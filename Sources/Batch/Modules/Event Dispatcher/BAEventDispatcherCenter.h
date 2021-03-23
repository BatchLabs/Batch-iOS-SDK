//
//  BAEventDispatcherCenter.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAMSGAction.h>
#import <Batch/BAPushEventPayload.h>
#import <Batch/BAMessageEventPayload.h>
#import <Batch/BAPushPayload.h>
#import <Batch/BatchEventDispatcher.h>

@interface BAEventDispatcherCenter : NSObject <BACenterProtocol>

@property (readonly, nonnull) NSMutableSet<id<BatchEventDispatcherDelegate>> * dispatchers;

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage*)message;

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage *)message action:(nullable BAMSGAction*)msgAction;

+ (nullable BAMessageEventPayload*)messageEventPayloadFromMessage:(nonnull BatchMessage *)message
                                                           action:(nullable BAMSGAction*)msgAction
                                       webViewAnalyticsIdentifier:(nullable NSString*)webViewAnalyticsIdentifier;

- (void)addEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher;

- (void)removeEventDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher;

- (void)dispatchEventWithType:(BatchEventDispatcherType)type payload:(nonnull id<BatchEventDispatcherPayload>)payload;

@end
