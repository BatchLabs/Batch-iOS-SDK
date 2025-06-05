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
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/Versions.h>

#define LOG_DOMAIN @"LocalCampaignsManager"

/// Max number of campaigns to send to the server for JIT sync
#define MAX_CAMPAIGNS_JIT_THRESHOLD 5

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

- (void)loadCampaigns:(NSArray<BALocalCampaign *> *)updatedCampaignList {
    @synchronized(_campaignList) {
        [_campaignList removeAllObjects];
        if (updatedCampaignList != nil) {
            [_campaignList addObjectsFromArray:[self cleanCampaignList:updatedCampaignList]];
        }

        [self updateWatchedEventNames];
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
            success:^(NSArray *eligibleCampaignIds) {
              [self setNextAvailableJITTimestampWithDefaultDelay];

              if ([eligibleCampaignIds count] > 0) {
                  for (BALocalCampaign *campaign in [NSArray arrayWithArray:eligibleCampaignsSynced]) {
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

- (nullable NSDictionary<NSString *, BALocalCampaignCountedEvent *> *)viewCountsForLoadedCampaigns {
    if ([_campaignList count] == 0) {
        return nil;
    }

    NSMutableArray<NSString *> *campaignIds = [NSMutableArray new];
    for (BALocalCampaign *lc in _campaignList) {
        [campaignIds addObject:lc.campaignID];
    }

    NSMutableDictionary *views = [NSMutableDictionary new];
    // TODO : optimize this with a SQLite "IN"
    for (NSString *lcId in campaignIds) {
        views[lcId] = [_viewTracker eventInformationForCampaignID:lcId kind:BALocalCampaignTrackerEventKindView];
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
- (BOOL)isCampaignOverCapping:(BALocalCampaign *)campaign ignoreMinInterval:(BOOL)ignoreMinInterval {
    BALocalCampaignCountedEvent *eventData =
        [_viewTracker eventInformationForCampaignID:campaign.campaignID kind:BALocalCampaignTrackerEventKindView];
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

    return true;
}

/**
 Update the set of watched event names
 This method is not thread safe: do not call it without some kind of lock
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
