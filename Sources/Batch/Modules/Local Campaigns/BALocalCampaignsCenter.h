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
#import <Batch/BALocalCampaignsTracker.h>

@class BatchEventAttributes;

/*
 Batch's In-App Messaging Module.
 Works hand in hand with BAMessagingCenter: it's a little different than other modules, since
 all of its public interface will be provided by BatchMessaging which already talks to BAMessagingCenter,
 but this allows a better separation of roles.
 */
@interface BALocalCampaignsCenter : NSObject <BACenterProtocol>

@property (nonnull, readonly, class) BALocalCampaignsCenter *instance;

@property (nonnull, readonly) BALocalCampaignsManager *campaignManager;

@property (nonnull, readonly) BALocalCampaignsTracker *viewTracker;

@property (assign) long globalMinimumDisplayInterval;

/**
 Persistence queue. Exposed for tests only.
 */
@property (nonnull, nonatomic, readonly, strong) dispatch_queue_t persistenceQueue;

/**
 Displays the campaign for the specified application event.
 */
- (void)emitSignal:(nonnull id<BALocalCampaignSignalProtocol>)event;

/**
 Called when an internal event is tracked
 Will perform a quick check using a cache, and if there's a potentially wanted event, will submit the task to an queue
 so that the checks required do not block the thread
 */
- (void)processTrackerPrivateEventNamed:(nonnull NSString *)name;

/**
 Called when a public event is tracked
 Will perform a quick check using a cache, and if there's a potentially wanted event, will submit the task to an queue
 so that the checks required do not block the thread
 */
- (void)processTrackerPublicEventNamed:(nonnull NSString *)name
                                 label:(nullable NSString *)label
                            attributes:(nullable BatchEventAttributes *)attributes;

/**
 Notify this module of the display of an In-App Campaign.

 Used for example for increasing the view count of a campaign, in order to be able to make the capping work.
 */
- (void)didPerformCampaignOutputWithIdentifier:(nonnull NSString *)identifier eventData:(nullable NSObject *)eventData;

/**
 Handle the WS response payload:
  - Parse and load it
  - Write it on disk if valid
  - Emit the campaigns loaded signal
 */
- (void)handleWebserviceResponsePayload:(nonnull NSDictionary *)payload;

/**
 Notify this module that the local campaigns webservice has finished with success or not.

 Used to release the signal queue.
 */
- (void)localCampaignsWebserviceDidFinish;

/**
 Trigger a WS call to refresh the campaigns
 */
- (void)refreshCampaignsFromServer;

- (void)userDidOptOut;

@end
