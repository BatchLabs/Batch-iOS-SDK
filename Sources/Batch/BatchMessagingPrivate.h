//
//  BatchMessagingPrivate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

#import <Batch/BALocalCampaign.h>
#import <Batch/BAMSGCTA.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BatchMessagingModels.h>

@interface BatchAlertMessageCTA ()

- (nullable instancetype)_initWithInternalCTA:(nullable BAMSGCTA *)msgCTA;

@end

@interface BatchAlertMessageContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageAlert *)msg;

@end

@interface BatchInterstitialMessageCTA ()

- (nullable instancetype)_initWithInternalCTA:(nullable BAMSGCTA *)msgCTA;

@end

@interface BatchInterstitialMessageContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageInterstitial *)msg;

@end

@interface BatchBannerMessageContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

@end

@interface BatchMessageImageContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageImage *)msg;

@end

@interface BatchMessageModalContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageModal *)msg;

@end

@interface BatchMessageWebViewContent ()

@property (nullable, readwrite) NSString *trackingIdentifier;

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageWebView *)msg;

@end

@interface BatchMessage ()

+ (nullable instancetype)messageForPayload:(nonnull NSDictionary<NSString *, NSObject *> *)payload
                              isCEPMessage:(BOOL)isCEPMessage;

@property (nonnull, readonly) NSDictionary<NSString *, NSObject *> *messagePayload;

@property (nonnull) NSString *messageIdentifier;
@property (nullable) NSString *devTrackingIdentifier;
@property (nullable) NSObject *eventData;
/// Determine if the message is a MEP or a CEP one
@property BOOL isCEPMessage;

@end

@interface BatchInAppMessage () <NSCopying>

+ (nullable instancetype)messageForPayload:(nonnull NSDictionary<NSString *, NSObject *> *)payload
                              isCEPMessage:(BOOL)isCEPMessage;

- (void)setCampaign:(nonnull BALocalCampaign *)campaign;

@property (nullable) NSString *campaignIdentifier;

@property (nullable) NSString *campaignToken;

@end

@interface BatchPushMessage ()

- (void)setIsDisplayedFromInbox:(BOOL)isDisplayedFromInbox;

@end

@interface BatchMessageAction ()

- (nullable instancetype)_initWithInternalAction:(nullable BAMSGAction *)action;

@end

@interface BatchMessageCTA ()

- (nullable instancetype)_initWithInternalAction:(nullable BAMSGCTA *)action;

@end
