//
//  BALocalCampaignsManager.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsManager.h>

#import <Batch/BALogger.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>
#import <Batch/BASecureDateProvider.h>

#import <Batch/BAEventTrigger.h>
#import <Batch/BALocalCampaign.h>

#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BALocalCampaignsJITService.h>
#import <Batch/BAParameter.h>
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/Versions.h>

#define LOG_DOMAIN @"LocalCampaignsManager"

/// Max number of campaigns to send to the server for JIT sync
#define MAX_CAMPAIGNS_JIT_THRESHOLD 10

/// Min delay between two JIT sync (in seconds)
#define MIN_DELAY_BETWEEN_JIT_SYNC 15

/// Period during cached local campaign requiring a JIT sync is considered as up-to-date  (in seconds).
#define JIT_CAMPAIGN_CACHE_PERIOD 30

/// Default retry after in fail case (in seconds)
#define DEFAULT_RETRY_AFTER @60

@interface BALocalCampaignsManager () {
    /// Date provider
    id<BADateProviderProtocol> _dateProvider;

    /// View tracker
    BALocalCampaignsTracker *_viewTracker;

    /// Local campaigns
    NSMutableArray<BALocalCampaign *> *_campaignList;

    /// Watched event names
    NSSet *_watchedEventNames;

    /// Timestamp to wait before JIT service be available again.
    NSTimeInterval _nextAvailableJITTimestamp;

    /// Simple synchronized lock for watched events
    NSObject *_watchedEventsLock;

    /// Simple synchronized lock for requiresJITSync
    NSObject *_nextAvailableJITTimestampLock;

    /// Cached list of synced JIT campaigns
    NSMutableDictionary *_syncedJITCampaigns;
}

@end

@implementation BALocalCampaignsManager

- (instancetype)initWithViewTracker:(BALocalCampaignsTracker *)viewTracker {
    self = [self init];
    if (self) {
        _dateProvider = [BASecureDateProvider new];
        _viewTracker = viewTracker;
        [self setup];
    }

    return self;
}

- (instancetype)initWithDateProvider:(id<BADateProviderProtocol>)dateProvider
                         viewTracker:(BALocalCampaignsTracker *)viewTracker {
    self = [self init];
    if (self) {
        _dateProvider = dateProvider;
        _viewTracker = viewTracker;
        [self setup];
    }

    return self;
}

- (void)setup {
    _campaignList = [NSMutableArray new];
    _watchedEventsLock = [NSObject new];
    _nextAvailableJITTimestampLock = [NSObject new];
    _syncedJITCampaigns = [NSMutableDictionary dictionary];
}

#pragma mark Public methods

- (NSArray *)campaignList {
    return [NSArray arrayWithArray:_campaignList];
}

/**
 * Loads campaigns with customer user ID support.
 * Clears existing campaigns, filters the new list based on user-specific criteria,
 * and updates the watched event names cache.
 * @param updatedCampaignList Array of campaigns to load
 */
- (void)loadCampaigns:(NSArray<BALocalCampaign *> *)updatedCampaignList fromCache:(BOOL)fromCache {
    @synchronized(_campaignList) {
        [_campaignList removeAllObjects];
        if (updatedCampaignList != nil) {
            [_campaignList addObjectsFromArray:[self cleanCampaignList:updatedCampaignList]];

            if (!fromCache) {
                NSMutableArray *ids = [NSMutableArray array];
                for (BALocalCampaign *item in updatedCampaignList) {
                    [ids addObject:item.campaignID];
                }
                [self updateSyncedJITCampaigns:_campaignList eligibleCampaignIds:ids];
            }
        }

        [self updateWatchedEventNames];
    }
}

// Clears cached JIT campaigns to ensure they are re-evaluated when user identity changes
- (void)resetJITCampaignsCaches {
    @synchronized(_syncedJITCampaigns) {
        [_syncedJITCampaigns removeAllObjects];
    }
}

- (BOOL)isEventWatched:(NSString *)name {
    // Store the set in a strong variable to prevent a race condition where _watchedEventNames would be freed
    // while we sent a selector to it 
    NSSet<NSString *> *watchedEvents;

    @synchronized(_watchedEventsLock) {
        watchedEvents = [_watchedEventNames copy];
    }

    NSString *uppercaseName = [name uppercaseString];
    return [watchedEvents containsObject:uppercaseName];
}

/**
 * Finds eligible campaigns for a signal and sorts them by priority.
 * Considers trigger satisfaction, displayability, and customer user ID filtering.
 * @param signal The signal containing trigger information
 * @return Array of eligible campaigns sorted by priority (highest first)
 */
- (nonnull NSArray<BALocalCampaign *> *)eligibleCampaignsSortedByPriority:(id<BALocalCampaignSignalProtocol>)signal {
    @synchronized(_campaignList) {
        NSMutableArray<BALocalCampaign *> *eligibleCampaigns = [NSMutableArray new];
        for (BALocalCampaign *campaign in _campaignList) {
            BOOL satisfiesTrigger = false;
            for (id<BALocalCampaignTriggerProtocol> trigger in campaign.triggers) {
                if ([signal doesSatisfyTrigger:trigger]) {
                    satisfiesTrigger = true;
                    break;
                }
            }
            if (!satisfiesTrigger) {
                continue;
            }

            if (![self isCampaignDisplayable:campaign]) {
                continue;
            }

            [eligibleCampaigns addObject:campaign];
        }
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Found %lu eligible campaigns for signal %@",
                                 (unsigned long)[eligibleCampaigns count], [signal description]];

        return [eligibleCampaigns sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          NSInteger first = ((BALocalCampaign *)obj1).priority;
          NSInteger second = ((BALocalCampaign *)obj2).priority;
          return (first < second) ? NSOrderedDescending : ((first == second) ? NSOrderedSame : NSOrderedAscending);
        }];
    }
}

- (nonnull NSArray<BALocalCampaign *> *)firstEligibleCampaignsRequiringSync:
    (NSArray<BALocalCampaign *> *)eligibleCampaigns {
    NSMutableArray *eligibleCampaignNotRequiringSync = [NSMutableArray array];
    int i = 0;
    for (BALocalCampaign *campaign in eligibleCampaigns) {
        if (i >= MAX_CAMPAIGNS_JIT_THRESHOLD) {
            break;
        }
        if (campaign.requiresJustInTimeSync) {
            [eligibleCampaignNotRequiringSync addObject:campaign];
        } else {
            break;
        }
        i++;
    }
    return eligibleCampaignNotRequiringSync;
}

- (nullable BALocalCampaign *)firstCampaignNotRequiringJITSync:(NSArray<BALocalCampaign *> *)eligibleCampaigns {
    for (BALocalCampaign *campaign in eligibleCampaigns) {
        if (!campaign.requiresJustInTimeSync) {
            return campaign;
        }
    }
    return nil;
}

- (void)verifyCampaignsEligibilityFromServer:(NSArray<BALocalCampaign *> *)eligibleCampaigns
                                     version:(BALocalCampaignsVersion)version
                              withCompletion:(void (^_Nonnull)(BALocalCampaign *_Nullable))completionHandler {
    if ([eligibleCampaigns count] <= 0) {
        completionHandler(nil);
    }

    if (![self isJITServiceAvailable]) {
        completionHandler(nil);
    }
    NSMutableArray *eligibleCampaignsSynced = [eligibleCampaigns mutableCopy];
    BALocalCampaignsJITService *wsClient =
        [[BALocalCampaignsJITService alloc] initWithLocalCampaigns:eligibleCampaignsSynced
            viewTracker:_viewTracker
            version:version
            success:^(NSArray *eligibleCampaignIds) {
              [self setNextAvailableJITTimestampWithDefaultDelay];

              if ([eligibleCampaignIds count] > 0) {
                  [self updateSyncedJITCampaigns:eligibleCampaignsSynced eligibleCampaignIds:eligibleCampaignIds];

                  if ([eligibleCampaignsSynced count] > 0) {
                      completionHandler(eligibleCampaigns[0]);
                  } else {
                      completionHandler(nil);
                  }
              } else {
                  completionHandler(nil);
              }
            }
            error:^(NSError *error, NSNumber *retryAfter) {
              [self setNextAvailableJITTimestampWithCustomDelay:retryAfter];
              completionHandler(nil);
            }];
    [BAWebserviceClientExecutor.sharedInstance addClient:wsClient];
}

- (void)updateSyncedJITCampaigns:(NSMutableArray<BALocalCampaign *> *)eligibleCampaignsSynced
             eligibleCampaignIds:(NSArray *)eligibleCampaignIds {
    @synchronized(_syncedJITCampaigns) {
        for (BALocalCampaign *campaign in [NSArray arrayWithArray:eligibleCampaignsSynced]) {
            if (campaign.requiresJustInTimeSync) {
                BATSyncedJITResult *syncedJITResult = [[BATSyncedJITResult alloc]
                    initWithTimestamp:[[self->_dateProvider currentDate] timeIntervalSince1970]];
                if (![eligibleCampaignIds containsObject:campaign.campaignID]) {
                    [eligibleCampaignsSynced removeObject:campaign];
                    syncedJITResult.eligible = false;
                } else {
                    syncedJITResult.eligible = true;
                }
                self->_syncedJITCampaigns[campaign.campaignID] = syncedJITResult;
            }
        }
    }
}

- (BOOL)isJITServiceAvailable {
    @synchronized(_nextAvailableJITTimestampLock) {
        return ([[_dateProvider currentDate] timeIntervalSince1970] >= _nextAvailableJITTimestamp);
    }
}

- (BATSyncedJITCampaignState)syncedJITCampaignState:(BALocalCampaign *)campaign {
    if (!campaign.requiresJustInTimeSync) {
        // Should not happen but ensure we do not sync for a non-jit campaign
        return BATSyncedJITCampaignStateEligible;
    }

    BATSyncedJITResult *syncedJITResult = _syncedJITCampaigns[campaign.campaignID];
    if (syncedJITResult == nil) {
        return BATSyncedJITCampaignStateRequiresSync;
    }
    if ([[_dateProvider currentDate] timeIntervalSince1970] >=
        (syncedJITResult.timestamp + JIT_CAMPAIGN_CACHE_PERIOD)) {
        return BATSyncedJITCampaignStateRequiresSync;
    }
    return syncedJITResult.eligible ? BATSyncedJITCampaignStateEligible : BATSyncedJITCampaignStateNotEligible;
}

/**
 * Gets view counts for loaded campaigns with customer user ID support.
 * Returns a dictionary mapping campaign IDs to their view count information.
 * @return Dictionary of campaign IDs to view counts, or nil if no campaigns are loaded
 */
- (nullable NSDictionary<NSString *, BALocalCampaignCountedEvent *> *)viewCountsForLoadedCampaigns {
    if ([_campaignList count] == 0) {
        return nil;
    }

    NSMutableArray<NSString *> *campaignIds = [NSMutableArray new];
    for (BALocalCampaign *lc in _campaignList) {
        [campaignIds addObject:lc.campaignID];
    }

    NSString *customUserID = [BAParameter objectForKey:kParametersCustomUserIDKey fallback:nil];
    NSMutableDictionary *views = [NSMutableDictionary new];
    // TODO : optimize this with a SQLite "IN"
    for (NSString *lcId in campaignIds) {
        views[lcId] = [_viewTracker eventInformationForCampaignID:lcId
                                                             kind:BALocalCampaignTrackerEventKindView
                                                          version:_version
                                                     customUserID:customUserID];
    }

    return views;
}

- (BOOL)isOverGlobalCappings {
    if (_cappings == nil) {
        // No cappings
        return false;
    }

    if (_cappings.session != nil && _viewTracker.sessionViewsCount >= _cappings.session.intValue) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Session capping has been reached"];
        return true;
    }

    NSArray<BALocalCampaignsTimeBasedCapping *> *timeBasedCappings = _cappings.timeBasedCappings;
    if (timeBasedCappings != nil) {
        for (BALocalCampaignsTimeBasedCapping *timeBasedCapping in timeBasedCappings) {
            if (timeBasedCapping.duration != nil && timeBasedCapping.views != nil) {
                double timestamp =
                    [[_dateProvider currentDate] timeIntervalSince1970] - timeBasedCapping.duration.doubleValue;
                NSNumber *count = [_viewTracker numberOfViewEventsSince:timestamp];
                if (count == nil) {
                    [BALogger debugForDomain:LOG_DOMAIN
                                     message:@"Cannot retrived the number of view events. Campaigns will be prevented "
                                             @"from displaying."];
                    return true;
                }
                if (count.intValue >= timeBasedCapping.views.intValue) {
                    [BALogger debugForDomain:LOG_DOMAIN message:@"Time-based cappings have been reached"];
                    return true;
                }
            }
        }
    }
    return false;
}

#pragma mark Private methods

/**
 Removes campaign that will never be ok, even in the future:
 - Expired campaigns
 - Campaigns that hit their capping
 - Campaigns that have a max api level too low (min api level doesn't not mean that it is busted forever)
 */
/**
 * Removes campaigns that will never be eligible, even in the future.
 * Filters out expired campaigns, campaigns over capping, and campaigns with incompatible API levels.
 * Uses customer user ID for personalized capping calculations.
 * @param campaignsToClean Array of campaigns to filter
 * @return Array of campaigns that could potentially be displayed
 */
- (NSArray *)cleanCampaignList:(NSArray *)campaignsToClean {
    BATZAwareDate *currentDate = [BATZAwareDate dateWithDate:[_dateProvider currentDate] relativeToUserTZ:NO];
    NSInteger messagingAPILevel = BAMessagingAPILevel;

    NSMutableArray *cleanedCampaignList = [NSMutableArray new];

    for (BALocalCampaign *campaign in campaignsToClean) {
        // Exclude campaigns that are over
        if (campaign.endDate != nil && [currentDate isAfter:campaign.endDate]) {
            [BALogger debugForDomain:LOG_DOMAIN
                             message:@"Ignoring campaign %@ since it is past its end_date", campaign.campaignID];
            continue;
        }

        // Exclude campaigns that are over the view capping
        if ([self isCampaignOverCapping:campaign ignoreMinInterval:YES]) {
            [BALogger debugForDomain:LOG_DOMAIN
                             message:@"Ignoring campaign %@ since it is over capping", campaign.campaignID];
            continue;
        }

        // Exclude campaigns that have a max api level too low
        if (campaign.maximumAPILevel > 0 && messagingAPILevel > campaign.maximumAPILevel) {
            [BALogger debugForDomain:LOG_DOMAIN
                             message:@"Ignoring campaign %@ since we are over its max API level", campaign.campaignID];
            continue;
        }

        [cleanedCampaignList addObject:campaign];
    }

    return cleanedCampaignList;
}

/**
 Checks if a campaign is over its global capping.
 */
/**
 * Checks if a campaign is over its capping with customer user ID support.
 * Considers both view count capping and minimum display interval.
 * @param campaign The campaign to check
 * @param ignoreMinInterval Whether to ignore minimum display interval check
 * @return YES if campaign is over capping, NO otherwise
 */
- (BOOL)isCampaignOverCapping:(BALocalCampaign *)campaign ignoreMinInterval:(BOOL)ignoreMinInterval {
    NSString *customUserID = [BAParameter objectForKey:kParametersCustomUserIDKey fallback:nil];

    BALocalCampaignCountedEvent *eventData =
        [_viewTracker eventInformationForCampaignID:campaign.campaignID
                                               kind:BALocalCampaignTrackerEventKindView
                                            version:_version
                                       customUserID:customUserID];
    if (eventData == nil) {
        // What should happen if we can't read the views ?
        [BALogger errorForDomain:@"Batch Messaging"
                         message:@"Could not read campaign view history. Refusing to display. This should not happen: "
                                 @"please contact the support team."];
        return true;
    }

    if (campaign.capping != 0 && eventData.count >= campaign.capping) {
        return true;
    }

    if (!ignoreMinInterval &&
        (campaign.minimumDisplayInterval > 0 &&
         [[_dateProvider currentDate] timeIntervalSince1970] <=
             ([eventData.lastOccurrence timeIntervalSince1970] + campaign.minimumDisplayInterval))) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Not displaying campaign: min interval has not been reached"];
        return true;
    }

    return false;
}

/**
 Checks if the campaign is displayable according to general conditions:
  - Capping checks
  - Current date over start date
  - Minimum API level
  - etc...
 */
/**
 * Checks if a campaign is displayable according to all conditions.
 * Considers capping, API level compatibility, date constraints, and quiet hours.
 * Uses customer user ID for personalized eligibility checks.
 * @param campaign The campaign to check
 * @return YES if campaign is displayable, NO otherwise
 */
- (BOOL)isCampaignDisplayable:(BALocalCampaign *)campaign {
    if ([self isCampaignOverCapping:campaign ignoreMinInterval:NO]) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ since it is over capping/minimum display interval",
                                 campaign.campaignID];
        return false;
    }

    NSInteger messagingAPILevel = BAMessagingAPILevel;

    if (campaign.minimumAPILevel > 0 && campaign.minimumAPILevel > messagingAPILevel) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ since it is over max API level", campaign.campaignID];
        return false;
    }

    if (campaign.maximumAPILevel > 0 && messagingAPILevel > campaign.maximumAPILevel) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ since we are over its max API level", campaign.campaignID];
        return false;
    }

    BATZAwareDate *currentDate = [BATZAwareDate dateWithDate:[_dateProvider currentDate] relativeToUserTZ:NO];

    if (campaign.startDate != nil && [currentDate isBefore:campaign.startDate]) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ since it is past it has not begun yet", campaign.campaignID];
        return false;
    }

    if (campaign.endDate != nil && [currentDate isAfter:campaign.endDate]) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ since it is past its end_date", campaign.campaignID];
        return false;
    }

    if ([self isCampaignDateInQuietHours:campaign]) {
        [BALogger debugForDomain:LOG_DOMAIN
                         message:@"Ignoring campaign %@ because of quiet days and hours", campaign.campaignID];

        return false;
    }

    return true;
}

/**
 Checks if the current user date and time fall within the configured quiet hours.
 This method handles both same-day and overnight time intervals.

 @return YES if the current time is a quiet time, NO otherwise.
 */
- (BOOL)isCampaignDateInQuietHours:(BALocalCampaign *)campaign {
    if (campaign.quietHours != nil) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        [calendar setFirstWeekday:0];
        NSDate *now = [_dateProvider currentDate];

        // Get current day of week. NSCalendar uses 1 for Sunday, 2 for Monday, etc.
        // Our enum uses 0 for Sunday, 1 for Monday, etc. We need to subtract 1 to align them.
        NSInteger currentWeekday = [calendar component:NSCalendarUnitWeekday fromDate:now] - 1;

        BOOL isTodayAQuietDay =
            [campaign.quietHours.quietDaysOfWeek containsObject:[NSNumber numberWithInteger:currentWeekday]];

        // If the current day is designated as a quiet day, then the entire day is quiet.
        if (isTodayAQuietDay) {
            return true;
        }

        // --- Check for Time-Based Quiet Hours ---
        // If we've reached this point, it's not a full quiet day. Now check the specific time range.
        NSDateComponents *timeComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                                       fromDate:now];
        NSInteger currentHour = [timeComponents hour];
        NSInteger currentMinute = [timeComponents minute];

        // To make comparisons easier, convert all times to total minutes from midnight.
        NSInteger currentTimeInMinutes = currentHour * 60 + currentMinute;
        NSInteger startTimeInMinutes = campaign.quietHours.startHour * 60 + campaign.quietHours.startMin;
        NSInteger endTimeInMinutes = campaign.quietHours.endHour * 60 + campaign.quietHours.endMin;

        // This logic handles two scenarios for the quiet hours interval:
        // 1. Overnight (e.g., 22:00 to 07:00), where start time is greater than end time.
        // 2. Same-day (e.g., 09:00 to 17:00), where start time is less than or equal to end time.

        // Determine if the quiet period is overnight
        BOOL isOvernight = startTimeInMinutes > endTimeInMinutes;

        if (isOvernight) {
            // For an overnight period, it's a quiet time if the current time is either:
            // 1. After the start time (e.g., between 22:00 and midnight).
            // OR
            // 2. Before the end time (e.g., between midnight and 07:00).
            return currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes;
        } else {
            // For a same-day period, it is quiet time if the current time is within the interval.
            return currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes;
        }
    }

    return false;
}

/**
 Update the set of watched event names
 This method is not thread safe: do not call it without some kind of lock
 */
/**
 * Updates the set of watched event names from loaded campaigns.
 * This method is not thread safe for the campaign list access but is synchronized for the watched events update.
 * Should be called after loading campaigns to optimize event filtering.
 */
- (void)updateWatchedEventNames {
    NSMutableSet *updatedEventNames = [NSMutableSet new];

    for (BALocalCampaign *campaign in _campaignList) {
        for (id<BALocalCampaignTriggerProtocol> trigger in campaign.triggers) {
            if ([trigger isKindOfClass:[BAEventTrigger class]]) {
                [updatedEventNames addObject:[((BAEventTrigger *)trigger).name uppercaseString]];
            }
        }
    }

    @synchronized(_watchedEventsLock) {
        _watchedEventNames = updatedEventNames;
    }
}

- (void)setNextAvailableJITTimestampWithDefaultDelay {
    [self setNextAvailableJITTimestampWithCustomDelay:@MIN_DELAY_BETWEEN_JIT_SYNC];
}

- (void)setNextAvailableJITTimestampWithCustomDelay:(nullable NSNumber *)delay {
    NSNumber *retryAfter = ((delay == nil ? 0 : delay) <= 0 ? DEFAULT_RETRY_AFTER : delay);
    _nextAvailableJITTimestamp = [[self->_dateProvider currentDate] timeIntervalSince1970] + retryAfter.doubleValue;
}

@end
