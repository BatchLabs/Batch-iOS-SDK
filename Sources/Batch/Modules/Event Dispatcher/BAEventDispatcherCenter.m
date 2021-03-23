//
//  BAEventDispatcherCenter.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAInjection.h>

#define LOGGER_DOMAIN @"EventDispatcher"

@implementation BAEventDispatcherCenter

+ (void)load
{
    BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
                                    static id singleInstance = nil;
                                    static dispatch_once_t once;
                                    dispatch_once(&once, ^{
                                      singleInstance = [BAEventDispatcherCenter new];
                                    });
                                    return singleInstance;
                                }];
    [BAInjection registerInjectable:lcInjectable forClass:BAEventDispatcherCenter.class];
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dispatchers = [NSMutableSet set];
    }
    return self;
}

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage*)message
{
    return [self messageEventPayloadFromMessage:message action:nil];
}

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage*)message action:(nullable BAMSGAction*)msgAction
{
    return [[BAMessageEventPayload alloc] initWithMessage:(BatchInAppMessage*) message action:msgAction];
}

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage *)message
                                                           action:(nullable BAMSGAction*)action
                                       webViewAnalyticsIdentifier:(nullable NSString*)webViewAnalyticsIdentifier
{
    return [[BAMessageEventPayload alloc] initWithMessage:(BatchInAppMessage*)message
                                                   action:action
                               webViewAnalyticsIdentifier:webViewAnalyticsIdentifier];
}

- (void)addEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher
{
    [BALogger publicForDomain:LOGGER_DOMAIN message:@"Adding event dispatcher: %@", NSStringFromClass([dispatcher class])];
    [self.dispatchers addObject:(dispatcher)];
}

- (void)removeEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher
{
    [self.dispatchers removeObject:(dispatcher)];
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
