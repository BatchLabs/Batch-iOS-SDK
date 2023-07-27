//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Foundation/Foundation.h>

@interface BALocalCampaignsTracker : BALocalCampaignsSQLTracker

@property (readonly) NSUInteger sessionViewsCount;

- (void)resetSessionViewsCount;

@end
