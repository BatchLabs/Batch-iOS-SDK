//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BALocalCampaignsTimeBasedCapping;

/// Represents the global cappings for local campaigns
@interface BALocalCampaignsGlobalCappings : NSObject

/// Number of in-apps allowed during the user session
@property (nullable) NSNumber *session;

/// List of time-based cappings
@property (nullable) NSArray<BALocalCampaignsTimeBasedCapping *>* timeBasedCappings;

@end

/**
 Represents a time-based capping rule
 Eg: display no more than 3 in-apps in 1 hour
 */
@interface BALocalCampaignsTimeBasedCapping : NSObject

/// Number of views allowed
@property (nullable) NSNumber *views;

/// Capping duration ( in seconds )
@property (nullable) NSNumber *duration;


@end

