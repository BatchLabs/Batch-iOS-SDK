//
//  BatchInbox.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2017 Batch SDK. All rights reserved.
//

#import <Batch/BatchInbox.h>

#import <Batch/BAInbox.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BatchInboxPrivate.h>
#import <Batch/BatchMessagingPrivate.h>

#define DEBUG_DOMAIN @"BatchInboxFetcher"
#define LOGGER_DOMAIN @"BatchInboxNotificationContent"

@interface BatchInboxFetcher ()

@property (retain) BAInbox *backingImpl;

@end

@implementation BatchInboxFetcher

- (instancetype)init {
    @throw [NSException
        exceptionWithName:NSInternalInconsistencyException
                   reason:@"-init is not supported for this class. Use [BatchInbox inboxFetcher] or [BatchInbox "
                          @"inboxFetcherForUserIdentifier:authenticationKey:] to get an instance."
                 userInfo:nil];
}

- (instancetype)initForInstallation {
    self = [super init];
    if (self) {
        _backingImpl = [[BAInbox alloc] initForInstallation];
    }
    return self;
}

- (instancetype)initForUserIdentifier:(nonnull NSString *)identifier authenticationKey:(nonnull NSString *)key {
    self = [super init];
    if (self) {
        if (identifier == nil) {
            return nil;
        }
        _backingImpl = [[BAInbox alloc] initForUserIdentifier:identifier authenticationKey:key];
    }
    return self;
}

- (void)fetchNewNotifications:(void (^_Nullable)(NSError *_Nullable error,
                                                 NSArray<BatchInboxNotificationContent *> *_Nullable notifications,
                                                 BOOL foundNewMessages,
                                                 BOOL endReached))completionHandler {
    [_backingImpl fetchNewNotifications:completionHandler];
}

- (void)fetchNextPage:(void (^_Nullable)(NSError *_Nullable error,
                                         NSArray<BatchInboxNotificationContent *> *_Nullable notifications,
                                         BOOL endReached))completionHandler {
    [_backingImpl fetchNextPage:completionHandler];
}

- (void)markNotificationAsRead:(nonnull BatchInboxNotificationContent *)notification {
    [_backingImpl markNotificationAsRead:notification];
}

- (void)markAllNotificationsAsRead {
    [_backingImpl markAllNotificationsAsRead];
}

- (void)markNotificationAsDeleted:(nonnull BatchInboxNotificationContent *)notification {
    [_backingImpl markNotificationAsDeleted:notification];
}

- (BOOL)filterSilentNotifications {
    return _backingImpl.filterSilentNotifications;
}

- (void)setFilterSilentNotifications:(BOOL)filterSilentNotifications {
    _backingImpl.filterSilentNotifications = filterSilentNotifications;
}

- (BOOL)endReached {
    return [_backingImpl endReached];
}

- (NSArray<NSObject *> *)allFetchedNotifications {
    return [_backingImpl allFetchedNotifications];
}

- (NSUInteger)limit {
    return _backingImpl.limit;
}

- (void)setLimit:(NSUInteger)limit {
    _backingImpl.limit = limit;
}

- (NSUInteger)maxPageSize {
    return _backingImpl.maxPageSize;
}

- (void)setMaxPageSize:(NSUInteger)maxPageSize {
    _backingImpl.maxPageSize = maxPageSize;
}

@end

@implementation BatchInboxNotificationContentMessage

- (nonnull instancetype)initWithBody:(nonnull NSString *)body
                               title:(nullable NSString *)title
                            subtitle:(nullable NSString *)subtitle {
    self = [super init];

    if (self) {
        _body = body;
        _title = title;
        _subtitle = subtitle;
    }

    return self;
}

@end

@implementation BatchInboxNotificationContent {
    BOOL _failOnSilentNotification;
}

- (nullable instancetype)initWithInternalIdentifier:(nonnull NSString *)identifier
                                         rawPayload:(nonnull NSDictionary *)rawPayload
                                           isUnread:(BOOL)isUnread
                                               date:(nonnull NSDate *)date
                           failOnSilentNotification:(BOOL)failOnSilentNotification {
    self = [super init];

    if (self) {
        _identifier = identifier;
        _payload = [rawPayload copy];
        _date = date;
        _isUnread = isUnread;
        _failOnSilentNotification = failOnSilentNotification;

        if ([BANullHelper isStringEmpty:_identifier]) {
            [BALogger
                errorForDomain:DEBUG_DOMAIN
                       message:@"Empty identifier while instanciating BatchInboxNotificationContent, returning nil"];
            return nil;
        }

        if ([BANullHelper isDictionaryEmpty:_payload]) {
            [BALogger
                errorForDomain:DEBUG_DOMAIN
                       message:@"Empty identifier while instanciating BatchInboxNotificationContent, returning nil"];
            return nil;
        }

        if (![self parseRawPayload]) {
            return nil;
        }
    }

    return self;
}

- (BOOL)isSilent {
    return _message == nil;
}

- (BOOL)parseRawPayload {
    if (![_payload isKindOfClass:[NSDictionary class]]) {
        return false;
    }

    _source = [self parseSource];
    _attachmentURL = [self parseAttachment];

    _message = [self parseMessage];

    if (_message == nil && _failOnSilentNotification) {
        [BALogger errorForDomain:DEBUG_DOMAIN
                         message:@"BatchInboxNotificationContent: No message found, filtering of silent notifications "
                                 @"is enabled: skipping."];
        return false;
    }

    return true;
}

- (nullable BatchInboxNotificationContentMessage *)parseMessage {
    NSString *msgBody = nil;
    NSString *msgTitle = nil;
    NSString *msgSubtitle = nil;

    NSDictionary *aps = _payload[@"aps"];
    if ([BANullHelper isDictionaryEmpty:aps]) {
        if (_failOnSilentNotification) {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: missing 'aps'"];
        }
        return nil;
    }

    NSObject *alert = aps[@"alert"];

    if ([alert isKindOfClass:[NSString class]]) {
        if ([BANullHelper isStringEmpty:alert]) {
            if (_failOnSilentNotification) {
                [BALogger debugForDomain:DEBUG_DOMAIN
                                 message:@"BatchInboxNotificationContent: 'aps:alert' is a string but is empty"];
            }
            return nil;
        }

        msgBody = (NSString *)alert;
    } else if ([alert isKindOfClass:[NSDictionary class]]) {
        NSDictionary *alertDict = (NSDictionary *)alert;
        NSObject *body = alertDict[@"body"];
        if ([BANullHelper isStringEmpty:body]) {
            if (_failOnSilentNotification) {
                [BALogger debugForDomain:DEBUG_DOMAIN
                                 message:@"BatchInboxNotificationContent: 'aps:alert:body' is missing or empty"];
            }
            return nil;
        }

        msgBody = (NSString *)body;

        NSObject *title = alertDict[@"title"];
        if (![BANullHelper isStringEmpty:title]) {
            msgTitle = (NSString *)title;
        }

        NSObject *subtitle = alertDict[@"subtitle"];
        if (![BANullHelper isStringEmpty:subtitle]) {
            msgSubtitle = (NSString *)subtitle;
        }
    } else {
        if (_failOnSilentNotification) {
            [BALogger debugForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent: missing 'aps:alert'"];
        }
        return nil;
    }

    return [[BatchInboxNotificationContentMessage alloc] initWithBody:msgBody title:msgTitle subtitle:msgSubtitle];
}

- (BatchNotificationSource)parseSource {
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

- (NSURL *)parseAttachment {
    NSDictionary *comBatch = _payload[@"com.batch"];
    if ([BANullHelper isDictionaryEmpty:comBatch]) {
        return nil;
    }

    NSDictionary *attachment = [comBatch objectForKey:@"at"];
    if (![attachment isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    NSString *urlString = [attachment objectForKey:@"u"];

    if (![urlString isKindOfClass:[NSString class]]) {
        [BALogger errorForDomain:DEBUG_DOMAIN message:@"BatchInboxNotificationContent:attachment url is not a string"];
        return nil;
    }

    return [NSURL URLWithString:urlString];
}

- (void)_markAsRead {
    _isUnread = false;
}

- (BOOL)hasLandingMessage {
    return [BatchMessaging messageFromPushPayload:_payload] != nil;
}

- (void)displayLandingMessage {
    BatchPushMessage *message = [BatchMessaging messageFromPushPayload:_payload];
    [message setIsDisplayedFromInbox:true];
    if (message) {
        [[BAMessagingCenter instance] presentLandingMessage:message bypassDnD:true];
    } else {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"No landing message is attached."];
    }
}

@end

@implementation BatchInbox

+ (nonnull BatchInboxFetcher *)fetcher {
    return [[BatchInboxFetcher alloc] initForInstallation];
}

+ (nullable BatchInboxFetcher *)fetcherForUserIdentifier:(nonnull NSString *)identifier
                                       authenticationKey:(nonnull NSString *)authKey {
    return [[BatchInboxFetcher alloc] initForUserIdentifier:identifier authenticationKey:authKey];
}

@end
