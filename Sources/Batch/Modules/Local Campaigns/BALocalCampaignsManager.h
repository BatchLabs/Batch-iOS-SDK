//
//  BALocalCampaignsManager.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaign.h>
#import <Batch/BADateProviderProtocol.h>
#import <Batch/BALocalCampaignSignalProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Handles many Local campagins related features:
 - Holds campaigns got from the backend/disk cache
 - Checks campaign condition satisfaction and trigger them
 - Automatically if in auto mode (if dev didn't ask Batch to delay campaigns)
 - Trigger a callback to the developer if in manual mode
 */
@interface BALocalCampaignsManager : NSObject

- (instancetype)initWithViewTracker:(id <BALocalCampaignTrackerProtocol>)viewTracker;

- (instancetype)initWithDateProvider:(id <BADateProviderProtocol>)dateProvider viewTracker:(id <BALocalCampaignTrackerProtocol>)viewTracker;

@property (readonly, nonnull) NSArray<BALocalCampaign*> *campaignList;

/**
 Update the currently stored campaign list. This should usually be done when a WS succeeds or when campaigns are loaded from the disk.
 
 Also triggers the campaign loaded signal
 */
- (void)loadCampaigns:(NSArray<BALocalCampaign*>*)updatedCampaignList;

/**
 Checks if an event name will trigger at least one campaign, allowing for a fast pre-filter to check if it is worth
 checking other conditions for campaigns with an event trigger
 */
- (BOOL)isEventWatched:(NSString *)name;

/**
 Get the higher priority campaign between all of those that are satisfied by the given application event
 This is the campaign that you'll want to display
 */
- (nullable BALocalCampaign*)campaignToDisplayForSignal:(id<BALocalCampaignSignalProtocol>)signal;

/**
 Get the view counts for the loaded campaigns
 
 Can be nil if no campaigns are loaded
 */
- (nullable NSDictionary<NSString*, BALocalCampaignCountedEvent*>*)viewCountsForLoadedCampaigns;

@end

NS_ASSUME_NONNULL_END
