//
//  BatchEventDispatcher.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2019 Batch SDK. All rights reserved.
//

#import <Batch/BatchMessaging.h>

/**
 Protocol to access data associated with a dispatched event.
 */
@protocol BatchEventDispatcherPayload

@required

@property (readonly, nullable) NSString *trackingId;
@property (readonly, nullable) NSString *deeplink;

/**
 * Indicate if the action associated with the event is positive.
 * A positive action is :
 * - An Open for a push campaign
 * - A CTA click or Global tap containing a deeplink or a custom action for an in-app campaign
 */
@property (readonly) BOOL isPositiveAction;

/**
 * Get the analytics identifier associated with the event.
 * Only used for messages of type BatchEventDispatcherTypeMessagingWebViewClick and BatchEventDispatcherTypeMessagingClose.
 * Matches the "analyticsID" parameter of various methods of the JavaScript SDK.
 */
@property (readonly, nullable) NSString *webViewAnalyticsIdentifier;

/**
 * Message that originated this event, if this is a messaging event. Not applicable for notification events.
 */
@property (readonly, nullable) BatchMessage *sourceMessage;

/**
 * UserInfo of the originating remote notification, if this is a notification event.
 *
 * Applicable for messaging events if the message is a mobile landing.
 */
@property (readonly, nullable) NSDictionary *notificationUserInfo;

/**
 * Read a value for a custom payload key
 */
- (nullable NSObject*)customValueForKey:(nonnull NSString*)key;

@end

/**
 Represents the type of a dispatched event.
 */
typedef NS_ENUM(NSInteger, BatchEventDispatcherType) {
        BatchEventDispatcherTypeNotificationOpen,
        BatchEventDispatcherTypeMessagingShow,
        BatchEventDispatcherTypeMessagingClose,
        BatchEventDispatcherTypeMessagingCloseError,
        BatchEventDispatcherTypeMessagingAutoClose,
        BatchEventDispatcherTypeMessagingClick,
        BatchEventDispatcherTypeMessagingWebViewClick,
};

/**
 Represents a dispatcher that can be registered to receive events.
 */
@protocol BatchEventDispatcherDelegate <NSObject>

@required

/**
 Called when a new event happens in the Batch SDK.
 
 No guarantee about the thread this method will be called on is made.

 @param type The type of the event
 @param payload The payload associated with the event
 */
- (void)dispatchEventWithType:(BatchEventDispatcherType)type
                      payload:(nonnull id<BatchEventDispatcherPayload>)payload;

@end

/**
 Batch's Event Dispatcher module.
 */
@interface BatchEventDispatcher : NSObject

/**
 Check if the event is associated with a push notification.
 
 @param eventType The type of the event
 @return True if the event is associated with a push notification, false otherwise
 */
+ (BOOL)isNotificationEvent:(BatchEventDispatcherType)eventType;

/**
 Check if the event is associated with an in-app or landing message.

 @param eventType The type of the event
 @return True if the event is associated with an in-app or landing message, false otherwise
*/
+ (BOOL)isMessagingEvent:(BatchEventDispatcherType)eventType;

/**
 Add an event dispatcher.
 If that dispatcher is already added, it won't be added a second time.
 
 @param dispatcher The dispatcher to add
 */
+ (void)addDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher;

/**
 Remove an event dispatcher.
 If that dispatcher isn't already added, nothing will be done.
 
 @param dispatcher The dispatcher to remove
 */
+ (void)removeDispatcher:(nonnull id<BatchEventDispatcherDelegate>)dispatcher;

@end
