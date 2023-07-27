//
//  BAInboxDatasourceProtocol.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInbox.h>
#import <Batch/BAInboxWebserviceClientType.h>
#import <Batch/BAInboxWebserviceResponse.h>
#import <Foundation/Foundation.h>

/*!
 @protocol BAInboxDatasourceProtocol
 @abstract Protocol defining methods for accessing an inbox datasource
 */
@protocol BAInboxDatasourceProtocol <NSObject>

/*!
 @method close
 @abstract Close the database. You should call this before deallocing it
 */
- (void)close;

/*!
 @method clear
 @abstract Clear the database. Should only be used for tests;
 */
- (void)clear;

/*!
@method notifications:withFetcherId
@abstract Get a list of notifications
*/
- (nonnull NSArray<BAInboxNotificationContent *> *)notifications:(nonnull NSArray<NSString *> *)notificaitonIds
                                                   withFetcherId:(long long)fetcherId;

/*!
@method candidateNotificationsFromCursor:limit:fetcherId
@abstract Get candidates notifcations from cache
*/
- (nullable NSArray<BAInboxCandidateNotification *> *)candidateNotificationsFromCursor:(nullable NSString *)cursor
                                                                                 limit:(NSUInteger)limit
                                                                             fetcherId:(long long)fetcherId;

/*!
@method createFetcherIdWith:identifier
@abstract Create or get the corresponding fetcher in db
*/
- (long long)createFetcherIdWith:(BAInboxWebserviceClientType)type identifier:(nonnull NSString *)identifier;

/*!
@method insertResponse:withFetcherId
@abstract Insert a response in database
*/
- (BOOL)insertResponse:(nonnull BAInboxWebserviceResponse *)response withFetcherId:(long long)fetcherId;

/*!
@method insertNotification:fetcherId
@abstract Insert a notification in database
*/
- (BOOL)insertNotification:(nonnull BAInboxNotificationContent *)notification withFetcherId:(long long)fetcherId;

/*!
@method updateNotification:withFetcherId
@abstract Update the notification from a payload
*/
- (nullable NSString *)updateNotification:(nonnull NSDictionary *)dictionary withFetcherId:(long long)fetcherId;

/*!
@method markAsDeleted
@abstract Mark a notification as deleted
*/
- (BOOL)markAsDeleted:(nonnull NSString *)notificationId;

/*!
@method markAsRead
@abstract Mark a notification as read
*/
- (BOOL)markAsRead:(nonnull NSString *)notificationId;

/*!
@method markAllAsRead:withFetcherId
@abstract Mark all notifications before a specified time as read
*/
- (BOOL)markAllAsRead:(long long)time withFetcherId:(long long)fetcherId;

/*!
@method deleteNotifications
@abstract Delete notifications
*/
- (BOOL)deleteNotifications:(nonnull NSArray<NSString *> *)notificaitonIds;

/*!
@method cleanDatabase
@abstract Clean old notifications from the database
*/
- (BOOL)cleanDatabase;

@end
