//
//  BAPushEventPayload.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BatchEventDispatcher.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/BatchMessagingModels.h>

@interface BAPushEventPayload : NSObject <BatchEventDispatcherPayload>

@property (readonly, nullable) NSString *trackingId;
@property (readonly, nullable) NSString *deeplink;
@property (readonly) BOOL isPositiveAction;
@property (readonly, nullable) BatchMessage *sourceMessage;
@property (readonly, nullable) NSDictionary *notificationUserInfo;
@property (readonly, nullable) NSString *webViewAnalyticsIdentifier;

- (nonnull instancetype)initWithUserInfo:(nonnull NSDictionary*)userInfo;

@end
