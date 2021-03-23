//
//  BatchInbox.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2017 Batch SDK. All rights reserved.
//

#import <Batch/BatchInbox.h>

#import <Batch/BatchInboxPrivate.h>
#import <Batch/BAInbox.h>
#import <Batch/BATJsonDictionary.h>

#define DEBUG_DOMAIN @"BatchInboxFetcher"

@interface BatchInboxFetcher()

@property (retain) BAInbox *backingImpl;

@end

@implementation BatchInboxFetcher

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"-init is not supported for this class. Use [BatchInbox inboxFetcher] or [BatchInbox inboxFetcherForUserIdentifier:authenticationKey:] to get an instance." userInfo:nil];
}

- (instancetype)initForInstallation
{
    self = [super init];
    if (self) {
        _backingImpl = [[BAInbox alloc] initForInstallation];
    }
    return self;
}

- (instancetype)initForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)key
{
    self = [super init];
    if (self) {
        if (identifier == nil) {
            return nil;
        }
        _backingImpl = [[BAInbox alloc] initForUserIdentifier:identifier authenticationKey:key];
    }
    return self;
}

- (void)fetchNewNotifications:(void (^ _Nullable)(NSError* _Nullable error, NSArray<BatchInboxNotificationContent*>* _Nullable notifications, BOOL foundNewMessages, BOOL endReached))completionHandler
{
    [_backingImpl fetchNewNotifications:completionHandler];
}

- (void)fetchNextPage:(void (^ _Nullable)(NSError* _Nullable error, NSArray<BatchInboxNotificationContent*>* _Nullable notifications, BOOL endReached))completionHandler
{
    [_backingImpl fetchNextPage:completionHandler];
}

- (void)markNotificationAsRead:(nonnull BatchInboxNotificationContent*)notification
{
    [_backingImpl markNotificationAsRead:notification];
}

- (void)markAllNotificationsAsRead
{
    [_backingImpl markAllNotificationsAsRead];
}

- (void)markNotificationAsDeleted:(nonnull BatchInboxNotificationContent*)notification
{
    [_backingImpl markNotificationAsDeleted:notification];
}

- (BOOL)endReached
{
    return [_backingImpl endReached];
}

- (NSArray<NSObject*>*)allFetchedNotifications
{
    return [_backingImpl allFetchedNotifications];
}

- (NSUInteger)limit
{
    return _backingImpl.limit;
}

- (void)setLimit:(NSUInteger)limit
{
    _backingImpl.limit = limit;
}

- (NSUInteger)maxPageSize
{
    return _backingImpl.maxPageSize;
}

- (void)setMaxPageSize:(NSUInteger)maxPageSize
{
    _backingImpl.maxPageSize = maxPageSize;
}

@end

@implementation BatchInboxNotificationContent

- (nullable instancetype)initWithInternalIdentifier:(nonnull NSString *)identifier
                                         rawPayload:(nonnull NSDictionary *)rawPayload
                                           isUnread:(BOOL)isUnread
                                               date:(nonnull NSDate *)date
{
    self = [super init];

    if (self) {
        _identifier = identifier;
        _payload = [rawPayload copy];
        _date = date;
        _isUnread = isUnread;
        _isDeleted = false;

        if ([BANullHelper isStringEmpty:_identifier]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"Empty identifier while instanciating BatchInboxNotificationContent, returning nil"];
            return nil;
        }

        if ([BANullHelper isDictionaryEmpty:_payload]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"Empty identifier while instanciating BatchInboxNotificationContent, returning nil"];
            return nil;
        }

        if (![self parseRawPayload]) {
            return nil;
        }
    }

    return self;
}

- (BOOL)parseRawPayload
{
    if (![_payload isKindOfClass:[NSDictionary class]]) {
        return false;
    }

    _source = [self parseSource];
    _attachmentURL = [self parseAttachment];

    NSDictionary *aps = _payload[@"aps"];
    if ([BANullHelper isDictionaryEmpty:aps]) {
        [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: missing 'aps'"];
        return false;
    }

    NSObject *alert = aps[@"alert"];

    if ([alert isKindOfClass:[NSString class]]) {
        if ([BANullHelper isStringEmpty:alert]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: 'aps:alert' is a string but is empty"];
            return false;
        }
        _body = (NSString*)alert;
        _title = nil;
    } else if ([alert isKindOfClass:[NSDictionary class]]) {
        NSDictionary *alertDict = (NSDictionary*)alert;
        NSObject *body = alertDict[@"body"];
        if ([BANullHelper isStringEmpty:body]) {
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: 'aps:alert:body' is missing or empty"];
            return false;
        }
        _body = (NSString*)body;

        NSObject *title = alertDict[@"title"];
        if (![BANullHelper isStringEmpty:title]) {
            _title = (NSString*)title;
        }
    } else {
        [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: missing 'aps:alert'"];
        return false;
    }

    return true;
}

- (BatchNotificationSource)parseSource
{
    NSDictionary *comBatch = _payload[@"com.batch"];
    if ([BANullHelper isDictionaryEmpty:comBatch]) {
        return BatchNotificationSourceUnknown;
    }

    NSString *type = comBatch[@"t"];
    if ([BANullHelper isStringEmpty:type]) {
        return BatchNotificationSourceUnknown;
    }

    type = [type lowercaseString];
    if ([@"t" isEqualToString:type]) {
        return BatchNotificationSourceTransactional;
    } else if ([@"c" isEqualToString:type]) {
        return BatchNotificationSourceCampaign;
    } else if ([@"tc" isEqualToString:type]) {
        return BatchNotificationSourceTrigger;
    }

    return BatchNotificationSourceUnknown;
}

- (NSURL*)parseAttachment
{
    NSDictionary *comBatch = _payload[@"com.batch"];
    if ([BANullHelper isDictionaryEmpty:comBatch]) {
        return nil;
    }

    NSDictionary *attachment = [comBatch objectForKey:@"at"];
    if (![attachment isKindOfClass:[NSDictionary class]])
    {
        return nil;
    }

    NSString *urlString = [attachment objectForKey:@"u"];

    if (![urlString isKindOfClass:[NSString class]])
    {
        [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent:attachment url is not a string"];
        return nil;
    }

    return [NSURL URLWithString:urlString];
}

- (void)_markAsRead
{
    _isUnread = false;
}

- (void)_markAsDeleted
{
    _isDeleted = true;
}

@end

@implementation BatchInbox

+ (nonnull BatchInboxFetcher*)fetcher
{
    return [[BatchInboxFetcher alloc] initForInstallation];
}

+ (nullable BatchInboxFetcher*)fetcherForUserIdentifier:(nonnull NSString*)identifier authenticationKey:(nonnull NSString*)authKey
{
    return [[BatchInboxFetcher alloc] initForUserIdentifier:identifier authenticationKey:authKey];
}

@end
