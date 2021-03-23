//
//  BATrackingAuthorization.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BATrackingAuthorizationStatus) {

    // iOS returned a tracking authorization status that we don't know about
    BATrackingAuthorizationStatusUnknown = 0,
    
    // Tracking has been disabled in Batch's configuration
    BATrackingAuthorizationStatusForbiddenByBatchConfig = 1,
    
    // User denied tracking (limitsAdTracking on iOS 13 and lower matches this)
    BATrackingAuthorizationStatusDenied = 2,
    
    // User agreed to tracking. On iOS 13 and lower this is the default value, but on iOS 14 this is only used when the user explicitly allowed tracking via AppTrackingTransparency
    BATrackingAuthorizationStatusAuthorized = 3,
    
    // iOS 14+: we don't know if the user allowed tracking
    BATrackingAuthorizationStatusNotDetermined = 4,
    
    // iOS 14+: Tracking is disabled by policy and can't be enabled by the user
    BATrackingAuthorizationStatusRestricted = 5,
};


@interface BATrackingAuthorization : NSObject

@property (readonly) BATrackingAuthorizationStatus trackingAuthorizationStatus;

@property (nullable, readonly) NSUUID* attributionIdentifier;

- (void)settingsMayHaveChanged;

@end

NS_ASSUME_NONNULL_END
