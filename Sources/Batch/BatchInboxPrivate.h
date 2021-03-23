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

@interface BatchInboxNotificationContent()

- (nullable instancetype)initWithInternalIdentifier:(nonnull NSString *)identifier
                                         rawPayload:(nonnull NSDictionary *)rawPayload
                                           isUnread:(BOOL)isUnread
                                               date:(nonnull NSDate *)date;

- (void)_markAsRead;

- (void)_markAsDeleted;

@end
