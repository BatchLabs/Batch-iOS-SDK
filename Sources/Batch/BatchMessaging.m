//
//  BatchMessaging.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BatchMessaging.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BANullHelper.h>
#import <Batch/BAMSGPayloadParser.h>
#import <Batch/BAThreading.h>
#import <Batch/BatchMessagingPrivate.h>

NSString* const kBatchMessagingCloseButtonTrackingIdentifier = @"close";
NSInteger const BatchMessageGlobalActionIndex = -1;

@implementation BatchAlertMessageCTA

- (nullable instancetype)_initWithInternalCTA:(nullable BAMSGCTA*)msgCTA
{
    self = [super init];
    if (self)
    {
        _label = msgCTA.label;
        _action = msgCTA.actionIdentifier;
        _args = [msgCTA.actionArguments copy];
    }
    return self;
}

@end

@implementation BatchAlertMessageContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageAlert*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _title = msg.titleText;
            _body = msg.bodyText;
            _cancelLabel = msg.cancelButtonText;
            if ([msg.acceptCTA isKindOfClass:[BAMSGCTA class]]) {
                _acceptCTA = [[BatchAlertMessageCTA alloc] _initWithInternalCTA:msg.acceptCTA];
            }
        }
    }
    return self;
}

@end

@implementation BatchInterstitialMessageCTA

- (nullable instancetype)_initWithInternalCTA:(nullable BAMSGCTA*)msgCTA
{
    self = [super init];
    if (self)
    {
        _label = msgCTA.label;
        _action = msgCTA.actionIdentifier;
        _args = [msgCTA.actionArguments copy];
    }
    return self;
}

@end

@implementation BatchInterstitialMessageContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageInterstitial*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _header = msg.headingText;
            _title = msg.titleText;
            _body = msg.bodyText;
            _showCloseButton = msg.showCloseButton;
            if (![BANullHelper isStringEmpty:msg.videoURL]) {
                _mediaURL = msg.videoURL;
            } else {
                _mediaURL = msg.heroImageURL;
            }
            _mediaAccessibilityDescription = msg.heroDescription;
            
            NSMutableArray *ctas = [NSMutableArray arrayWithCapacity:[msg.ctas count]];
            for (BAMSGCTA *internalCTA in msg.ctas) {
                if (![internalCTA isKindOfClass:[BAMSGCTA class]]) {
                    continue;
                }
                BatchInterstitialMessageCTA *parsedCTA = [[BatchInterstitialMessageCTA alloc] _initWithInternalCTA:internalCTA];
                if (parsedCTA != nil) {
                    [ctas addObject:parsedCTA];
                }
            }
            _ctas = [ctas copy];
        }
    }
    return self;
}

@end

@implementation BatchMessageAction

- (nullable instancetype)_initWithInternalAction:(nullable BAMSGAction*)action
{
    self = [super init];
    if (self)
    {
        _action = action.actionIdentifier;
        _args = [action.actionArguments copy];
    }
    return self;
}

- (BOOL)isDismissAction
{
    return _action == nil;
}

@end

@implementation BatchMessageCTA

- (nullable instancetype)_initWithInternalAction:(nullable BAMSGCTA*)action
{
    self = [super _initWithInternalAction:action];
    if (self)
    {
        _label = action.label.copy;
    }
    return self;
}

@end

@implementation BatchImageMessageAction
@end

@implementation BatchBannerMessageAction
@end

@implementation BatchBannerMessageCTA

- (nullable instancetype)_initWithInternalCTA:(nullable BAMSGCTA*)msgCTA
{
    self = [super init];
    if (self)
    {
        _label = msgCTA.label;
        _action = msgCTA.actionIdentifier;
        _args = [msgCTA.actionArguments copy];
    }
    return self;
}

@end

@implementation BatchBannerMessageContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageBanner*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _title = msg.titleText;
            _body = msg.bodyText;
            _showCloseButton = msg.showCloseButton;
            _mediaURL = msg.imageURL;
            _mediaAccessibilityDescription = msg.imageDescription;
            
            NSMutableArray *ctas = [NSMutableArray arrayWithCapacity:[msg.ctas count]];
            for (BAMSGCTA *internalCTA in msg.ctas) {
                if (![internalCTA isKindOfClass:[BAMSGCTA class]]) {
                    continue;
                }
                BatchBannerMessageCTA *parsedCTA = [[BatchBannerMessageCTA alloc] _initWithInternalCTA:internalCTA];
                if (parsedCTA != nil) {
                    [ctas addObject:parsedCTA];
                }
            }
            _ctas = [ctas copy];
            
            _globalTapAction = msg.globalTapAction != nil ? [[BatchBannerMessageAction alloc] _initWithInternalAction:msg.globalTapAction]: nil;
            _automaticallyDismissAfter = msg.autoClose;
        }
    }
    return self;
}

@end

@implementation BatchMessageImageContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageImage*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _imageSize = msg.imageSize;
            _imageURL = msg.imageURL;
            _globalTapDelay = msg.globalTapDelay;
            _isFullscreen = msg.isFullscreen;
            _imageDescription = msg.imageDescription;
            _autoClose = msg.autoClose;
            _allowSwipeToDismiss = msg.allowSwipeToDismiss;
            _globalTapAction = [[BatchImageMessageAction alloc] _initWithInternalAction:msg.globalTapAction];
        }
    }
    return self;
}

@end

@implementation BatchMessageModalContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageModal*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _title = msg.titleText;
            _body = msg.bodyText;
            _showCloseButton = msg.showCloseButton;
            _mediaURL = msg.imageURL;
            _mediaAccessibilityDescription = msg.imageDescription;
            
            NSMutableArray *ctas = [NSMutableArray arrayWithCapacity:[msg.ctas count]];
            for (BAMSGCTA *internalCTA in msg.ctas) {
                if (![internalCTA isKindOfClass:[BAMSGCTA class]]) {
                    continue;
                }
                BatchBannerMessageCTA *parsedCTA = [[BatchBannerMessageCTA alloc] _initWithInternalCTA:internalCTA];
                if (parsedCTA != nil) {
                    [ctas addObject:parsedCTA];
                }
            }
            _ctas = [ctas copy];
            
            _globalTapAction = msg.globalTapAction != nil ? [[BatchBannerMessageAction alloc] _initWithInternalAction:msg.globalTapAction]: nil;
            _automaticallyDismissAfter = msg.autoClose;
        }
    }
    return self;
}

@end

@implementation BatchMessageWebViewContent

- (nullable instancetype)_initWithInternalMessage:(nullable BAMSGMessageWebView*)msg
{
    self = [super init];
    if (self)
    {
        if (msg != nil) {
            _URL = msg.url;
        }
    }
    return self;
}

@end

@implementation BatchMessage : NSObject

+ (nullable instancetype)messageForPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    return [[BatchMessage alloc] initWithPayload:payload];
}

- (nullable instancetype)initWithPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    if (![payload isKindOfClass:[NSDictionary class]])
    {
        [BALogger errorForDomain:@"BatchMessage" message:@"payload isn't a NSDictionary"];
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _messagePayload = payload;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BatchMessage *copy = [[[self class] allocWithZone:zone] init];
    
    if (copy) {
        copy->_messagePayload = [self.messagePayload copyWithZone:zone];
    }
    
    return copy;
}

@end

@implementation BatchInAppMessage
{
    
    NSObject *_lock;
    
    id<BatchInAppMessageContent> _content;
}

+ (nullable instancetype)messageForPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    return [[BatchInAppMessage alloc] initForPayload:payload];
}

- (nullable instancetype)initForPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    self = [super initWithPayload:payload];
    if (self)
    {
        _lock = [NSObject new];
        NSObject *identifier = payload[@"id"];
        if (![identifier isKindOfClass:[NSString class]])
        {
            [BALogger errorForDomain:@"BatchInAppMessage" message:@"'id' is not a NSString but is mandatory"];
            return nil;
        }
        
        NSObject *devIdentifier = payload[@"did"];
        if ((id)devIdentifier == [NSNull null])
        {
            devIdentifier = nil;
        }
        if (devIdentifier != nil && ![devIdentifier isKindOfClass:[NSString class]])
        {
            [BALogger errorForDomain:@"BatchInAppMessage" message:@"'did' is not nil but is not a NSString"];
            return nil;
        }
        
        self.messageIdentifier = (NSString*)identifier;
        self.devTrackingIdentifier = (NSString*)devIdentifier;
        _content = nil;
    }
    return self;
}

- (void)setCampaign:(nonnull BALocalCampaign*)campaign
{
    if (![campaign isKindOfClass:[BALocalCampaign class]])
    {
        [BALogger errorForDomain:@"BatchMessage" message:@"campaign isn't a BALocalCampaign"];
        return;
    }
    
    _customPayload = campaign.customPayload;
    if (campaign.devTrackingIdentifier != nil) {
        self.devTrackingIdentifier = campaign.devTrackingIdentifier;
    }
    self.eventData = campaign.eventData;
    self.campaignIdentifier = campaign.campaignID;
    self.campaignToken = campaign.publicToken;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BatchInAppMessage *copy = [super copyWithZone:zone];
    
    if (copy) {
        copy->_lock = [NSObject new];
        copy->_customPayload = [_customPayload copyWithZone:zone];
        copy.devTrackingIdentifier = self.devTrackingIdentifier;
        copy.messageIdentifier = self.messageIdentifier;
        copy.eventData = [self.eventData copy];
        copy.campaignIdentifier = self.campaignIdentifier;
        copy.campaignToken = self.campaignToken;
    }
    
    return copy;
}

- (id<BatchInAppMessageContent>)content
{
    @synchronized(_lock) {
        if (_content == nil) {
            BAMSGMessage *msg = [BAMSGPayloadParser messageForRawMessage:self bailIfNotAlert:false];
            if ([msg isKindOfClass:[BAMSGMessageAlert class]]) {
                _content = [[BatchAlertMessageContent alloc] _initWithInternalMessage:(BAMSGMessageAlert*)msg];
                ((BatchAlertMessageContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
                
            } else if ([msg isKindOfClass:[BAMSGMessageInterstitial class]]) {
                _content = [[BatchInterstitialMessageContent alloc] _initWithInternalMessage:(BAMSGMessageInterstitial*)msg];
                ((BatchInterstitialMessageContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
                
            } else if ([msg isKindOfClass:[BAMSGMessageBanner class]]) {
                _content = [[BatchBannerMessageContent alloc] _initWithInternalMessage:(BAMSGMessageBanner*)msg];
                ((BatchBannerMessageContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
            } else if ([msg isKindOfClass:[BAMSGMessageImage class]]) {
                _content = [[BatchMessageImageContent alloc] _initWithInternalMessage:(BAMSGMessageImage*)msg];
                ((BatchMessageImageContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
            } else if ([msg isKindOfClass:[BAMSGMessageModal class]]) {
                _content = [[BatchMessageModalContent alloc] _initWithInternalMessage:(BAMSGMessageModal*)msg];
                ((BatchMessageModalContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
            } else if ([msg isKindOfClass:[BAMSGMessageWebView class]]) {
                _content = [[BatchMessageWebViewContent alloc] _initWithInternalMessage:(BAMSGMessageWebView*)msg];
                ((BatchMessageWebViewContent*)_content).trackingIdentifier = self.devTrackingIdentifier;
            }
        }
        return _content;
    }
}

- (BatchMessagingContentType)contentType
{
    id content = self.content;

    if ([content isKindOfClass: BatchAlertMessageContent.class]) {
        return BatchMessagingContentTypeAlert;
    } else if ([content isKindOfClass: BatchInterstitialMessageContent.class]) {
        return BatchMessagingContentTypeInterstitial;
    } else if ([content isKindOfClass: BatchBannerMessageContent.class]) {
        return BatchMessagingContentTypeBanner;
    } else if ([content isKindOfClass: BatchMessageImageContent.class]) {
        return BatchMessagingContentTypeImage;
    } else if ([content isKindOfClass: BatchMessageModalContent.class]) {
        return BatchMessagingContentTypeModal;
    } else if ([content isKindOfClass: BatchMessageWebViewContent.class]) {
        return BatchMessagingContentTypeWebView;
    }

    return BatchMessagingContentTypeUnknown;
}

@end

@implementation BatchPushMessage : BatchMessage

+ (nullable instancetype)messageForPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    return [[BatchPushMessage alloc] initWithPayload:payload];
}

- (nullable instancetype)initWithPayload:(nonnull NSDictionary<NSString*, NSObject*>*)payload
{
    if (![payload isKindOfClass:[NSDictionary class]])
    {
        [BALogger errorForDomain:@"BatchMessage" message:@"payload isn't a NSDictionary"];
        return nil;
    }

    NSObject* batchPayload = [payload objectForKey:@"com.batch"];
    if (![batchPayload isKindOfClass:[NSDictionary class]])
    {
        [BALogger errorForDomain:@"BatchMessage" message:@"batch internal payload not found or isn't a NSDictionary"];
        return nil;
    }

    NSObject* message = [(NSDictionary*)batchPayload objectForKey:@"ld"];
    if (![message isKindOfClass:[NSDictionary class]])
    {
        [BALogger errorForDomain:@"BatchMessage" message:@"message not found or isn't a NSDictionary"];
        return nil;
    }

    NSDictionary *castedMessage = (NSDictionary*)message;

    self = [super initWithPayload:castedMessage];
    if (self)
    {
        _pushPayload = payload;

        // Read the extra non-ui related keys in the landing payload for compatibility
        NSString *identifier = castedMessage[@"id"];
        if (![identifier isKindOfClass:[NSString class]])
        {
            [self printGenericDebugLog:@"'id' is not a NSString but is mandatory"];
            return nil;
        }

        NSString *devIdentifier = castedMessage[@"did"];
        if ((id)devIdentifier == [NSNull null])
        {
            devIdentifier = nil;
        }
        if (devIdentifier != nil && ![devIdentifier isKindOfClass:[NSString class]])
        {
            [self printGenericDebugLog:@"'did' is not nil but is not a NSString"];
            return nil;
        }

        NSDictionary *eventData = castedMessage[@"ed"];
        if (eventData != nil && ![eventData isKindOfClass:[NSDictionary class]])
        {
            [self printGenericDebugLog:@"'ed' is not nil but isn't a NSDictionary. Ignoring."];
            // Don't return!
        }

        self.messageIdentifier = identifier;
        self.devTrackingIdentifier = devIdentifier;
        self.eventData = eventData;
    }
    return self;
}

- (void)printGenericDebugLog:(NSString*)msg
{
    [BALogger debugForDomain:@"BatchPushMessage" message:@"Error while decoding payload: %@", msg];
}

@end

@implementation BatchMessaging

+ (void)setDelegate:(id<BatchMessagingDelegate> _Nullable)delegate
{
    [[BAMessagingCenter instance] setDelegate:delegate];
}

+ (void)setCanReconfigureAVAudioSession:(BOOL)canReconfigureAVAudioSession
{
    [[BAMessagingCenter instance] setCanReconfigureAVAudioSession:canReconfigureAVAudioSession];
}

+ (void)setAutomaticMode:(BOOL)automatic
{
    [[BAMessagingCenter instance] setAutomaticMode:automatic];
}

+ (BOOL)doNotDisturb
{
    return [BAMessagingCenter instance].doNotDisturb;
}

+ (void)setDoNotDisturb:(BOOL)dnd
{
    [BAMessagingCenter instance].doNotDisturb = dnd;
}

+ (BOOL)hasPendingMessage
{
    return [[BAMessagingCenter instance] hasPendingMessage];
}

+ (BatchMessage* _Nullable)popPendingMessage
{
    return [[BAMessagingCenter instance] popPendingMessage];
}

+ (BOOL)showPendingMessage
{
    return [[BAMessagingCenter instance] showPendingMessage];
}

+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont
{
    [[BAMessagingCenter instance] setFontOverride:font boldFont:boldFont];
}

+ (void)setFontOverride:(nullable UIFont*)font boldFont:(nullable UIFont*)boldFont italicFont:(nullable UIFont*)italicFont boldItalicFont:(nullable UIFont*)boldItalicFont
{
    [[BAMessagingCenter instance] setFontOverride:font boldFont:boldFont italicFont:italicFont boldItalicFont:boldItalicFont];
}

+ (nullable BatchPushMessage*)messageFromPushPayload:(nonnull NSDictionary*)userData
{
    return [BatchPushMessage messageForPayload:userData];
}

+ (UIViewController* _Nullable)loadViewControllerForMessage:(BatchMessage* _Nonnull)message
                                                      error:(NSError * _Nullable * _Nullable)error
{
    return [[BAMessagingCenter instance] loadViewControllerForMessage:message error:error];
}

+ (void)presentMessagingViewController:(nonnull UIViewController*)vc
{
    [BAThreading performBlockOnMainThreadAsync:^{
        [[BAMessagingCenter instance] presentMessagingViewController:vc error:nil];
    }];
}

@end
