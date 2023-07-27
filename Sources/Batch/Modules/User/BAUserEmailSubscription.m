//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAUserEmailSubscription.h"
#import <Batch/BALogger.h>
#import <Batch/BATrackerCenter.h>

#define DEBUG_DOMAIN @"BAUserEmailSubscription"

@implementation BAUserEmailSubscription {
    /// User email
    NSString *_email;

    /// If we should delete the email
    BOOL _deleteEmail;

    /// Subscriptions
    NSMutableDictionary *_subscriptions;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _subscriptions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithEmail:(nullable NSString *)email {
    self = [super init];
    if (self) {
        if (email == nil) {
            _deleteEmail = true;
        }
        _email = email;
        _subscriptions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setEmail:(nullable NSString *)email {
    if (email == nil) {
        _deleteEmail = true;
    }
    _email = email;
}

- (void)setEmailSubscriptionState:(BatchEmailSubscriptionState)state forKind:(BAEmailKind)kind {
    [_subscriptions setValue:[BAUserEmailSubscription subscriptionStateToString:state]
                      forKey:[BAUserEmailSubscription emailKindToString:kind]];
}

- (void)sendEmailSubscriptionEvent {
    // Ensure we have a custom identifier
    NSString *customID = [BatchUser identifier];
    if (customID == nil) {
        [BALogger debugForDomain:DEBUG_DOMAIN message:@"Custom ID nill, not sending event"];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"custom_id"] = customID;

    if (_email != nil) {
        params[@"email"] = _email;
    } else if (_deleteEmail) {
        params[@"email"] = [NSNull null];
    }

    if ([_subscriptions count] != 0) {
        params[@"subscriptions"] = [_subscriptions copy];
    }
    [BATrackerCenter trackPrivateEvent:@"_EMAIL_CHANGED" parameters:params];
}

+ (NSString *)subscriptionStateToString:(BatchEmailSubscriptionState)state {
    NSString *result = nil;
    switch (state) {
        case BatchEmailSubscriptionStateSubscribed:
            result = @"subscribed";
            break;
        case BatchEmailSubscriptionStateUnsubscribed:
            result = @"unsubscribed";
            break;
        default:
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Unknown subscriptions state"];
            break;
    }
    return result;
}

+ (NSString *)emailKindToString:(BAEmailKind)kind {
    NSString *result = nil;
    switch (kind) {
        case BAEmailKindMarketing:
            result = @"marketing";
            break;
        default:
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Unknown email kind"];
            break;
    }
    return result;
}

@end
