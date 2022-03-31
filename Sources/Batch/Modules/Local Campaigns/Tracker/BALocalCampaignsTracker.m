//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BALocalCampaignsTracker.h"

@implementation BALocalCampaignsTracker

- (void)resetSessionViewsCount {
    _sessionViewsCount = 0;
}

- (BALocalCampaignCountedEvent *)trackEventForCampaignID:(NSString *)campaignID
                                                    kind:(BALocalCampaignTrackerEventKind)kind {
    _sessionViewsCount++;
    return [super trackEventForCampaignID:campaignID kind:kind];
}

@end
