//
//  BAInbox.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BatchInboxNotificationContent;

@interface BAInboxNotificationContentIdentifiers : NSObject
@property (nonatomic, nonnull) NSString *identifier;
@property (nonatomic, nonnull) NSString *sendID;
@property (nonatomic, nullable) NSString *installID;
@property (nonatomic, nullable) NSString *customID;
@property (nonatomic, nullable) NSDictionary *additionalData;
@end

@interface BAInboxNotificationContent : NSObject

@property (nonatomic, nonnull) BAInboxNotificationContentIdentifiers *identifiers;
@property (nonatomic, nonnull) NSDate *date;
@property (nonatomic, nullable) NSMutableArray<BAInboxNotificationContentIdentifiers*> *duplicateIdentifiers;
@property (nonatomic, nonnull) NSDictionary *payload;
@property (nonatomic) BOOL isUnread;
@property (nonatomic) BOOL isDeleted;

- (void)addDuplicatedIdentifiers:(BAInboxNotificationContentIdentifiers *_Nonnull)identifiers;

@end

/*
 A candidate notification is a notifications from the local database that needs to be sync with the server.
 When the fetcher will try to fetch notifications, it will first look in the local database,
 retrieve what it believe are the right notifications (called candidate notifications),
 sync them with the server, and return them.
 */
@interface BAInboxCandidateNotification : NSObject

@property (nonatomic, nonnull) NSString *identifier;
@property (nonatomic) BOOL isUnread;

@end

@interface BAInbox : NSObject

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initForInstallation;

- (nullable instancetype)initForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)authKey;

@property NSUInteger maxPageSize;

@property NSUInteger limit;

@property BOOL performHandlersOnMainThread;

@property (readonly, nonnull) NSArray<BatchInboxNotificationContent*> *allFetchedNotifications;

@property (readonly) BOOL endReached;

@property BOOL filterSilentNotifications;

- (void)fetchNewNotifications:(void (^ _Nullable)(NSError *_Nullable error, NSArray<BatchInboxNotificationContent *> *_Nullable notifications, BOOL foundNewNotifications, BOOL endReached))completionHandler;

- (void)fetchNextPage:(void (^ _Nullable)(NSError *_Nullable error, NSArray<BatchInboxNotificationContent *> *_Nullable notifications, BOOL endReached))completionHandler;

- (void)markNotificationAsRead:(nonnull BatchInboxNotificationContent *)notification;

- (void)markAllNotificationsAsRead;

- (void)markNotificationAsDeleted:(nonnull BatchInboxNotificationContent*)notification;

@end
