//
//  BAInboxWebserviceResponse.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@class BAInboxNotificationContent;

@interface BAInboxWebserviceResponse : NSObject

@property(nonatomic, assign) BOOL hasMore;
@property(nonatomic, assign) BOOL didTimeout;
@property(nonatomic, nullable) NSString *cursor;
@property(nonatomic, nonnull) NSArray<BAInboxNotificationContent*> *notifications;

@end
