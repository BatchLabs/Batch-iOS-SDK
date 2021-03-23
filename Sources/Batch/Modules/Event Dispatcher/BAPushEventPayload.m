//
//  BAPushEventPayload.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAPushEventPayload.h>
#import <Batch/BAPushCenter.h>

@implementation BAPushEventPayload

- (instancetype)initWithUserInfo:(nonnull NSDictionary*)userInfo
{
    self = [super init];
    if (self) {
        _sourceMessage = nil;
        _notificationUserInfo = userInfo;
        _deeplink = nil;
        _trackingId = nil;
        _isPositiveAction = true;

        _deeplink = [BAPushCenter deeplinkFromUserInfo:userInfo];
    }
    return self;
}

- (nullable NSObject*)customValueForKey:(nonnull NSString*)key
{
    if ([kWebserviceKeyPushBatchData isEqualToString:key]) {
        return nil;
    }
    return self.notificationUserInfo[key];
}

@end
