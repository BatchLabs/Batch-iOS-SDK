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
#import <Batch/BALocalCampaignsVersion.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Enumeration representing the synchronization state of Just-In-Time (JIT) campaigns.
 * Used to determine whether a JIT campaign needs to be synchronized with the server.
 */
typedef NS_ENUM(NSInteger, BATSyncedJITCampaignState) {
    /** Campaign is eligible and recently synchronized */
    BATSyncedJITCampaignStateEligible,
    /** Campaign is not eligible after synchronization */
    BATSyncedJITCampaignStateNotEligible,
    /** Campaign requires synchronization with the server */
    BATSyncedJITCampaignStateRequiresSync
};

/**
 * Handles many Local campaigns related features:
 * - Holds campaigns retrieved from the backend/disk cache
 * - Checks campaign condition satisfaction and triggers them
 * - Manages campaign eligibility with customer user ID support
 * - Handles Just-In-Time (JIT) synchronization for dynamic campaigns
 * - Manages global and per-campaign capping rules
 * - Processes quiet hours and scheduling constraints
 */
@interface BALocalCampaignsManager : NSObject

/**
 * Initializes the manager with a view tracker.
 * Uses the default secure date provider internally.
 * @param viewTracker The tracker for recording campaign views and events
 * @return An initialized BALocalCampaignsManager instance
 */
- (instancetype)initWithViewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker;

/**
 * Designated initializer for the campaigns manager.
 * @param dateProvider The date provider for time-based operations
 * @param viewTracker The tracker for recording campaign views and events
 * @return An initialized BALocalCampaignsManager instance
 */
- (instancetype)initWithDateProvider:(id<BADateProviderProtocol>)dateProvider
                         viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker;

/** Array of currently loaded campaigns */
@property (readonly, nonnull) NSArray<BALocalCampaign *> *campaignList;

/** Global capping rules for all campaigns */
@property (nullable) BALocalCampaignsGlobalCappings *cappings;

/** Version of the campaigns (MEP or CEP) affecting customer user ID support */
@property BALocalCampaignsVersion version;

/**
 * Updates the currently stored campaign list with customer user ID support.
 * This should usually be done when a webservice succeeds or when campaigns are loaded from disk.
 * Also triggers the campaign loaded signal and updates watched event names.
 * @param updatedCampaignList Array of campaigns to load
 */
- (void)loadCampaigns:(NSArray<BALocalCampaign *> *)updatedCampaignList fromCache:(BOOL)fromCache;

/**
 * Clears the cached JIT (Just-In-Time) campaigns.
 * Should be called when user identity changes to ensure campaigns are re-evaluated for the new user.
 */
- (void)resetJITCampaignsCaches;

/**
 * Checks if an event name will trigger at least one campaign.
 * Allows for a fast pre-filter to check if it is worth checking other conditions for campaigns with an event trigger.
 * @param name The event name to check
 * @return YES if the event is watched by at least one campaign, NO otherwise
 */
- (BOOL)isEventWatched:(NSString *)name;

/**
 * Gets all campaigns that are satisfied by the latest application event and sorts them by priority.
 * This method considers customer user ID for personalized campaign eligibility.
 * @param signal The signal containing trigger information
 * @return Array of eligible campaigns sorted by priority (highest first)
 */
- (nonnull NSArray<BALocalCampaign *> *)eligibleCampaignsSortedByPriority:(id<BALocalCampaignSignalProtocol>)signal;

/**
 * Gets the first eligible campaigns requiring a JIT sync.
 * Stops at the first campaign not requiring JIT, up to the maximum threshold.
 * @param eligibleCampaigns Array of eligible campaigns to filter
 * @return Array of campaigns requiring JIT synchronization
 */
- (nonnull NSArray<BALocalCampaign *> *)firstEligibleCampaignsRequiringSync:
    (NSArray<BALocalCampaign *> *)eligibleCampaigns;

/**
 * Gets the first eligible campaign not requiring a JIT sync.
 * Used as a fallback when JIT synchronization is not available.
 * @param eligibleCampaigns Array of eligible campaigns to search
 * @return First campaign not requiring JIT sync, or nil if none found
 */
- (nullable BALocalCampaign *)firstCampaignNotRequiringJITSync:(NSArray<BALocalCampaign *> *)eligibleCampaigns;

/**
 * Verifies campaign eligibility with the server using JIT synchronization.
 * Makes a webservice call to check if campaigns are still eligible for display.
 * @param eligibleCampaigns Array of campaigns to verify
 * @param version Campaign version (MEP or CEP)
 * @param completionHandler Block called with the elected campaign or nil
 */
- (void)verifyCampaignsEligibilityFromServer:(NSArray<BALocalCampaign *> *)eligibleCampaigns
                                     version:(BALocalCampaignsVersion)version
                              withCompletion:
                                  (void (^_Nonnull)(BALocalCampaign *_Nullable electedCampaign))completionHandler;

/**
 * Checks if the JIT webservice is available.
 * Based on the minimum delay between JIT sync calls.
 * @return YES if JIT service is available, NO otherwise
 */
- (BOOL)isJITServiceAvailable;

/**
 * Checks if the given campaign has been already synced recently.
 * Returns the synchronization state based on cached JIT results.
 * @param campaign The campaign to check
 * @return The synchronization state of the campaign
 */
- (BATSyncedJITCampaignState)syncedJITCampaignState:(BALocalCampaign *)campaign;

/**
 * Gets the view counts for the loaded campaigns with customer user ID support.
 * Returns a dictionary mapping campaign IDs to their view count information.
 * @return Dictionary of campaign IDs to view counts, or nil if no campaigns are loaded
 */
- (nullable NSDictionary<NSString *, BALocalCampaignCountedEvent *> *)viewCountsForLoadedCampaigns;

/**
 * Checks if the global in-app cappings have been reached.
 * Considers both session-based and time-based capping rules.
 * @return YES if global cappings are exceeded, NO otherwise
 */
- (BOOL)isOverGlobalCappings;

/**
 * Sets the next available timestamp for Just-In-Time (JIT) synchronization using the default minimum delay.
 * The default minimum delay is defined by the constant MIN_DELAY_BETWEEN_JIT_SYNC.
 * Used to prevent too frequent JIT synchronization calls.
 */
- (void)setNextAvailableJITTimestampWithDefaultDelay;

/**
 * Sets the next available timestamp for Just-In-Time (JIT) synchronization using a custom delay.
 * If delay is nil or invalid, uses the default retry after value.
 * @param delay Custom delay in seconds, or nil to use default
 */
- (void)setNextAvailableJITTimestampWithCustomDelay:(nullable NSNumber *)delay;

/**
 * Checks if the current user date and time fall within the configured quiet hours.
 * This method handles both same-day and overnight time intervals, as well as quiet days.
 * @param campaign The campaign to check for quiet hours
 * @return YES if the current time is a quiet time, NO otherwise
 */
- (BOOL)isCampaignDateInQuietHours:(BALocalCampaign *)campaign;

@end

NS_ASSUME_NONNULL_END
