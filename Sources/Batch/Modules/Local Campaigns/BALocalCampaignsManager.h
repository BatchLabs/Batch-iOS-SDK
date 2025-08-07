//
//  BALocalCampaignsManager.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BADateProviderProtocol.h>
#import <Batch/BALocalCampaign.h>
#import <Batch/BALocalCampaignSignalProtocol.h>
#import <Batch/BALocalCampaignsGlobalCappings.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BATSyncedJITCampaignState) {
    BATSyncedJITCampaignStateEligible,
    BATSyncedJITCampaignStateNotEligible,
    BATSyncedJITCampaignStateRequiresSync
};

/**
 Handles many Local campagins related features:
 - Holds campaigns got from the backend/disk cache
 - Checks campaign condition satisfaction and trigger them
 - Automatically if in auto mode (if dev didn't ask Batch to delay campaigns)
 - Trigger a callback to the developer if in manual mode
 */
@interface BALocalCampaignsManager : NSObject

- (instancetype)initWithViewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker;

- (instancetype)initWithDateProvider:(id<BADateProviderProtocol>)dateProvider
                         viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker;

@property (readonly, nonnull) NSArray<BALocalCampaign *> *campaignList;

@property (nullable) BALocalCampaignsGlobalCappings *cappings;

/**
 Update the currently stored campaign list. This should usually be done when a WS succeeds or when campaigns are loaded
 from the disk.

 Also triggers the campaign loaded signal
 */
- (void)loadCampaigns:(NSArray<BALocalCampaign *> *)updatedCampaignList fromCache:(BOOL)fromCache;

/**
 Checks if an event name will trigger at least one campaign, allowing for a fast pre-filter to check if it is worth
 checking other conditions for campaigns with an event trigger
 */
- (BOOL)isEventWatched:(NSString *)name;

/**
 Get all campaign between all of those that are satisfied by the latest application event and sort them by priority
 This is the campaign that you'll want to display
 */
- (nonnull NSArray<BALocalCampaign *> *)eligibleCampaignsSortedByPriority:(id<BALocalCampaignSignalProtocol>)signal;

/**
 Get the first eligible campaigns requiring a JIT sync (Meaning it stop at the first campaign not requiring JIT)
 */
- (nonnull NSArray<BALocalCampaign *> *)firstEligibleCampaignsRequiringSync:
    (NSArray<BALocalCampaign *> *)eligibleCampaigns;

/**
 Get the first eligible campaign not requiring a JIT sync
 */
- (nullable BALocalCampaign *)firstCampaignNotRequiringJITSync:(NSArray<BALocalCampaign *> *)eligibleCampaigns;

/**
 Checking with server if campaigns are still eligible
 */
- (void)verifyCampaignsEligibilityFromServer:(NSArray<BALocalCampaign *> *)eligibleCampaigns
                              withCompletion:
                                  (void (^_Nonnull)(BALocalCampaign *_Nullable electedCampaign))completionHandler;

/**
 Check if JIT webservice is available.
 */
- (BOOL)isJITServiceAvailable;

/**
 Check if the given campaign has been already synced recently
 */
- (BATSyncedJITCampaignState)syncedJITCampaignState:(BALocalCampaign *)campaign;

/**
 Get the view counts for the loaded campaigns

 Can be nil if no campaigns are loaded
 */
- (nullable NSDictionary<NSString *, BALocalCampaignCountedEvent *> *)viewCountsForLoadedCampaigns;

/**
 Check if the global in-apps cappings have been reached.
 */
- (BOOL)isOverGlobalCappings;

/**
 Sets the next available timestamp for Just-In-Time (JIT) synchronization
 using the default minimum delay.
 The default minimum delay is defined by the constant
 #MIN_DELAY_BETWEEN_JIT_SYNC
 */
- (void)setNextAvailableJITTimestampWithDefaultDelay;

/**
 Sets the next available timestamp for Just-In-Time (JIT) synchronization
 using a custom delay.
 The default minimum delay is defined by the constant
 #DEFAULT_RETRY_AFTER
 */
- (void)setNextAvailableJITTimestampWithCustomDelay:(nullable NSNumber *)delay;

@end

NS_ASSUME_NONNULL_END
