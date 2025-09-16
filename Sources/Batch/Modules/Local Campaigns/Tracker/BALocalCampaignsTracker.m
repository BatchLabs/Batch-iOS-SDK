//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BALocalCampaignsTracker.h"

@implementation BALocalCampaignsTracker

/**
 * Resets the session view count to zero.
 * Called at the beginning of new sessions to reset the session-based capping counter.
 */
- (void)resetSessionViewsCount {
    _sessionViewsCount = 0;
}

/**
 * Tracks a campaign event with customer user ID support and increments session view count.
 * This method extends the base tracker functionality by maintaining a session-level counter
 * for session-based capping while delegating the actual tracking to the superclass.
 * @param campaignID The unique identifier of the campaign
 * @param kind The type of event being tracked
 * @param version The campaign version (MEP or CEP) affecting customer user ID support
 * @param customUserID Optional customer user identifier for user-specific tracking
 * @return The updated counted event if successful, nil otherwise
 */
- (BALocalCampaignCountedEvent *)trackEventForCampaignID:(NSString *)campaignID
                                                    kind:(BALocalCampaignTrackerEventKind)kind
                                                 version:(BALocalCampaignsVersion)version
                                            customUserID:(nullable NSString *)customUserID {
    _sessionViewsCount++;
    return [super trackEventForCampaignID:campaignID kind:kind version:version customUserID:customUserID];
}

@end
