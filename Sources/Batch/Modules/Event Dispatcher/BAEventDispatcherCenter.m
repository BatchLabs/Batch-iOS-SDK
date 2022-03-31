//
//  BAEventDispatcherCenter.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAEventDispatcherCenter.h>

#define LOGGER_DOMAIN @"EventDispatcher"

#define CUSTOM_DISPATCHER_NAME @"other"

@implementation BAEventDispatcherCenter

- (instancetype)init {
    self = [super init];
    if (self) {
        _dispatchers = [NSMutableSet set];
    }
    return self;
}

+ (nullable BAMessageEventPayload *)messageEventPayloadFromMessage:(nonnull BatchMessage *)message {
    return [self messageEventPayloadFromMessage:message action:nil];
}

+ (nullable BAMessageEventPayload *)messageEventPayloadFromMessage:(nonnull BatchMessage *)message
                                                            action:(nullable BAMSGAction *)msgAction {
    return [[BAMessageEventPayload alloc] initWithMessage:(BatchInAppMessage *)message action:msgAction];
}

+ (nullable BAMessageEventPayload *)messageEventPayloadFromMessage:(nonnull BatchMessage *)message
                                                            action:(nullable BAMSGAction *)action
                                        webViewAnalyticsIdentifier:(nullable NSString *)webViewAnalyticsIdentifier {
    return [[BAMessageEventPayload alloc] initWithMessage:(BatchInAppMessage *)message
                                                   action:action
                               webViewAnalyticsIdentifier:webViewAnalyticsIdentifier];
}

+ (BOOL)isBatchEventDispatcher:(NSString *)name {
    return [@[ @"firebase", @"at_internet", @"mixpanel", @"google_analytics", @"batch_plugins" ] containsObject:name];
}

- (void)addEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher {
    [BALogger publicForDomain:LOGGER_DOMAIN
                      message:@"Adding event dispatcher: %@", NSStringFromClass([dispatcher class])];
    [self.dispatchers addObject:(dispatcher)];
}

- (void)removeEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher {
    [self.dispatchers removeObject:(dispatcher)];
}

- (nonnull NSDictionary *)dispatchersAnalyticRepresentation {
    NSMutableDictionary *analyticRepresentation = [NSMutableDictionary dictionary];
    for (id<BatchEventDispatcherDelegate> dispatcher in self.dispatchers) {
        if ([dispatcher respondsToSelector:@selector(name)] && [dispatcher respondsToSelector:@selector(version)]) {
            NSString *name = [[dispatcher name] copy];
            if (![BAEventDispatcherCenter isBatchEventDispatcher:name]) {
                name = CUSTOM_DISPATCHER_NAME;
            }
            [analyticRepresentation setObject:[NSNumber numberWithUnsignedInteger:[dispatcher version]] forKey:name];
        }
    }
    return analyticRepresentation;
}

- (void)dispatchEventWithType:(BatchEventDispatcherType)type payload:(id<BatchEventDispatcherPayload>)payload {
    if (![[BAOptOut instance] isOptedOut]) {
        for (id<BatchEventDispatcherDelegate> dispatcher in self.dispatchers) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Dispatching event %ld to %@", (long)type, dispatcher];
            [dispatcher dispatchEventWithType:type payload:payload];
        }
    }
}

@end
