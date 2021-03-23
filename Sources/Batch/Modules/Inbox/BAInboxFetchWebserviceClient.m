//
//  BAInboxWebserviceClient.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BAInboxFetchWebserviceClient.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAJson.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAInbox.h>
#import <Batch/BAInboxDatasourceProtocol.h>
#import <Batch/BAInjection.h>
#import <Batch/BAPushPayload.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BACSS.h>
#import <Batch/BAWebserviceURLBuilder.h>

#define DEBUG_DOMAIN @"InboxFetchWebserviceClient"

#define LOCAL_ERROR_DOMAIN @"com.batch.inbox.fetch.wsclient"

static const NSString *kBatchWebserviceIdentifierInboxFetch = @"inbox_fetch";

@implementation BAInboxFetchWebserviceClient {
    NSString *_authKey;
    NSUInteger _limit;
    long long _fetcherId;
    NSString *_fromToken;
    void (^_successHandler)(BAInboxWebserviceResponse* _Nonnull response);
    void (^_errorHandler)(NSError* _Nonnull error);
}

- (nullable instancetype)initWithIdentifier:(nonnull NSString*)identifier
                                       type:(BAInboxWebserviceClientType)type
                          authenticationKey:(nullable NSString*)authKey
                                      limit:(NSUInteger)limit
                                  fetcherId:(long long)fetcherId
                                  fromToken:(nullable NSString*)from
                                    success:(void (^ _Nullable)(BAInboxWebserviceResponse* _Nonnull response))successHandler
                                      error:(void (^ _Nullable)(NSError* _Nonnull error))errorHandler
{
    NSURL *url = [self generateURLWithIdentifier:identifier
                                            type:type];
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
    self = [super initWithURL:url
                   identifier:(NSString *)kBatchWebserviceIdentifierInboxFetch
                     delegate:self];
    if (self) {
        _authKey = authKey;
        _limit = limit;
        _fetcherId = fetcherId;
        _fromToken = from;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
    }
    return self;
}

- (nullable NSURL*)generateURLWithIdentifier:(nonnull NSString*)identifier
                                        type:(BAInboxWebserviceClientType)type
{
    NSURL *url = [BAWebserviceURLBuilder webserviceURLForShortname:@"inbox"];
    
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

- (void)connectionDidFinishLoadingWithData:(NSData *)data
{
    [super connectionDidFinishLoadingWithData:data];
    [BALogger debugForDomain:DEBUG_DOMAIN
                     message:@"Inbox - Success"];
    NSError *err = nil;
    BAInboxWebserviceResponse *response = [self parseResponse:data error:&err];
    if (err == nil && response == nil) {
        err = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                  code:-10
                              userInfo:@{NSLocalizedDescriptionKey: @"An unknown error occurred while decoding the response."}];
    }
    
    if (_fetcherId != -1) {
        // Store response into cache
        [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] insertResponse:response withFetcherId:_fetcherId];
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
                     message:@"Inbox - Failure - %@", [error localizedDescription]];
    if (error != nil && _errorHandler != nil) {
        _errorHandler(error);
    }
}

- (BAInboxWebserviceResponse *)parseResponse:(NSData*)data error:(NSError**)outErr
{
    NSDictionary *raw = [BAJson deserializeDataAsDictionary:data error:outErr];

    if (!raw) {
        return nil;
    }

    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:raw errorDomain:@"InboxWebserviceClient"];

    NSError *err = nil;

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

    NSMutableArray *notifications = [NSMutableArray new];

    for (NSDictionary *rawNotif in rawNotifications) {
        if (![rawNotif isKindOfClass:[NSDictionary class]]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"Notification content isn't an object, skipping"];
            continue;
        }

        NSError *notifErr = nil;
        BAInboxNotificationContent *parsed = [BAInboxFetchWebserviceClient parseRawNotification:rawNotif error:&notifErr];
        if (parsed == nil) {
            if (notifErr != nil) {
                [BALogger errorForDomain:DEBUG_DOMAIN message:@"Error while parsing notification content, skipping: %@", notifErr.localizedDescription];
            }
            continue;
        }
        [notifications addObject:parsed];
    }

    response.notifications = notifications;

    return response;
}

+ (BAInboxNotificationContent *)parseRawNotification:(NSDictionary*)dictionary error:(NSError**)outErr
{
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        if (outErr) {
            *outErr = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                          code:-200
                                      userInfo:@{NSLocalizedDescriptionKey: @"Raw notification is nil or isn't an NSDictionary"}];
        }
        return nil;
    }

    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:dictionary errorDomain:@"InboxWebserviceClient"];

    NSError *err = nil;

    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    content.identifiers = [BAInboxNotificationContentIdentifiers new];

    content.identifiers.identifier = [json objectForKey:@"notificationId" kindOfClass:[NSString class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    NSNumber *time = [json objectForKey:@"notificationTime" kindOfClass:[NSNumber class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }
    content.date = [NSDate dateWithTimeIntervalSince1970:([time longLongValue]/1000)];

    content.payload = [json objectForKey:@"payload" kindOfClass:[NSDictionary class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    content.identifiers.sendID = [json objectForKey:@"sendId" kindOfClass:[NSString class] allowNil:false error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    content.identifiers.installID = [json objectForKey:@"installId" kindOfClass:[NSString class] allowNil:true error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    content.identifiers.customID = [json objectForKey:@"customId" kindOfClass:[NSString class] allowNil:true error:&err];
    if (err != nil) {
        return [json writeErrorAndReturnNil:err toErrorPointer:outErr];
    }

    content.identifiers.additionalData = [[[BAPushPayload alloc] initWithUserInfo:content.payload] openEventData];

    NSNumber *read = [json objectForKey:@"read" kindOfClass:[NSNumber class] fallback:@(false)];
    
    NSNumber *opened = [json objectForKey:@"opened" kindOfClass:[NSNumber class] fallback:@(false)];
    
    content.isUnread = ![read boolValue] && ![opened boolValue];

    if ([BANullHelper isStringEmpty:content.identifiers.sendID]) {
        if (outErr) {
            *outErr = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                          code:-201
                                      userInfo:@{NSLocalizedDescriptionKey: @"Empty or missing send ID"}];
        }
        return nil;
    }

    if ([BANullHelper isStringEmpty:content.identifiers.identifier]) {
        if (outErr) {
            *outErr = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                          code:-202
                                      userInfo:@{NSLocalizedDescriptionKey: @"Empty or missing identifier"}];
        }
        return nil;
    }

    if ([BANullHelper isDictionaryEmpty:content.payload]) {
        if (outErr) {
            *outErr = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                          code:-203
                                      userInfo:@{NSLocalizedDescriptionKey: @"Empty or missing payload"}];
        }
        return nil;
    }

    return content;
}

@end
