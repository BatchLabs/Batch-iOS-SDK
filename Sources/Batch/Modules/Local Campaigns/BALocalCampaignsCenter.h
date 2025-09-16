//
//  BALocalCampaignsCenter.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BACenterMulticastDelegate.h>

#import <Batch/BALocalCampaignSignalProtocol.h>
#import <Batch/BALocalCampaignsManager.h>
#import <Batch/BALocalCampaignsPersisting.h>
#import <Batch/BALocalCampaignsTracker.h>

@class BatchEventAttributes;

/**
 * Batch's In-App Messaging Module.
 * Works hand in hand with BAMessagingCenter: it's a little different than other modules, since
 * all of its public interface will be provided by BatchMessaging which already talks to BAMessagingCenter,
 * but this allows a better separation of roles.
 *
 * This center coordinates local campaigns functionality including:
 * - Campaign loading and caching
 * - Event processing and signal emission
 * - Campaign eligibility and display logic
 * - View tracking and capping management
 * - Customer user ID support for personalized campaigns
 */
@interface BALocalCampaignsCenter : NSObject <BACenterProtocol>

/** Singleton instance of the local campaigns center */
@property (nonnull, readonly, class) BALocalCampaignsCenter *instance;

/** Campaign manager responsible for campaign logic and eligibility */
@property (nonnull, readonly) BALocalCampaignsManager *campaignManager;

/** Persister for storing campaigns to disk */
@property (nonnull, readonly) id<BALocalCampaignsPersisting> campaignPersister;

/** Tracker for recording campaign views and events */
@property (nonnull, readonly) BALocalCampaignsTracker *viewTracker;

/** Global minimum display interval between campaigns in seconds */
@property (assign) long globalMinimumDisplayInterval;

/**
 * Persistence queue. Exposed for tests only.
 * Serial queue used for campaign persistence operations.
 */
@property (nonnull, nonatomic, readonly, strong) dispatch_queue_t persistenceQueue;

/**
 * Processes a campaign signal and potentially displays a campaign.
 * This is the main entry point for campaign triggering.
 * @param event The signal containing trigger information
 */
- (void)emitSignal:(nonnull id<BALocalCampaignSignalProtocol>)event;

/**
 * Called when an internal event is tracked.
 * Will perform a quick check using a cache, and if there's a potentially wanted event,
 * will submit the task to a queue so that the checks required do not block the thread.
 * @param name The name of the internal event
 */
- (void)processTrackerPrivateEventNamed:(nonnull NSString *)name;

/**
 * Called when a public event is tracked.
 * Will perform a quick check using a cache, and if there's a potentially wanted event,
 * will submit the task to a queue so that the checks required do not block the thread.
 * @param name The name of the public event
 * @param label Optional label for the event
 * @param attributes Optional attributes dictionary for the event
 */
- (void)processTrackerPublicEventNamed:(nonnull NSString *)name
                                 label:(nullable NSString *)label
                            attributes:(nullable NSDictionary *)attributes;

/**
 * Notify this module of the display of an In-App Campaign.
 * Used for increasing the view count of a campaign, in order to be able to make the capping work.
 * Tracks the campaign view with customer user ID support.
 * @param identifier The unique identifier of the displayed campaign
 * @param eventData Optional event data associated with the campaign display
 */
- (void)didPerformCampaignOutputWithIdentifier:(nonnull NSString *)identifier eventData:(nullable NSObject *)eventData;

/**
 * Handle the webservice response payload:
 * - Parse and load campaigns
 * - Write to disk if valid
 * - Update campaign manager with new data
 * @param payload The response payload from the campaigns webservice
 */
- (void)handleWebserviceResponsePayload:(nonnull NSDictionary *)payload;

/**
 * Notify this module that the local campaigns webservice has finished with success or not.
 * Used to release the signal queue and allow campaign processing to resume.
 */
- (void)localCampaignsWebserviceDidFinish;

/**
 * Trigger a webservice call to refresh the campaigns from the server.
 * This will load campaigns asynchronously and update the local cache.
 */
- (void)refreshCampaignsFromServer;

/**
 * Called when user opts out of Batch services.
 * Clears all campaign data and resets the center state.
 */
- (void)userDidOptOut;

@end
