//
//  BALocalCampaignsManager.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsManager.h>

#import <Batch/BALogger.h>

#import <Batch/BASecureDateProvider.h>
#import <Batch/BALocalCampaignTrackerProtocol.h>

#import <Batch/BALocalCampaign.h>
#import <Batch/BAEventTrigger.h>

#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BACampaignsLoadedSignal.h>

#define LOG_DOMAIN @"LocalCampaignsManager"

@interface BALocalCampaignsManager ()
{
    id<BADateProviderProtocol> _dateProvider;
    id<BALocalCampaignTrackerProtocol> _viewTracker;

    NSMutableArray<BALocalCampaign*> * _campaignList;
    NSSet *_watchedEventNames;
}

@end

@implementation BALocalCampaignsManager

- (instancetype)initWithViewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker {
    self = [self init];
    if (self) {
        _dateProvider = [BASecureDateProvider new];
        _viewTracker = viewTracker;
        [self setup];
    }

    return self;
}

- (instancetype)initWithDateProvider:(id<BADateProviderProtocol>)dateProvider viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker {
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
}

#pragma mark Public methods

- (NSArray*)campaignList {
    return [NSArray arrayWithArray:_campaignList];
}

- (void)loadCampaigns:(NSArray<BALocalCampaign*>*)updatedCampaignList {
    @synchronized (_campaignList) {
        [_campaignList removeAllObjects];
        if (updatedCampaignList != nil) {
            [_campaignList addObjectsFromArray:[self cleanCampaignList:updatedCampaignList]];
        }

        [self updateWatchedEventNames];
    }
}

- (BOOL)isEventWatched:(NSString*)name {
    // Store the set in a strong variable to prevent a race condition where _watchedEventNames would be freed
    // while we sent a selector to it
    NSSet<NSString*>* watchedEventNames = _watchedEventNames;
    return [watchedEventNames containsObject:[name uppercaseString]];
}

- (BALocalCampaign*)campaignToDisplayForSignal:(id<BALocalCampaignSignalProtocol>)signal {
    @synchronized (_campaignList) {
        NSMutableArray<BALocalCampaign*>* eligibleCampaigns = [NSMutableArray new];

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

        [_campaignList sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSInteger first = ((BALocalCampaign*)obj1).priority;
            NSInteger second = ((BALocalCampaign*)obj2).priority;
            return (first < second) ? NSOrderedDescending : ((first == second) ? NSOrderedSame : NSOrderedAscending);
        }];

        NSUInteger count = [eligibleCampaigns count];
        [BALogger debugForDomain:LOG_DOMAIN message:@"Found %lu eligible campaigns for signal %@", (unsigned long)count, [signal description]];
        if (count > 0) {
            return eligibleCampaigns[0];
        }

        return nil;
    }
}

- (nullable NSDictionary<NSString*, BALocalCampaignCountedEvent*>*)viewCountsForLoadedCampaigns
{
    if ([_campaignList count] == 0) {
        return nil;
    }
    
    NSMutableArray<NSString*>* campaignIds = [NSMutableArray new];
    for (BALocalCampaign *lc in _campaignList) {
        [campaignIds addObject:lc.campaignID];
    }
    
    NSMutableDictionary *views = [NSMutableDictionary new];
    //TODO : optimize this with a SQLite "IN"
    for (NSString *lcId in campaignIds) {
        views[lcId] = [_viewTracker eventInformationForCampaignID:lcId kind:BALocalCampaignTrackerEventKindView];
    }
    
    return views;
}

#pragma mark Private methods

/**
 Removes campaign that will never be ok, even in the future:
 - Expired campaigns
 - Campaigns that hit their capping
 - Campaigns that have a max api level too low (min api level doesn't not mean that it is busted forever)
 */
- (NSArray*)cleanCampaignList:(NSArray*)campaignsToClean {
    BATZAwareDate *currentDate = [BATZAwareDate dateWithDate:[_dateProvider currentDate] relativeToUserTZ:NO];
    NSInteger messagingAPILevel = BAMessagingAPILevel;

    NSMutableArray *cleanedCampaignList = [NSMutableArray new];

    for (BALocalCampaign *campaign in campaignsToClean) {
        // Exclude campaigns that are over
        if (campaign.endDate != nil && [currentDate isAfter:campaign.endDate]) {
            [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is past its end_date", campaign.campaignID];
            continue;
        }

        // Exclude campaigns that are over the view capping
        if ([self isCampaignOverCapping:campaign ignoreMinInterval:YES]) {
            [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is over capping", campaign.campaignID];
            continue;
        }

        // Exclude campaigns that have a max api level too low
        if (campaign.maximumAPILevel > 0 && messagingAPILevel > campaign.maximumAPILevel) {
            [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since we are over its max API level", campaign.campaignID];
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
    BALocalCampaignCountedEvent *eventData = [_viewTracker eventInformationForCampaignID:campaign.campaignID kind:BALocalCampaignTrackerEventKindView];
    if (eventData == nil) {        
        // What should happen if we can't read the views ?
        [BALogger errorForDomain:@"Batch Messaging" message:@"Could not read campaign view history. Refusing to display. This should not happen: please contact the support team."];
        return true;
    }

    if (campaign.capping != 0 && eventData.count >= campaign.capping) {
        return true;
    }
    
    if (!ignoreMinInterval && (campaign.minimumDisplayInterval > 0 &&
        [[_dateProvider currentDate] timeIntervalSince1970] <= ([eventData.lastOccurrence timeIntervalSince1970] + campaign.minimumDisplayInterval))) {
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
        [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is over capping/minimum display interval", campaign.campaignID];
        return false;
    }
    
    NSInteger messagingAPILevel = BAMessagingAPILevel;
    
    if (campaign.minimumAPILevel > 0 && campaign.minimumAPILevel > messagingAPILevel) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is over max API level", campaign.campaignID];
        return false;
    }
    
    if (campaign.maximumAPILevel > 0 && messagingAPILevel > campaign.maximumAPILevel) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since we are over its max API level", campaign.campaignID];
        return false;
    }
    
    BATZAwareDate *currentDate = [BATZAwareDate dateWithDate:[_dateProvider currentDate] relativeToUserTZ:NO];
    
    if (campaign.startDate != nil && [currentDate isBefore:campaign.startDate]) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is past it has not begun yet", campaign.campaignID];
        return false;
    }
    
    if (campaign.endDate != nil && [currentDate isAfter:campaign.endDate]) {
        [BALogger debugForDomain:LOG_DOMAIN message:@"Ignoring campaign %@ since it is past its end_date", campaign.campaignID];
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
                [updatedEventNames addObject:[((BAEventTrigger*)trigger).name uppercaseString]];
            }
        }
    }

    _watchedEventNames = updatedEventNames;
}

@end
