//
//  BAInboxSyncWebserviceClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInboxSyncWebserviceClient.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAJson.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAInboxDatasourceProtocol.h>
#import <Batch/BAInjection.h>
#import <Batch/BAPushPayload.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BACSS.h>
#import <Batch/BAWebserviceURLBuilder.h>
#import <Batch/BAInboxFetchWebserviceClient.h>

#define DEBUG_DOMAIN @"InboxSyncWebserviceClient"

#define LOCAL_ERROR_DOMAIN @"com.batch.inbox.sync.wsclient"

static const NSString *kBatchWebserviceIdentifierInboxSync = @"inbox_sync";

@implementation BAInboxSyncWebserviceClient {
    NSString *_authKey;
    NSUInteger _limit;
    long long _fetcherId;
    NSString *_fromToken;
    NSMutableDictionary *_body;
    NSArray<BAInboxCandidateNotification*> *_candidates;
    void (^_successHandler)(BAInboxWebserviceResponse* _Nonnull response);
    void (^_errorHandler)(NSError* _Nonnull error);
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString*)identifier
                                       type:(BAInboxWebserviceClientType)type
                          authenticationKey:(nullable NSString*)authKey
                                      limit:(NSUInteger)limit
                                  fetcherId:(long long)fetcherId
                                 candidates:(nonnull NSArray<BAInboxCandidateNotification*> *)candidates
                                  fromToken:(nonnull NSString*)from
                                    success:(void (^ _Nullable)(BAInboxWebserviceResponse* _Nonnull response))successHandler
                                      error:(void (^ _Nullable)(NSError* _Nonnull error))errorHandler
{
    NSURL *url = [self generateURLWithIdentifier:identifier type:type];
    if (url == nil) {
        NSError *err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                           code:-11
                                       userInfo:@{NSLocalizedDescriptionKey: @"No API Key set"}];
        if (errorHandler != nil) {
            errorHandler(err);
        }
        return nil;
    }
    
    // I hate to do stuff before super's init, but the parent class' design sucks ass
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost
                             URL:url
                        delegate:self];
    if (self) {
        _authKey = authKey;
        _limit = limit;
        _fetcherId = fetcherId;
        _candidates = candidates;
        _fromToken = from;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
        
        _body = [NSMutableDictionary new];
        NSMutableArray *notifications = [NSMutableArray new];
        
        for (BAInboxCandidateNotification *candidate in candidates) {
            NSMutableDictionary *bodyCandidate = [NSMutableDictionary new];
            [bodyCandidate setObject:candidate.identifier forKey:@"notificationId"];
            [bodyCandidate setObject:[NSNumber numberWithBool:!candidate.isUnread] forKey:@"read"];
            
            [notifications addObject:bodyCandidate];
        }
        
        [_body setObject:notifications forKey:@"notifications"];
    }
    return self;
}

- (nullable NSURL*)generateURLWithIdentifier:(nonnull NSString*)identifier
                                        type:(BAInboxWebserviceClientType)type
{
    NSURL *url = [BAWebserviceURLBuilder webserviceURLForShortname:@"inbox"];
    
    url = [url URLByAppendingPathComponent:@"sync"];
    url = [url URLByAppendingPathComponent:type == BAInboxWebserviceClientTypeUserIdentifier ? @"custom" : @"install"];
    url = [url URLByAppendingPathComponent:identifier];
    
    return url;
}

- (nonnull NSDictionary<NSString *, NSString *>*)queryParameters
{
    NSMutableDictionary *params = [super queryParameters];

    if (![BANullHelper isStringEmpty:_fromToken]) {
        params[@"from"] = _fromToken;
    }

    if (_limit > 0) {
        params[@"limit"] = [@(_limit) stringValue];
    }

    return params;
}

- (nonnull NSMutableDictionary *)requestHeaders
{
    if ([BANullHelper isStringEmpty:_authKey]) {
        return [super requestHeaders];
    }

    NSMutableDictionary *headers = [super requestHeaders];
    headers[@"X-CustomID-Auth"] = _authKey;
    return headers;
}

- (nonnull NSMutableDictionary *)requestBodyDictionary
{
    return _body;
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data
{
    [super connectionDidFinishLoadingWithData:data];
    [BALogger debugForDomain:DEBUG_DOMAIN
                     message:@"Inbox - Sync Success"];

    NSError *err = nil;
    BAInboxWebserviceResponse *response = [self parseResponse:data error:&err];
    if (err == nil && response == nil) {
        err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                  code:-10
                              userInfo:@{NSLocalizedDescriptionKey: @"An unknown error occurred while decoding the response."}];
    }
    
    if (err != nil) {
        if (_errorHandler != nil) {
            _errorHandler(err);
        }
    } else {
        if (_successHandler != nil) {
            _successHandler(response);
        }
    }
}

- (void)connectionFailedWithError:(NSError *)error
{
    [super connectionFailedWithError:error];
    if ([error.domain isEqualToString:NETWORKING_ERROR_DOMAIN] && error.code == BAConnectionErrorCauseOptedOut) {
        error = [BAErrorHelper optedOutError];
    }
    
    [BALogger debugForDomain:DEBUG_DOMAIN
                     message:@"Inbox - Sync Failure - %@", [error localizedDescription]];
    
    if (error != nil && _errorHandler != nil) {
        _errorHandler(error);
    }
}

- (BOOL)isCandidate:(NSString *)notificationId
{
    for (BAInboxCandidateNotification *candidate in _candidates) {
        if ([candidate.identifier isEqualToString:notificationId]) {
            return YES;
        }
    }
    
    return NO;
}

-(NSString *)parseNotificationId:(NSDictionary *)dictionary
{
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:dictionary errorDomain:@"InboxWebserviceSyncClient"];
    
    NSError *err = nil;
    NSString* notificationId = [json objectForKey:@"notificationId" kindOfClass:[NSString class] allowNil:false error:&err];
    if (err != nil) {
        return nil;
    }
    return notificationId;
}

- (BAInboxWebserviceResponse *)parseResponse:(NSData*)data error:(NSError**)outErr
{
    NSDictionary *raw = [BAJson deserializeDataAsDictionary:data error:outErr];
    if (!raw) {
        return nil;
    }

    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:raw errorDomain:@"InboxWebserviceSyncClient"];

    // Parse cache operations
    NSError *err = nil;
    NSDictionary *cache = [json objectForKey:@"cache" kindOfClass:[NSDictionary class] allowNil:true error:&err];
    if (cache != nil) {
        [self handleCache:cache];
    }
    
    // Parse response
    BAInboxWebserviceResponse *response = [[BAInboxWebserviceResponse alloc] init];

    NSNumber *hasMore = [json objectForKey:@"hasMore" kindOfClass:[NSNumber class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }
    response.hasMore = [hasMore boolValue];

    NSNumber *timeout = [json objectForKey:@"timeout" kindOfClass:[NSNumber class] fallback:@(false)];
    response.didTimeout = [timeout boolValue];

    NSString *cursor = [json objectForKey:@"cursor" kindOfClass:[NSString class] allowNil:true error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }
    if ([BANullHelper isStringEmpty:cursor]) {
        cursor = nil;
    }
    response.cursor = cursor;
    
    NSArray *rawNotifications = [json objectForKey:@"notifications" kindOfClass:[NSArray class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    NSMutableArray<NSString *> *notificationsIds = [NSMutableArray new];
    for (NSDictionary *rawNotif in rawNotifications) {
        if (![rawNotif isKindOfClass:[NSDictionary class]]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"Notification content isn't an object, skipping"];
            continue;
        }
        
        NSString* notificationId = [self parseNotificationId:rawNotif];
        if ([self isCandidate:notificationId]) {
            // The notification is a candidate, it's already in DB, update it
            NSString *notifId = [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] updateNotification:rawNotif withFetcherId:_fetcherId];
            if (notifId) {
                [notificationsIds addObject:notifId];
            }
        } else {
            // The notification isn't a candidate, inserting it
            BAInboxNotificationContent *notif = [BAInboxFetchWebserviceClient parseRawNotification:rawNotif error:&err];
            if (notif && err == nil) {
                if ([[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] insertNotification:notif withFetcherId:_fetcherId]) {
                    [notificationsIds addObject:notificationId];
                }
            }
        }
    }
    
    if ([notificationsIds count] > 0) {
        response.notifications = [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] notifications:notificationsIds withFetcherId:_fetcherId];
    }

    return response;
}

-(void)handleCache:(NSDictionary *)cache
{
    NSNumber *cacheMarkAllAsRead = [cache objectForKey:@"lastMarkAllAsRead"];
    if (![BANullHelper isNumberEmpty:cacheMarkAllAsRead])
    {
        [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] markAllAsRead:([cacheMarkAllAsRead longLongValue] / 1000) withFetcherId:_fetcherId];
    }
    
    NSArray *delete = [cache objectForKey:@"delete"];
    if (![BANullHelper isArrayEmpty:delete])
    {
        NSMutableArray<NSString *> *deleteIds = [NSMutableArray new];
        for (NSString *deleteId in delete) {
            if (![BANullHelper isStringEmpty:delete])
            {
                [deleteIds addObject:deleteId];
            }
        }

        [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] deleteNotifications:deleteIds];
    }
}

@end
