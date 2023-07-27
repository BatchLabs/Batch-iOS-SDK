//
//  BatchInboxPrivate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

#import <Batch/BatchInbox.h>

@interface BatchInboxNotificationContentMessage ()

- (nonnull instancetype)initWithBody:(nonnull NSString *)body
                               title:(nullable NSString *)title
                            subtitle:(nullable NSString *)subtitle;

@end

@interface BatchInboxNotificationContent ()

- (nullable instancetype)initWithInternalIdentifier:(nonnull NSString *)identifier
                                         rawPayload:(nonnull NSDictionary *)rawPayload
                                           isUnread:(BOOL)isUnread
                                               date:(nonnull NSDate *)date
                           failOnSilentNotification:(BOOL)failOnSilentNotification;

- (void)_markAsRead;

- (void)_markAsDeleted;

@end
