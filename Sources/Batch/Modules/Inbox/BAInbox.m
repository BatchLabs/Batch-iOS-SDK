//
//  BAInbox.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BAInbox.h>
#import <Batch/BatchInbox.h>
#import <Batch/BatchInboxPrivate.h>
#import <Batch/BAInboxFetchWebserviceClient.h>
#import <Batch/BAInboxSyncWebserviceClient.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAInboxSQLiteDatasource.h>
#import <Batch/BAInboxSQLiteHelper.h>
#import <Batch/BAInjection.h>

#define DEBUG_DOMAIN @"Inbox"

#define LOCAL_ERROR_DOMAIN @"com.batch.inbox"

@interface BAInbox()
{
    dispatch_queue_t _dispatchQueue;
    NSMutableArray *_fetchedMessages;
    NSString *_cursor;
    BOOL _endReached;
    BAInboxWebserviceClientType _clientType;
    NSString *_clientIdentifier;
    NSString *_clientAuthKey;
    long long _fetcherId;
}
@end

@implementation BAInbox

+ (void)load
{
    BAInjectable *lcInjectable = [BAInjectable injectableWithInitializer: ^id () {
        static id singleInstance = nil;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            singleInstance = [[BAInboxSQLiteDatasource alloc] initWithFilename:@"ba_in.db" forDBHelper:[BAInboxSQLiteHelper new]];
        });
        return singleInstance;
    }];
                             
    [BAInjection registerInjectable:lcInjectable
                        forProtocol:@protocol(BAInboxDatasourceProtocol)];
}

- (instancetype)init
{
    return nil;
}

- (nonnull instancetype)initForInstallation
{
    return [self initForInstallationUsingCache:YES];
}

- (nonnull instancetype)initForInstallationUsingCache:(BOOL)useCache
{
    self = [super init];
    if (self) {
        _clientType = BAInboxWebserviceClientTypeInstallation;
        _clientIdentifier = [BAPropertiesCenter valueForShortName:@"di"];
        _clientAuthKey = nil;
        [self setupUsingCache:useCache];
    }
    return self;
}

- (nullable instancetype)initForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)authKey
{
    return [self initForUserIdentifier:identifier authenticationKey:authKey usingCache:YES];
}

- (nullable instancetype)initForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)authKey usingCache:(BOOL)useCache
{
    self = [super init];
    if (self) {
        _clientType = BAInboxWebserviceClientTypeUserIdentifier;
        _clientIdentifier = identifier;
        _clientAuthKey = authKey;
        [self setupUsingCache:useCache];
        
        if ([BANullHelper isStringEmpty:identifier]) {
            return nil;
        }
    }
    return self;
}

- (void)setupUsingCache:(BOOL)useCache
{
    _dispatchQueue = dispatch_queue_create("com.batch.push.inbox", NULL);
    _fetchedMessages = [NSMutableArray new];
    _endReached = false;
    _maxPageSize = 20;
    _limit = 200;
    _performHandlersOnMainThread = true;
    if (useCache) {
        _fetcherId = [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] createFetcherIdWith:_clientType identifier:_clientIdentifier];
    } else {
        _fetcherId = -1;
    }
}

#pragma mark Public API

- (void)fetchNewNotifications:(void (^ _Nullable)(NSError *_Nullable error, NSArray<BatchInboxNotificationContent *> *_Nullable notifications, BOOL foundNewNotifications, BOOL endReached))completionHandler
{
    dispatch_async(_dispatchQueue, ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        [self fetchFromWSForCursor:nil callback:^(NSError *error, BAInboxWebserviceResponse *result) {

            void (^callbackToPerform)(void) = NULL;

            if (error != nil) {
                if (completionHandler) {
                    callbackToPerform = ^() {
                        completionHandler(error, nil, false, false);
                    };
                }
            } else if (result == nil) {
                NSError *err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                                   code:-300
                                               userInfo:@{NSLocalizedDescriptionKey: @"Internal error."}];
                callbackToPerform = ^() {
                    completionHandler(err, nil, false, false);
                };
            } else {
                NSError *err = nil;
                NSArray<BAInboxNotificationContent*>* messages = [self handleResult:result didAskNewMessages:true error:&err];
                if (completionHandler) {
                    callbackToPerform = ^() {
                        if (err) {
                            completionHandler(err, nil, false, false);
                        } else {
                            BOOL endReached = self->_endReached;
                            completionHandler(nil, [self convertPrivateModelsToPublic:messages], false, endReached);
                        }
                    };
                }
            }

            dispatch_semaphore_signal(waitSemaphore);

            if (callbackToPerform) {
                if (self.performHandlersOnMainThread) {
                    [BAThreading performBlockOnMainThreadAsync:callbackToPerform];
                } else {
                    callbackToPerform();
                }
            }
        }];

        if (dispatch_semaphore_wait(waitSemaphore, dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC))) {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"The semaphore waiting for the fetch expired. That should NOT happen."];
        }
    });
}

- (void)fetchNextPage:(void (^ _Nullable)(NSError *_Nullable error, NSArray<BatchInboxNotificationContent *> *_Nullable notifications, BOOL endReached))completionHandler
{
    if ([self endReached]) {
        if (completionHandler) {
            NSError *err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                               code:-200
                                           userInfo:@{NSLocalizedDescriptionKey: @"The end of the inbox feed has been reached, either because the server has nothing left to send or because the fetcher limit has been reached. You can try bumping the limit using -[BatchInboxFetcher setLimit:]."}];
            completionHandler(err, nil, true);
        }
        return;
    }
    
    if (_cursor == nil) {
        [self fetchNewNotifications:^(NSError *error, NSArray<BatchInboxNotificationContent *> *notifications, BOOL foundNewMessages, BOOL endReached) {
            if (completionHandler) {
                completionHandler(error, notifications, endReached);
            }
        }];
        return;
    }
    
    dispatch_async(_dispatchQueue, ^{
        dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);

        [self fetchFromWSForCursor:self->_cursor callback:^(NSError *error, BAInboxWebserviceResponse *result) {

            void (^callbackToPerform)(void) = NULL;

            if (error != nil) {
                if (completionHandler) {
                    callbackToPerform = ^() {
                        completionHandler(error, nil, false);
                    };
                }
            } else if (result == nil) {
                NSError *err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                                   code:-300
                                               userInfo:@{NSLocalizedDescriptionKey: @"Internal error."}];
                callbackToPerform = ^() {
                    completionHandler(err, nil, false);
                };
            } else {
                NSError *err = nil;
                NSArray<BAInboxNotificationContent*>* messages = [self handleResult:result didAskNewMessages:false error:&err];
                if (completionHandler) {
                    callbackToPerform = ^() {
                        if (err) {
                            completionHandler(err, nil, false);
                        } else {
                            BOOL endReached = self->_endReached;
                            completionHandler(nil, [self convertPrivateModelsToPublic:messages], endReached);
                        }
                    };
                }
            }

            dispatch_semaphore_signal(waitSemaphore);

            if (callbackToPerform) {
                if (self.performHandlersOnMainThread) {
                    [BAThreading performBlockOnMainThreadAsync:callbackToPerform];
                } else {
                    callbackToPerform();
                }
            }
        }];

        if (dispatch_semaphore_wait(waitSemaphore, dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC))) {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"The semaphore waiting for the fetch expired. That should NOT happen."];
        }
    });
}

- (void)markNotificationAsRead:(nonnull BatchInboxNotificationContent *)notification
{
    if (notification == nil) {
        return;
    }
    
    @synchronized (_fetchedMessages) {
        BAInboxNotificationContent *internalNotification = nil;
        for(BAInboxNotificationContent *fetchedMsg in _fetchedMessages) {
            if ([fetchedMsg.identifiers.identifier isEqualToString:notification.identifier]) {
                internalNotification = fetchedMsg;
                break;
            }
        }
        
        if (internalNotification != nil) {
            NSArray<NSDictionary*> *eventDatas = [self eventDatasForNotificationContent:internalNotification];
            for (NSDictionary *eventData in eventDatas) {
                [BATrackerCenter trackPrivateEvent:@"_INBOX_MARK_READ" parameters:eventData];
            }
            [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] markAsRead: internalNotification.identifiers.identifier];
            internalNotification.isUnread = false;
            [notification _markAsRead];
        } else {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Could not find the specified notification (%@) to be marked as read", notification.identifier];
        }
    }
}

- (void)markAllNotificationsAsRead
{
    @synchronized (_fetchedMessages) {
        if ([_fetchedMessages count] > 0) {
            NSArray<NSDictionary*> *eventDatas = [self eventDatasForNotificationContent:_fetchedMessages[0]];
            for (NSDictionary *eventData in eventDatas) {
                [BATrackerCenter trackPrivateEvent:@"_INBOX_MARK_ALL_READ" parameters:eventData];
            }
            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
            [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] markAllAsRead:(long long)now withFetcherId:_fetcherId];
            for (BAInboxNotificationContent* msg in _fetchedMessages) {
                msg.isUnread = false;
            }
        }
    }
}

- (void)markNotificationAsDeleted:(nonnull BatchInboxNotificationContent*)notification
{
    if (notification == nil) {
        return;
    }
    
    @synchronized (_fetchedMessages) {
        BAInboxNotificationContent *internalNotification = nil;
        for(BAInboxNotificationContent *fetchedMsg in _fetchedMessages) {
            if ([fetchedMsg.identifiers.identifier isEqualToString:notification.identifier]) {
                internalNotification = fetchedMsg;
                break;
            }
        }
        
        if (internalNotification != nil) {
            NSArray<NSDictionary*> *eventDatas = [self eventDatasForNotificationContent:internalNotification];
            for (NSDictionary *eventData in eventDatas) {
                [BATrackerCenter trackPrivateEvent:@"_INBOX_MARK_DELETED" parameters:eventData];
            }
            internalNotification.isDeleted = true;
            [notification _markAsDeleted];
            [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] markAsDeleted: internalNotification.identifiers.identifier];
            [_fetchedMessages removeObject: internalNotification];
        } else {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"Could not find the specified notification (%@) to be marked as deleted", notification.identifier];
        }
    }
}

- (BOOL)endReached
{
    return _endReached || [_fetchedMessages count] >= self.limit;
}

- (NSArray<NSObject*>*)allFetchedNotifications
{
    //Someday, reimplement this by keeping a cache of the public models, alongside smarter deduplication of the first refresh
    NSArray<BAInboxNotificationContent*>* messages;
    @synchronized (_fetchedMessages) {
        messages = [_fetchedMessages copy];
    }
    return [self convertPrivateModelsToPublic:messages];
}

#pragma mark Private API

- (void)fetchFromWSForCursor:(NSString*)cursor callback:(void (^ _Nonnull)(NSError* _Nullable error, BAInboxWebserviceResponse* _Nullable result))callback
{
    // Before the first fetch or sync, we clean old notifications for the DB
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] cleanDatabase];
    });
    
    if (_fetcherId != -1) {
        NSArray<BAInboxCandidateNotification*> *candidates = [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] candidateNotificationsFromCursor:cursor limit:self.maxPageSize fetcherId:_fetcherId];
        if ([candidates count] > 0) {
            [self syncFromWSForCursor:cursor candidates:candidates callback:callback];
            return;
        }
    }
    
    BAWebserviceClient *wsClient = [[BAInboxFetchWebserviceClient alloc] initWithIdentifier:_clientIdentifier
                                                                                       type:_clientType
                                                                          authenticationKey:_clientAuthKey
                                                                                      limit:self.maxPageSize
                                                                                  fetcherId:_fetcherId
                                                                                  fromToken:cursor
                                                                                    success:^(BAInboxWebserviceResponse* _Nonnull response) {
                                                                                        callback(nil, response);
                                                                                    } error:^(NSError* _Nonnull error) {
                                                                                        callback(error, nil);
                                                                                    }];

    [BAWebserviceClientExecutor.sharedInstance addClient:wsClient];
}



- (void)syncFromWSForCursor:(NSString*)cursor candidates:(NSArray<BAInboxCandidateNotification*> *)candidates callback:(void (^ _Nonnull)(NSError* _Nullable error, BAInboxWebserviceResponse* _Nullable result))callback
{
    BAWebserviceClient *wsClient = [[BAInboxSyncWebserviceClient alloc] initWithIdentifier:_clientIdentifier
                                                                                       type:_clientType
                                                                          authenticationKey:_clientAuthKey
                                                                                      limit:self.maxPageSize
                                                                                  fetcherId:_fetcherId
                                                                                 candidates:candidates
                                                                                  fromToken:cursor
                                                                                    success:^(BAInboxWebserviceResponse* _Nonnull response) {
                                                                                        callback(nil, response);
                                                                                    } error:^(NSError* _Nonnull error) {
                                                                                        callback(error, nil);
                                                                                    }];

    [BAWebserviceClientExecutor.sharedInstance addClient:wsClient];
}

- (NSArray<BAInboxNotificationContent*>*)handleResult:(BAInboxWebserviceResponse *)result didAskNewMessages:(BOOL)newMessages error:(NSError**)error
{
    @synchronized (_fetchedMessages) {
        if (result.didTimeout && [result.notifications count] == 0) {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-101
                                         userInfo:@{NSLocalizedDescriptionKey: @"Server could not respond in time: no notifications have been fetched. Please retry later."}];
            }
            return nil;
        }
        
        _endReached = !result.hasMore;
        
        //Todo: merge with already fecthed messages (v2)
        if (newMessages) {
            [_fetchedMessages removeAllObjects];
        }
        
        // We also need to deduplicate the result array we give back in the callback
        NSMutableArray<BAInboxNotificationContent*> *addedNotifications = [NSMutableArray new];
        
        // Deduplicate based on sendID
        for (BAInboxNotificationContent *resMsg in result.notifications) {
            NSString *sendID = resMsg.identifiers.sendID;
            BAInboxNotificationContent *duplicateNotif = nil;
            for (BAInboxNotificationContent *fetchedMsg in _fetchedMessages) {
                if ([fetchedMsg.identifiers.sendID isEqualToString:sendID]) {
                    duplicateNotif = fetchedMsg;
                    break;
                }
            }
            
            if (duplicateNotif != nil) {
                if ([resMsg.identifiers.identifier isEqualToString:duplicateNotif.identifiers.identifier]) {
                    [BALogger debugForDomain:DEBUG_DOMAIN
                                     message:@"Got the exact same notification twice. Skipping. (id %@)", resMsg.identifiers.identifier];
                } else {
                    [BALogger debugForDomain:DEBUG_DOMAIN
                                     message:@"Merging notifications for sendID %@ (identifiers: %@, %@)", sendID, resMsg.identifiers.identifier, duplicateNotif.identifiers.identifier];
                    
                    [duplicateNotif addDuplicatedIdentifiers:resMsg.identifiers];
                    
                    // If a notification is read, propagate this to the deduplicated notification
                    if (!resMsg.isUnread) {
                        duplicateNotif.isUnread = false;
                    }
                    
                }
            } else {
                [_fetchedMessages addObject:resMsg];
                [addedNotifications addObject:resMsg];
            }
        }
        
        _cursor = result.cursor;
        return addedNotifications;
    }
}

- (NSArray<BatchInboxNotificationContent*>*)convertPrivateModelsToPublic:(NSArray<BAInboxNotificationContent*>*)privateModels
{
    if (privateModels == nil) {
        return nil;
    }
    NSMutableArray<BatchInboxNotificationContent*> *models = [NSMutableArray new];

    for (BAInboxNotificationContent *privateModel in privateModels) {
        
        BatchInboxNotificationContent *model = [[BatchInboxNotificationContent alloc] initWithInternalIdentifier:privateModel.identifiers.identifier
                                                                                                      rawPayload:privateModel.payload
                                                                                                        isUnread:privateModel.isUnread
                                                                                                            date:privateModel.date];
        if (model != nil) {
            [models addObject:model];
        } else {
            [BALogger debugForDomain:DEBUG_DOMAIN
                             message:@"Error while converting private model to public"];
        }
    }

    return models;
}

// One event needs to be triggered per entry
- (NSArray<NSDictionary*>*)eventDatasForNotificationContent:(BAInboxNotificationContent*)content
{
    NSMutableArray *datas = [NSMutableArray new];
    
    if (content == nil) {
        return datas;
    }
    
    NSMutableArray<BAInboxNotificationContentIdentifiers*> *contentIdentifiers = [NSMutableArray arrayWithObject:content.identifiers];
    if (content.duplicateIdentifiers != nil) {
        [contentIdentifiers addObjectsFromArray:content.duplicateIdentifiers];
    }
    
    for (BAInboxNotificationContentIdentifiers* i in contentIdentifiers) {
        NSObject *customID = i.customID;
        if (customID == nil && _clientType == BAInboxWebserviceClientTypeUserIdentifier) {
            customID = _clientIdentifier;
        }
        if (customID == nil) {
            customID = [NSNull null];
        }
            
        [datas addObject:@{
                           @"notificationId": i.identifier,
                           @"notificationInstallId": i.installID != nil ? i.installID : [NSNull null],
                           @"notificationCustomId": customID,
                           @"additionalData": i.additionalData != nil ? i.additionalData : [NSNull null],
                           }];
    }
    
    return datas;
}

@end

@implementation BAInboxCandidateNotification
@end

@implementation BAInboxNotificationContent

- (void)addDuplicatedIdentifiers:(BAInboxNotificationContentIdentifiers *)identifiers
{
    if (identifiers == nil) {
        return;
    }
    
    if (self.duplicateIdentifiers == nil) {
        self.duplicateIdentifiers = [NSMutableArray new];
    }
    
    [self.duplicateIdentifiers addObject:identifiers];
}

@end

@implementation BAInboxNotificationContentIdentifiers
@end
