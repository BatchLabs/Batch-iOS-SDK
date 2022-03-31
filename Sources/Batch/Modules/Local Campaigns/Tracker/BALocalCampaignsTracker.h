//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALocalCampaignsSQLTracker.h>

@interface BALocalCampaignsTracker : BALocalCampaignsSQLTracker

@property (readonly) NSUInteger sessionViewsCount;

- (void)resetSessionViewsCount;

@end

