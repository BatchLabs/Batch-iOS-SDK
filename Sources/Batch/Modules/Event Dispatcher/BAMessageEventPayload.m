//
//  BAMessageEventPayload.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAMessageEventPayload.h>

@implementation BAMessageEventPayload {
    NSDictionary *_customPayload;
}

- (instancetype)initWithMessage:(nonnull BatchMessage *)message action:(nullable BAMSGAction *)action {
    self = [super init];
    if (self) {
        _sourceMessage = message;
        [self sharedSetup];
        [self setupAction:action];
        _webViewAnalyticsIdentifier = nil;
    }
    return self;
}

- (nonnull instancetype)initWithMessage:(nonnull BatchMessage *)message
                                 action:(nullable BAMSGAction *)action
             webViewAnalyticsIdentifier:(nullable NSString *)webViewAnalyticsIdentifier {
    self = [super init];
    if (self) {
        _sourceMessage = message;
        [self sharedSetup];
        [self setupAction:action];
        _webViewAnalyticsIdentifier = webViewAnalyticsIdentifier;
    }
    return self;
}

- (void)sharedSetup {
    _trackingId = _sourceMessage.devTrackingIdentifier;
    _customPayload = nil;
    _notificationUserInfo = nil;
    if ([_sourceMessage isKindOfClass:BatchInAppMessage.class]) {
        _customPayload = ((BatchInAppMessage *)_sourceMessage).customPayload;
    } else if ([_sourceMessage isKindOfClass:BatchPushMessage.class]) {
        NSDictionary *pushPayload = ((BatchPushMessage *)_sourceMessage).pushPayload;
        _notificationUserInfo = pushPayload;
        NSMutableDictionary *customPayload = [pushPayload mutableCopy];
        [customPayload removeObjectForKey:kWebserviceKeyPushBatchData];
        _customPayload = customPayload;
    }
    _deeplink = nil;
}

- (void)setupAction:(BAMSGAction *)action {
    _isPositiveAction = action != nil && ![action isDismissAction];
    if ([action.actionIdentifier isEqualToString:@"batch.deeplink"]) {
        NSObject *obj = action.actionArguments[@"l"];
        if ([obj isKindOfClass:[NSString class]]) {
            _deeplink = (NSString *)obj;
        }
    }
}

- (nullable NSObject *)customValueForKey:(nonnull NSString *)key {
    return _customPayload[key];
}

@end
