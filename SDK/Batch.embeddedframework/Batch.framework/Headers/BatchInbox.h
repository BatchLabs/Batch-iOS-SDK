//
//  BatchInbox.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2017 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BatchMessaging.h"
#import "BatchPush.h"

/**
 BatchInboxNotificationContent is the model for notifications fetched using the Inbox API
 Use it to display them in the way you like.
 */
@interface BatchInboxNotificationContent : NSObject

/**
 Unique notification identifier. Do not make assumptions about its format: it can change at any time.
 */
@property (nonatomic, readonly, nonnull) NSString *identifier;

/**
 Notification title (if present)
 */
@property (nonatomic, readonly, nullable) NSString *title;

/**
 Notification alert body
 */
@property (nonatomic, readonly, nonnull) NSString *body;

/**
 URL of the rich notification attachment (image/audio/video)
 */
@property (nonatomic, readonly, nullable) NSURL *attachmentURL;

/**
 Raw notification user data (also called payload)
 */
@property (nonatomic, readonly, nonnull) NSDictionary *payload;

/**
 Date at which the push notification has been sent to the device
 */
@property (nonatomic, readonly, nonnull) NSDate *date;

/**
 Flag indicating whether this notification is unread or not
 */
@property (nonatomic, readonly) BOOL isUnread;

/**
 The push notification's source, indicating what made Batch send it. It can come from a push campaign via the API or the dashboard, or from the transactional API, for example.
 */
@property (nonatomic, readonly) BatchNotificationSource source;

@end

/**
 BatchInboxFetcher allows you to fetch notifications that have been sent to a user (or installation, more on that later) in their raw form,
 allowing you to display them in a list, for example. This is also useful to display messages to users that disabled notifications.
 
 Once you get your BatchInboxFetcher instance, you should call fetchNewNotifications: to fetch the initial page of messages: nothing is done automatically.
 This method is also useful to refresh the list.
 
 In an effort to minimize network and memory usage, messages are fetched by page (batches of messages):
 this allows you to easily create an infinite list, loading more messages on demand.
 While you can configure the maximum number of messages you want in a page, the actual number of returned messages can differ, as the SDK may filter some of the messages returned by the server (such as duplicate notifications, etc...).
 
 As BatchInboxFetcher caches answers from the server, instances of this class should be tied to the lifecycle of the UI consuming it.
 For example, you should keep a reference to this object during your UIViewController's entire life.
 Another reason to keep the object around, is that you cannot mark a message as read with another BatchInbox instance that the one
 that gave you the message in the first place.
 
 A BatchInboxFetcher instance will hold to all fetched messages: be careful of how long you're keeping the instances around.
 You can also set a upper messages limit, after which BatchInbox will stop fetching new messages, even if you call fetchNextPage.
 */
@interface BatchInboxFetcher: NSObject

/**
 This class should not be instanciated directly: use BatchInbox to get a correctly initialized instance.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 Number of notifications to fetch on each call, up to 100 messages per page.
 Note that the actual count of fetched messages might differ from the value you've set here.
 */
@property (nonatomic) NSUInteger maxPageSize;

/**
 Maximum number of notifications to fetch. This allows you to let Batch manage the upper limit itself, so you can be sure not to use a crazy amount of memory.
 If you want to fetch unlimited messages, set this property to 0.
 
 Default value: 200
 */
@property (nonatomic) NSUInteger limit;

/**
 Returns a copy of all notifications that have been fetched until now, ordered by reverse chronological order (meaning that the first message is the newest one, and the last one the oldest).
 Note that this array will be empty until you call fetchNextPage:, and will only grow on subsequent fetches.
 
 Warning: in this version, allFetchedNotifications always regenerates the public models when called. You should cache the return value of this property, and only call it when you know you need to refresh your copy of the data.
 */
@property (readonly, nonnull) NSArray<BatchInboxNotificationContent*> *allFetchedNotifications;

/**
 Returns whether all of the user or installation's notifications have been fetched.
 If this property returns YES, calling fetchNextPage will always return an error, as there is nothing left to fetch.
 Also artificially returns YES if the maximum number of fetched messages has been reached.
 */
@property (readonly) BOOL endReached;

/**
 Fetch new notifications.
 While fetchNextPage: is used to fetch older notifications than the ones currently loaded, this method checks for new notifications. For example, this is the method you would call on initial load, or on a "pull to refresh".
 If new notifications are found, the previously fetched ones will be kept if possible, but might be cleared to ensure consistency.For example, if a gap were to happen because of a refresh, old notifications would be removed from the cache.
 
 The completion handler is called on the main queue.
 
 @param completionHandler An optional completion handler can be executed on success or failure with either the fetched notifications or the detailed error.
 */
- (void)fetchNewNotifications:(void (^ _Nullable)(NSError* _Nullable error, NSArray<BatchInboxNotificationContent*>* _Nullable notifications, BOOL foundNewNotifications, BOOL endReached))completionHandler;

/**
 Fetch a page of notifications.
 The completion handler is called on the main queue.
 Calling this method when no messages have been loaded will be equivalent to calling fetchNewNotifications:
 
 @param completionHandler An optional completion handler can be executed on success or failure with either the fetched notifications or the detailed error.
 */
- (void)fetchNextPage:(void (^ _Nullable)(NSError* _Nullable error, NSArray<BatchInboxNotificationContent*>* _Nullable notifications, BOOL endReached))completionHandler;

/**
 Mark a specific notification as read.
 The notification you provide will see its isUnread property updated.
 
 If you call fetchNewNotifications: right away (or get a new BatchInboxFetcher instance), you might have notifications that you've marked as read come back to an unread state, since the server may have not processed the request yet.
 
 @param notification The notification to be marked as read.
 */
- (void)markNotificationAsRead:(nonnull BatchInboxNotificationContent*)notification;

/**
 Marks all notifications as read.
 
 Note that you will have to call allFetchedNotifications again to update the isUnread status of your copy of the notifications. If you call fetchNewNotifications: right away (or get a new BatchInboxFetcher instance), you might have notifications that you've marked as read come back to an unread state, since the server may have not processed the request yet.
 */
- (void)markAllNotificationsAsRead;

@end

/**
 Batch's inbox module. Use this to get a configured instance of the inbox client.
 */
@interface BatchInbox : NSObject

/**
 Get an inbox fetcher for the current installation ID
 Batch must be started for this method to work.
 
 @return an instance of BatchInboxFetcher with the wanted configuration
 */
+ (nonnull BatchInboxFetcher*)fetcher;

/**
 Get an inbox fetcher for the specified user identifier.
 Batch must be started for this method to work.
 
 @param identifier User identifier for which you want the notifications
 @param authKey Secret authentication key: it should be computed your backend and given to this method
 @return an instance of BatchInboxFetcher with the wanted configuration
 */
+ (nullable BatchInboxFetcher*)fetcherForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)authKey;

@end
