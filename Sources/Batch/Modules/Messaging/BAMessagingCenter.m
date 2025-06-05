//
//  BAMessagingCenter.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMessagingCenter.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BADelegatedUIAlertController.h>
#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAMSGAction.h>
#import <Batch/BAMSGBannerViewController.h>
#import <Batch/BAMSGButton.h>
#import <Batch/BAMSGImageViewController.h>
#import <Batch/BAMSGInterstitialViewController.h>
#import <Batch/BAMSGLabel.h>
#import <Batch/BAMSGPayloadParser.h>
#import <Batch/BAMSGWebviewViewController.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAPushCenter.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchPush.h>

#import <Batch/BAMSGImageDownloader.h>

#import <Batch/BAActionsCenter.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAOSHelper.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BatchMessagingPrivate.h>

#import <Batch/BACSSBuiltinImportProvider.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BatchMessagingModels.h>

#import <Batch/BAWindowHelper.h>

#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>

#define LOGGER_DOMAIN @"Messaging"

#define BAMESSAGING_DEFAULT_TIMEOUT 30

#define BAMESSAGING_EVENT_NAME @"_MESSAGING"

#define BAMESSAGING_EVENT_TYPE_SHOW @"show"

#define BAMESSAGING_EVENT_TYPE_DISMISS @"dismiss"

#define BAMESSAGING_EVENT_TYPE_CLOSE @"close"

#define BAMESSAGING_EVENT_TYPE_CLOSE_ERROR @"close_error"

#define BAMESSAGING_EVENT_TYPE_AUTO_CLOSE @"auto_close"

#define BAMESSAGING_EVENT_TYPE_GLOBAL_TAP @"global_tap_action"

#define BAMESSAGING_EVENT_TYPE_LOADING_IMAGE_ERROR @"loading_image_error"

#define BAMESSAGING_EVENT_TYPE_CTA @"cta_action"

#define BAMESSAGING_EVENT_TYPE_WEBVIEW_CLICK @"webview_click"

#define BAMESSAGING_BANNER_ANIMATION_DURATION 0.3 // seconds

// Kind of needlessly long key, but this is to make sure we don't collide with anything
static char kBABatchMessagingMessageModelObject;

NSString *const kBATMessagingMessageDidAppear = @"batch.messaging.messageDidAppear";
NSString *const kBATMessagingMessageDidDisappear = @"batch.messaging.messageDidDisappear";

@interface BAMessagingCenter () {
    BABatchMessagingDelegateWrapper *_wrappedDelegate;
    BABatchInAppDelegateWrapper *_wrappedInAppDelegate;
    BatchMessage *_pendingMessage;
}
@end

@implementation BAMessagingCenter

@synthesize enableDynamicType = _enableDynamicType;

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:[BAMessagingCenter class]
                                             selector:@selector(pushOpenedNotification:)
                                                 name:BatchPushOpenedNotification
                                               object:nil];
}

+ (instancetype)instance {
    static BAMessagingCenter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAMessagingCenter alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _wrappedDelegate = [[BABatchMessagingDelegateWrapper alloc] initWithDelgate:nil];
        _wrappedInAppDelegate = [[BABatchInAppDelegateWrapper alloc] initWithDelgate:nil];
        _canReconfigureAVAudioSession = YES;
        _automaticMode = YES;
        _imageDownloadTimeout = BAMESSAGING_DEFAULT_TIMEOUT;
        _pendingMessage = nil;
        self.doNotDisturb = NO;
        _enableDynamicType = YES;
    }
    return self;
}

#pragma mark -
#pragma mark Private static methods

+ (void)pushOpenedNotification:(NSNotification *)notification {
    if (notification.userInfo != nil) {
        id payload = notification.userInfo[BatchPushOpenedNotificationPayloadKey];
        if (![payload isKindOfClass:NSDictionary.class]) {
            [BALogger publicForDomain:LOGGER_DOMAIN message:@"Cannot display landing/deeplink: internal error"];
            return;
        }
        BatchPushMessage *message = [BatchMessaging messageFromPushPayload:payload];

        if (message) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Push contains a mobile landing"];
            if ([BAMessagingCenter instance].automaticMode) {
                [BAThreading performBlockOnMainThreadAsync:^{
                  [BALogger debugForDomain:LOGGER_DOMAIN message:@"automatic mode is enabled: trying to display it"];
                  [[BAMessagingCenter instance] displayMessage:message bypassDnD:false error:nil];
                }];
            } else {
                [BALogger debugForDomain:LOGGER_DOMAIN message:@"but BatchMessaging is in manual mode: ignoring."];
            }
        } else {
            // BAPushCenter used to handle this, but it makes more sense to handle deeplinks in messaging.
            // We need to cann pushcenter because the public api to disable this is on BatchPush
            if ([[BAPushCenter instance] handleDeeplinks]) {
                // Look for an URL.
                BAPushPayload *pushPayload = [[BAPushPayload alloc] initWithUserInfo:payload];
                NSString *deeplink = pushPayload.rawDeeplink;
                if (deeplink != nil) {
                    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Push contains a deeplink"];
                    [[BACoreCenter instance] openDeeplink:deeplink inApp:pushPayload.openDeeplinksInApp];
                }
            }
        }
    }
}

#pragma mark Public instance methods

- (void)setDelegate:(id<BatchMessagingDelegate> _Nullable)delegate {
    _wrappedDelegate = [[BABatchMessagingDelegateWrapper alloc] initWithDelgate:delegate];
}

- (void)setInAppDelegate:(id<BatchInAppDelegate> _Nullable)inAppDelegate {
    _wrappedInAppDelegate = [[BABatchInAppDelegateWrapper alloc] initWithDelgate:inAppDelegate];
}

- (id<BatchMessagingDelegate> _Nullable)delegate {
    return _wrappedDelegate.delegate;
}

- (id<BatchInAppDelegate> _Nullable)inAppDelegate {
    return _wrappedInAppDelegate.delegate;
}

- (void)setImageDownloadTimeout:(NSTimeInterval)timeout {
    _imageDownloadTimeout = timeout;
}

- (void)setCanReconfigureAVAudioSession:(BOOL)canReconfigureAVAudioSession {
    _canReconfigureAVAudioSession = canReconfigureAVAudioSession;
}

- (void)setAutomaticMode:(BOOL)automatic {
    _automaticMode = automatic;
}

- (BOOL)hasPendingMessage {
    return _pendingMessage != nil;
}

- (BatchMessage *_Nullable)popPendingMessage {
    BatchMessage *msg = _pendingMessage;
    _pendingMessage = nil;
    return msg;
}

- (BOOL)showPendingMessage {
    BatchMessage *msg = [self popPendingMessage];
    if (msg) {
        [self displayMessage:msg bypassDnD:false error:nil];
        return true;
    }
    return false;
}

- (void)setFontOverride:(UIFont *)font boldFont:(UIFont *)boldFont {
    [self setFontOverride:font boldFont:boldFont italicFont:nil boldItalicFont:nil];
}

- (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont {
    if (font == nil) {
        [BAMSGLabel setFontOverride:nil boldFont:nil italicFont:nil boldItalicFont:nil];
        [BAMSGButton setFontOverride:nil boldFont:nil italicFont:nil boldItalicFont:nil];
        [InAppFont reset];
    } else {
        [BAMSGLabel setFontOverride:font boldFont:boldFont italicFont:italicFont boldItalicFont:boldItalicFont];
        [BAMSGButton setFontOverride:font boldFont:boldFont italicFont:italicFont boldItalicFont:boldItalicFont];
        [InAppFont setFontOverride:font boldFont:boldFont italicFont:italicFont boldItalicFont:boldItalicFont];
    }
}

- (void)setEnableDynamicType:(BOOL)enableDynamicType {
    _enableDynamicType = enableDynamicType;
}

- (BOOL)enableDynamicType {
    if (@available(iOS 15.0, *)) {
        return _enableDynamicType;
    }
    return false;
}

- (void)handleInAppMessage:(nonnull BatchInAppMessage *)message {
    [BAThreading performBlockOnMainThreadAsync:^{
      if ([self->_wrappedInAppDelegate batchInAppMessageReady:message]) {
          [BALogger debugForDomain:LOGGER_DOMAIN
                           message:@"Called developer's delegate with the In-App message %@", message];
      } else {
          if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
              NSError *err;
              if ([self displayMessage:message bypassDnD:false error:&err]) {
                  [BALogger debugForDomain:LOGGER_DOMAIN message:@"Displayed the In-App message %@", message];
              } else {
                  [BALogger publicForDomain:LOGGER_DOMAIN
                                    message:@"Batch tried to display an In-App message, but failed. Error: %@",
                                            err ? err.localizedDescription : @"Unknown"];
              }
          } else {
              [BALogger debugForDomain:LOGGER_DOMAIN
                               message:@"An In-App message should have been shown, but the app is in the "
                                       @"UIApplicationStateBackground state"];
          }
      }
    }];
}

- (UIViewController *_Nullable)loadViewControllerForMessage:(BatchMessage *_Nonnull)message
                                                      error:(NSError *_Nullable *_Nullable)error {
    /*if (_automaticMode)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorAutomaticModeNotDisabled
                                     userInfo:@{NSLocalizedDescriptionKey: @"Automatic mode must be disabled on
    BatchMessaging before you can use loadViewControllerForMessage:error: ."}];
        }

        return nil;
    }*/

    return [self internalLoadViewControllerForMessage:message error:error];
}

- (BOOL)presentMessagingViewController:(nonnull UIViewController *)vc error:(NSError **)error {
#if TARGET_OS_VISION
    [BALogger publicForDomain:@"Messaging"
                      message:@"Refusing to presentMessagingViewController: unsupported on visionOS"];
    return false;
#else
    if (![NSThread currentThread].isMainThread) {
        [BALogger publicForDomain:@"Messaging"
                          message:@"[BatchMessaging presentMessagingViewController:] was called outside of the main "
                                  @"thead. Aborting."];
        return false;
    }

    if ([[BAOptOut instance] isOptedOut]) {
        if (error) {
            *error = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorOptedOut
                       userInfo:@{
                           NSLocalizedDescriptionKey : @"Cannot perform messaging action: Batch is opted-out from"
                       }];
        }

        return false;
    }

    if (![vc respondsToSelector:@selector(shouldDisplayInSeparateWindow)]) {
        return false;
    }

    if ([(id)vc shouldDisplayInSeparateWindow]) {
        return [self showViewControllerInOwnWindow:vc error:error];
    } else {
        BOOL hasDeveloperOverridenVC = true;
        __block UIViewController *targetVC = [_wrappedDelegate presentingViewControllerForBatchUI];
        if (!targetVC) {
            hasDeveloperOverridenVC = false;
            targetVC = [[BAWindowHelper keyWindow] rootViewController];
        }

        if (targetVC) {
            UIViewController *presentedVC = targetVC.presentedViewController;
            while (presentedVC.presentedViewController) {
                presentedVC = presentedVC.presentedViewController;
            }
            if ([presentedVC isKindOfClass:[UIAlertController class]]) {
                [BALogger publicForDomain:LOGGER_DOMAIN
                                  message:@"A Batch message was about to be displayed on Alert Controller"];
                if (error) {
                    *error =
                        [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                            code:BatchMessagingErrorNoSuitableVCForDisplay
                                        userInfo:@{
                                            NSLocalizedDescriptionKey :
                                                @"Could not find a suitable view controller to display the message on."
                                        }];
                }
                return false;
            }
            void (^presentationBlock)(void) = ^{
              [targetVC presentViewController:vc animated:YES completion:nil];
            };

            if ([presentedVC isKindOfClass:[BAMSGInterstitialViewController class]]) {
                [presentedVC dismissViewControllerAnimated:true completion:presentationBlock];
            } else {
                if (presentedVC && !hasDeveloperOverridenVC) {
                    targetVC = presentedVC;
                }
                presentationBlock();
            }
            return true;
        } else {
            [BALogger publicForDomain:LOGGER_DOMAIN
                              message:@"A Batch message was about to be displayed, but no suitable View Controller has "
                                      @"been found"];
            if (error) {
                *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                             code:BatchMessagingErrorNoSuitableVCForDisplay
                                         userInfo:@{
                                             NSLocalizedDescriptionKey :
                                                 @"Could not find a suitable view controller to display the message on."
                                         }];
            }
            return false;
        }
    }
#endif
}

- (UIViewController *_Nullable)internalLoadViewControllerForMessage:(BatchMessage *_Nonnull)message
                                                              error:(NSError *_Nullable *_Nullable)error {
#if TARGET_OS_VISION
    [BALogger publicForDomain:@"Messaging"
                      message:@"Refusing to load messaging view controller: unsupported on visionOS"];
    return nil;
#else
    if (error) {
        *error = nil;
    }

    if (![NSThread currentThread].isMainThread) {
        if (error) {
            *error =
                [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                    code:BatchMessagingErrorNotOnMainThread
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        @"loadViewControllerForMessage:error: should be called from the main thread"
                                }];
        }

        return nil;
    }

    if ([[BAOptOut instance] isOptedOut]) {
        if (error) {
            *error = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorOptedOut
                       userInfo:@{
                           NSLocalizedDescriptionKey : @"Cannot perform messaging action: Batch is opted-out from"
                       }];
        }

        return nil;
    }

    BAMSGMessage *msg;
    if ([message isCEPMessage]) {
        msg = [BAMSGPayloadParser messageForCEPRawMessage:message bailIfNotAlert:NO];
    } else {
        msg = [BAMSGPayloadParser messageForMEPRawMessage:message bailIfNotAlert:NO];
    }

    if ([msg isKindOfClass:[BAMSGCEPMessage class]]) {
        return [InAppViewControllerProvider viewControllerWithMessage:(BAMSGCEPMessage *)msg error:error];
    } else if ([msg isKindOfClass:[BAMSGMessageAlert class]]) {
        return [BADelegatedUIAlertController alertControllerWithMessage:(BAMSGMessageAlert *)msg];
    } else if ([msg isKindOfClass:[BAMSGMessageInterstitial class]]) {
        BAMSGMessageInterstitial *universalMessage = (BAMSGMessageInterstitial *)msg;

        NSError *err = nil;

        NSURL *imageURL = [NSURL URLWithString:universalMessage.heroImageURL];

        BOOL hasHeroContent = imageURL != nil || universalMessage.videoURL != nil;
        BOOL shouldWaitForImageDownload = imageURL != nil && !universalMessage.videoURL;

        BAMSGInterstitialViewController *universalVC =
            [self universalViewControllerForMessage:universalMessage
                                     hasHeroContent:hasHeroContent
                                 shouldWaitForImage:shouldWaitForImageDownload
                                              error:&err];

        if (imageURL && !universalMessage.videoURL) {
            __weak BAMSGInterstitialViewController *weakVC = universalVC;
            [BAMSGImageDownloader downloadImageForURL:imageURL
                                      downloadTimeout:self.imageDownloadTimeout
                                    completionHandler:^(NSData *_Nullable data, BOOL isGif, UIImage *_Nullable image,
                                                        NSError *_Nullable error) {
                                      if (isGif) {
                                          [weakVC didFinishLoadingGIFHero:data];
                                      } else {
                                          [weakVC didFinishLoadingHero:image];
                                      }
                                    }];
        }

        if (error && err) {
            *error = err;
        }

        return universalVC;
    } else if ([msg isKindOfClass:[BAMSGMessageBanner class]]) {
        BAMSGMessageBanner *bannerMessage = (BAMSGMessageBanner *)msg;

        NSError *err = nil;

        BAMSGBannerViewController *bannerVC = [self bannerViewControllerForMessage:bannerMessage error:&err];

        if (error && err) {
            *error = err;
        }

        return bannerVC;
    } else if ([msg isKindOfClass:[BAMSGMessageModal class]]) {
        BAMSGMessageModal *modalMessage = (BAMSGMessageModal *)msg;

        NSError *err = nil;

        BAMSGModalViewController *modalVC = [self modalViewControllerForMessage:modalMessage error:&err];

        if (error && err) {
            *error = err;
        }

        return modalVC;
    } else if ([msg isKindOfClass:[BAMSGMessageImage class]]) {
        BAMSGMessageImage *imageMessage = (BAMSGMessageImage *)msg;

        NSError *err = nil;

        BAMSGImageViewController *imageVC = [self imageViewControllerForMessage:imageMessage error:&err];

        if (error && err) {
            *error = err;
        }

        return imageVC;
    } else if ([msg isKindOfClass:[BAMSGMessageWebView class]]) {
        BAMSGMessageWebView *webviewMessage = (BAMSGMessageWebView *)msg;

        NSError *err = nil;

        BAMSGWebviewViewController *imageVC = [self webviewViewControllerForMessage:webviewMessage error:&err];

        if (error && err) {
            *error = err;
        }

        return imageVC;
    } else {
        if (error) {
            *error = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorNoValidBatchMessage
                       userInfo:@{
                           NSLocalizedDescriptionKey :
                               @"Payload didn't contain a valid Batch message or this SDK is too old to understand it."
                       }];
        }

        return nil;
    }
#endif
}

- (BOOL)performAction:(nonnull BAMSGAction *)action source:(nullable id<BatchUserActionSource>)source {
    if (!action) {
        return false;
    }

    // A button with no action identifier will still close the message, since all buttons do
    if (action.actionIdentifier) {
        if ([@"" isEqualToString:action.actionIdentifier]) {
            [BALogger publicForDomain:LOGGER_DOMAIN
                              message:@"Internal error - A callback CTA was triggered but the action string was empty. "
                                      @"This shouldn't happen: please report this to Batch support: https://batch.com"];
            return false;
        }

        if (![[BAActionsCenter instance] performAction:action.actionIdentifier
                                              withArgs:action.actionArguments
                                             andSource:source]) {
            [BALogger publicForDomain:LOGGER_DOMAIN
                              message:@"The action '%@' couldn't be found. Did you forget to register it?",
                                      action.actionIdentifier];
            return false;
        }
    }

    return true;
}

- (void)performAction:(nonnull BAMSGAction *)action
               source:(nullable id<BatchUserActionSource>)source
        ctaIdentifier:(NSString *_Nonnull)ctaIdentifier
    messageIdentifier:(nullable NSString *)identifier {
    if (![self performAction:action source:source]) {
        return;
    }

    BatchMessageAction *publicAction = nil;

    if ([action isKindOfClass:[BAMSGCTA class]]) {
        publicAction = [[BatchMessageCTA alloc] _initWithInternalAction:(BAMSGCTA *)action];
    } else {
        publicAction = [[BatchMessageAction alloc] _initWithInternalAction:action];
    }

    [_wrappedDelegate batchMessageDidTriggerAction:publicAction
                                 messageIdentifier:identifier
                                     ctaIdentifier:ctaIdentifier];
}

#pragma mark Event tracking

- (NSMutableDictionary *)baseEventParametersForMessage:(BAMSGMessage *_Nonnull)message type:(NSString *_Nonnull)type {
    NSMutableDictionary *parameters = [NSMutableDictionary new];

    NSString *messageSource;
    if ([message.sourceMessage isKindOfClass:[BatchInAppMessage class]]) {
        messageSource = @"local";
    } else if ([message.sourceMessage isKindOfClass:[BatchPushMessage class]]) {
        if (((BatchPushMessage *)message.sourceMessage).isDisplayedFromInbox) {
            messageSource = @"inbox-landing";
        } else {
            messageSource = @"landing";
        }
    } else {
        messageSource = @"unknown";
    }
    [parameters setObject:messageSource forKey:@"s"];

    if (message.sourceMessage != nil) {
        // Ensure messageIdentifier is not null since CEP message does't have global identifier.
        if (![BANullHelper isNull:message.sourceMessage.messageIdentifier]) {
            [parameters setObject:message.sourceMessage.messageIdentifier forKey:@"id"];
        }
        if (message.sourceMessage.eventData != nil) {
            [parameters setObject:message.sourceMessage.eventData forKey:@"ed"];
        }
    }

    [parameters setObject:type forKey:@"type"];

    return parameters;
}

- (void)trackGenericEvent:(BAMSGMessage *_Nonnull)message type:(NSString *_Nonnull)type {
    [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME
                            parameters:[self baseEventParametersForMessage:message type:type]];
}

- (void)trackCTAClickEvent:(BAMSGMessage *_Nonnull)message
             ctaIdentifier:(NSString *_Nonnull)ctaIdentifier
                    action:(NSString *)action {
    NSMutableDictionary *parameters = [self baseEventParametersForMessage:message type:BAMESSAGING_EVENT_TYPE_CTA];
    [parameters setObject:ctaIdentifier forKey:@"ctaId"];
    [parameters setObject:(action != nil ? action : [NSNull null]) forKey:@"action"];
    [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME parameters:parameters];
}

- (void)trackCTAClickEvent:(BAMSGMessage *_Nonnull)message
             ctaIdentifier:(NSString *)ctaIdentifier
                   ctaType:(NSString *)ctaType
                    action:(NSString *)action {
    NSMutableDictionary *parameters = [self baseEventParametersForMessage:message type:BAMESSAGING_EVENT_TYPE_CTA];
    [parameters setObject:(action != nil ? action : [NSNull null]) forKey:@"action"];
    [parameters setObject:ctaIdentifier forKey:@"ctaId"];
    [parameters setObject:ctaType forKey:@"ctaType"];
    [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME parameters:parameters];
}

- (void)trackCloseError:(BAMSGMessage *_Nonnull)message cause:(BATMessagingCloseErrorCause)cause {
    NSMutableDictionary *parameters = [self baseEventParametersForMessage:message
                                                                     type:BAMESSAGING_EVENT_TYPE_CLOSE_ERROR];
    [parameters setObject:@(cause) forKey:@"cause"];
    [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME parameters:parameters];
}

- (void)trackWebViewClickEvent:(BAMSGMessage *_Nonnull)message
                        action:(BAMSGAction *)action
           analyticsIdentifier:(NSString *)analyticsID {
    NSMutableDictionary *parameters = [self baseEventParametersForMessage:message
                                                                     type:BAMESSAGING_EVENT_TYPE_WEBVIEW_CLICK];
    if (![BANullHelper isStringEmpty:analyticsID]) {
        [parameters setObject:analyticsID forKey:@"analyticsID"];
    }
    if (action != nil && action.actionIdentifier != nil) {
        [parameters setObject:action.actionIdentifier forKey:@"actionName"];
    }
    [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME parameters:parameters];
}

- (void)messageShown:(BAMSGMessage *_Nonnull)message {
    if (message != nil) {
        [[BANotificationCenter defaultCenter] postNotificationName:kBATMessagingMessageDidAppear object:message];

        [self trackGenericEvent:message type:BAMESSAGING_EVENT_TYPE_SHOW];

        if ([message.sourceMessage isKindOfClass:[BatchInAppMessage class]]) {
            // Maybe there's a better way to decouple classes here, but forward this to the In-App Campaigns module if
            // needed
            BatchInAppMessage *castedSourceMessage = ((BatchInAppMessage *)message.sourceMessage);
            [[BALocalCampaignsCenter instance]
                didPerformCampaignOutputWithIdentifier:castedSourceMessage.campaignIdentifier
                                             eventData:castedSourceMessage.eventData];
        }

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage];
        if (payload != nil) {
            [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingShow payload:payload];
        }
    }

    [_wrappedDelegate batchMessageDidAppear:message.sourceMessage.devTrackingIdentifier];
}

- (void)messageAutomaticallyClosed:(BAMSGMessage *_Nonnull)message {
    if (message != nil) {
        [self trackGenericEvent:message type:BAMESSAGING_EVENT_TYPE_AUTO_CLOSE];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage];
        if (payload != nil) {
            [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingAutoClose payload:payload];
        }
    }

    [_wrappedDelegate batchMessageDidDisappear:message.sourceMessage.devTrackingIdentifier
                                        reason:BatchMessagingCloseReasonAuto];
}

- (void)messageClosed:(BAMSGMessage *_Nonnull)message {
    if (message != nil) {
        [self trackGenericEvent:message type:BAMESSAGING_EVENT_TYPE_CLOSE];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage];
        if (payload != nil) {
            [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClose payload:payload];
        }
    }

    [_wrappedDelegate batchMessageDidDisappear:message.sourceMessage.devTrackingIdentifier
                                        reason:BatchMessagingCloseReasonUser];
}

- (void)message:(BAMSGMessage *_Nonnull)message closedByError:(BATMessagingCloseErrorCause)errorCause {
    if (message != nil) {
        [self trackCloseError:message cause:errorCause];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage];
        if (payload != nil) {
            [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingCloseError payload:payload];
        }
    }

    [_wrappedDelegate batchMessageDidDisappear:message.sourceMessage.devTrackingIdentifier
                                        reason:BatchMessagingCloseReasonError];
}

- (void)messageDismissed:(BAMSGMessage *_Nonnull)message {
    if (message != nil) {
        [[BANotificationCenter defaultCenter] postNotificationName:kBATMessagingMessageDidDisappear object:message];

        [self trackGenericEvent:message type:BAMESSAGING_EVENT_TYPE_DISMISS];
    }
    [_wrappedDelegate batchMessageDidDisappear:message.sourceMessage.devTrackingIdentifier
                                        reason:BatchMessagingCloseReasonAction];
}

- (void)messageGlobalTapActionTriggered:(BAMSGMessage *_Nonnull)message action:(BAMSGAction *)action {
    if (message != nil) {
        NSMutableDictionary *parameters = [self baseEventParametersForMessage:message
                                                                         type:BAMESSAGING_EVENT_TYPE_GLOBAL_TAP];
        [parameters setObject:(action.actionIdentifier != nil ? action.actionIdentifier : [NSNull null])
                       forKey:@"action"];
        [BATrackerCenter trackPrivateEvent:BAMESSAGING_EVENT_NAME parameters:parameters];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage action:action];
        if (payload != nil) {
            if ([action isDismissAction]) {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClose payload:payload];
            } else {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClick payload:payload];
            }
        }
    }
}

- (void)messageButtonClicked:(BAMSGMessage *_Nonnull)message
               ctaIdentifier:(NSString *_Nonnull)ctaIdentifier
                      action:(BAMSGCTA *)action {
    if (message != nil) {
        [self trackCTAClickEvent:message ctaIdentifier:ctaIdentifier action:action.actionIdentifier];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage action:action];
        if (payload != nil) {
            if ([action isDismissAction]) {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClose payload:payload];
            } else {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClick payload:payload];
            }
        }
    }
}

- (void)messageButtonClicked:(BAMSGMessage *_Nonnull)message
               ctaIdentifier:(NSString *)ctaIdentifier
                     ctaType:(NSString *)ctaType
                      action:(BAMSGAction *)action {
    if (message != nil) {
        [self trackCTAClickEvent:message ctaIdentifier:ctaIdentifier ctaType:ctaType action:action.actionIdentifier];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage action:action];
        if (payload != nil) {
            if ([action isDismissAction]) {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClose payload:payload];
            } else {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClick payload:payload];
            }
        }
    }
}

- (void)messageWebViewClickTracked:(BAMSGMessage *_Nonnull)message
                            action:(BAMSGAction *)action
               analyticsIdentifier:(NSString *)analyticsID {
    if (message != nil) {
        [self trackWebViewClickEvent:message action:action analyticsIdentifier:analyticsID];

        id<BatchEventDispatcherPayload> payload =
            [BAEventDispatcherCenter messageEventPayloadFromMessage:message.sourceMessage
                                                             action:action
                                         webViewAnalyticsIdentifier:analyticsID];
        if (payload != nil) {
            if ([action isDismissAction]) {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingClose payload:payload];
            } else {
                [self.eventDispatcher dispatchEventWithType:BatchEventDispatcherTypeMessagingWebViewClick
                                                    payload:payload];
            }
        }
    }
}

#pragma mark Instance methods

- (BAEventDispatcherCenter *)eventDispatcher {
    return [BAInjection injectClass:BAEventDispatcherCenter.class];
}

/**
 Display a message on the most appropriate view controller Batch can find.
 Warning: this does NOT take into account the automatic mode switch
 This must be called on the main thread

 @param message BatchMessage instance to display
 @param outErr Error output pointer
 @return YES on success, NO on failure
 */
- (BOOL)displayMessage:(BatchMessage *_Nonnull)message
             bypassDnD:(BOOL)bypassDnD
                 error:(NSError *_Nullable *_Nullable)outErr {
#if TARGET_OS_VISION
    [BALogger publicForDomain:LOGGER_DOMAIN message:@"Batch Messaging is unsupported on visionOS."];
    return false;
#else
    if (self.doNotDisturb && !bypassDnD) {
        [BALogger
            publicForDomain:LOGGER_DOMAIN
                    message:@"A BatchMessage was attempted to be displayed, but Do Not Disturb is enabled. Enqueing."];
        _pendingMessage = message;
        return true;
    }

    NSError *err = nil;
    UIViewController *vc = [self internalLoadViewControllerForMessage:message error:&err];

    if (err) {
        [BALogger
            publicForDomain:LOGGER_DOMAIN
                    message:@"An error occurred while loading Batch's messaging view: %@", [err localizedDescription]];
        if (outErr) {
            *outErr = err;
        }
        return false;
    } else if (vc) {
        return [self presentMessagingViewController:vc error:outErr];
    } else {
        if (outErr) {
            *outErr = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorInternal
                       userInfo:@{
                           NSLocalizedDescriptionKey : @"Could not load Batch's messaging view for an unknown reason."
                       }];
        }
        return false;
    }
#endif
}

- (BAMSGMessage *)messageForObject:(id)object {
    if (object == nil) {
        return nil;
    }

    id retVal = objc_getAssociatedObject(object, &kBABatchMessagingMessageModelObject);

    if (![retVal isKindOfClass:[BAMSGMessage class]]) {
        return nil;
    }

    return retVal;
}

- (BAMSGInterstitialViewController *)universalViewControllerForMessage:(BAMSGMessageInterstitial *)message
                                                        hasHeroContent:(BOOL)hasHeroContent
                                                    shouldWaitForImage:(BOOL)waitForImage
                                                                 error:(NSError **)error {
    NSError *cssError = nil;
    BACSSDocument *style = [[BACSSParser parserWithString:message.css
                                        andImportProvider:[BACSSBuiltinImportProvider new]] parseWithError:&cssError];
    if (!style || cssError) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid style attributes."}];
        }
        return nil;
    }

    BAMSGInterstitialViewController *vc = [[BAMSGInterstitialViewController alloc] initWithStyleRules:style
                                                                                       hasHeroContent:hasHeroContent
                                                                                   shouldWaitForImage:waitForImage];
    vc.messageDescription = message;
    vc.headingText = message.headingText;
    vc.titleText = message.titleText;
    vc.subtitleText = message.subtitleText;
    vc.bodyText = message.bodyText;
    vc.bodyHtml = message.bodyHtml;
    vc.ctas = message.ctas;
    vc.attachCTAsBottom = message.attachCTAsBottom;
    vc.stackCTAsHorizontally = message.stackCTAsHorizontally;
    vc.stretchCTAsHorizontally = message.stretchCTAsHorizontally;
    vc.flipHeroVertical = message.flipHeroVertical;
    vc.flipHeroHorizontal = message.flipHeroHorizontal;
    [vc setCloseButtonEnabled:message.showCloseButton autoclosingDuration:message.autoClose];

    if (message.heroSplitRatio != nil) {
        vc.heroSplitRatio = [message.heroSplitRatio floatValue];
    }

    if (message.videoURL) {
        vc.videoURL = [NSURL URLWithString:message.videoURL];
    }

    if (![vc canBeClosed]) {
        if (error) {
            *error = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorInternal
                       userInfo:@{
                           NSLocalizedDescriptionKey : @"This universal template is unclosable. Refusing to show it."
                       }];
        }
        return nil;
    }

    return vc;
}

- (NSError *)setupBaseBannerViewController:(BAMSGBaseBannerViewController *)vc
                                forMessage:(BAMSGMessageBaseBanner *)message {
    vc.messageDescription = message;
    vc.titleText = message.titleText;
    vc.bodyText = message.bodyText;
    vc.bodyHtml = message.bodyHtml;
    vc.ctas = message.ctas;
    vc.ctaStackDirection = message.ctaDirection;
    vc.allowSwipeToDismiss = message.allowSwipeToDismiss;
    vc.globalTapAction = message.globalTapAction;
    vc.globalTapDelay = message.globalTapDelay;
    vc.imageURL = message.imageURL;
    vc.imageDescription = message.imageDescription;
    [vc setCloseButtonEnabled:message.showCloseButton autoclosingDuration:message.autoClose];

    if (![vc canBeClosed]) {
        return [NSError
            errorWithDomain:MESSAGING_ERROR_DOMAIN
                       code:BatchMessagingErrorInternal
                   userInfo:@{NSLocalizedDescriptionKey : @"This template is unclosable. Refusing to show it."}];
    }

    return nil;
}

- (BAMSGBannerViewController *)bannerViewControllerForMessage:(BAMSGMessageBanner *)message error:(NSError **)error {
    NSError *cssError = nil;
    BACSSDocument *style = [[BACSSParser parserWithString:message.css
                                        andImportProvider:[BACSSBuiltinImportProvider new]] parseWithError:&cssError];
    if (!style || cssError) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid style attributes."}];
        }
        return nil;
    }

    BAMSGBannerViewController *vc = [[BAMSGBannerViewController alloc] initWithStyleRules:style];
    NSError *setupErr = [self setupBaseBannerViewController:vc forMessage:message];
    if (setupErr != nil) {
        if (error) {
            *error = setupErr;
        }
        return nil;
    }

    return vc;
}

- (BAMSGModalViewController *)modalViewControllerForMessage:(BAMSGMessageModal *)message error:(NSError **)error {
    NSError *cssError = nil;
    BACSSDocument *style = [[BACSSParser parserWithString:message.css
                                        andImportProvider:[BACSSBuiltinImportProvider new]] parseWithError:&cssError];
    if (!style || cssError) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid style attributes."}];
        }
        return nil;
    }

    BAMSGModalViewController *vc = [[BAMSGModalViewController alloc] initWithStyleRules:style];
    NSError *setupErr = [self setupBaseBannerViewController:vc forMessage:message];
    if (setupErr != nil) {
        if (error) {
            *error = setupErr;
        }
        return nil;
    }

    return vc;
}

- (BAMSGImageViewController *)imageViewControllerForMessage:(BAMSGMessageImage *)message error:(NSError **)error {
    NSError *cssError = nil;
    BACSSDocument *style = [[BACSSParser parserWithString:message.css
                                        andImportProvider:[BACSSBuiltinImportProvider new]] parseWithError:&cssError];
    if (!style || cssError) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid style attributes."}];
        }
        return nil;
    }

    BAMSGImageViewController *vc = [[BAMSGImageViewController alloc] initWithMessage:message andStyle:style];
    return vc;
}

- (BAMSGWebviewViewController *)webviewViewControllerForMessage:(BAMSGMessageWebView *)message error:(NSError **)error {
    NSError *cssError = nil;
    BACSSDocument *style = [[BACSSParser parserWithString:message.css
                                        andImportProvider:[BACSSBuiltinImportProvider new]] parseWithError:&cssError];
    if (!style || cssError) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid style attributes."}];
        }
        return nil;
    }

    BAMSGWebviewViewController *vc = [[BAMSGWebviewViewController alloc] initWithMessage:message andStyle:style];
    return vc;
}

- (BOOL)showViewControllerInOwnWindow:(UIViewController *)vc error:(NSError **)error {
    if (vc == nil) {
        if (error) {
            *error = [NSError errorWithDomain:MESSAGING_ERROR_DOMAIN
                                         code:BatchMessagingErrorInternal
                                     userInfo:@{NSLocalizedDescriptionKey : @"Invalid view controller."}];
        }
        return false;
    }

    UIWindow *overlayedWindow = [BAWindowHelper keyWindow];
    UIViewController *frontmostViewController = [BAWindowHelper frontmostViewController];
    if ([frontmostViewController isKindOfClass:SFSafariViewController.class]) {
        if (error) {
            *error = [NSError
                errorWithDomain:MESSAGING_ERROR_DOMAIN
                           code:BatchMessagingErrorInternal
                       userInfo:@{
                           NSLocalizedDescriptionKey :
                               @"An SFSafariViewController is already presenting and may not be hidden or obscured."
                       }];
        }
        return false;
    }
    BAMSGOverlayWindow *shownWindow = self.shownWindow;
    if (shownWindow) {
        UIViewController *shownVC = [shownWindow rootViewController];
        if ([shownVC conformsToProtocol:@protocol(BAMSGWindowHolder)]) {
            // Try to get the originally overlayed window from the previously shown view controller
            // It is kind hackish but it's the best way to get the previous key window without waiting for the
            // animation to be finished
            UIWindow *previouslyOverlayedWindow = ((id<BAMSGWindowHolder>)shownVC).overlayedWindow;
            if (previouslyOverlayedWindow != nil) {
                overlayedWindow = previouslyOverlayedWindow;
            }
        }
        [shownWindow dismissAnimated];
        self.shownWindow = nil;
    }

    BAMSGOverlayWindow *window;
    UIWindowScene *scene = [BAWindowHelper keyWindow].windowScene;
    if (scene != nil) {
        window = [[BAMSGOverlayWindow alloc] initWithWindowScene:scene];
    }

    if (window == nil) {
#if TARGET_OS_VISION
        // Vision pro has no way to get the screen size as it does not _really_ have
        // a screen size in VR space. We have to use a default one
        // FIXME: Fix this to reenable In-Apps
        window = [[BAMSGOverlayWindow alloc] initWithFrame:CGRectMake(0, 0, 1280, 720)];
#else
        window = [[BAMSGOverlayWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
#endif
    }
    if ([vc conformsToProtocol:@protocol(BAMSGWindowHolder)]) {
        // This NEEDS to be before rootViewController is set on the window, as this will trigger viewDidLoad
        // which requires overlayedWindow to be set, if possible
        ((id<BAMSGWindowHolder>)vc).overlayedWindow = overlayedWindow;
        ((id<BAMSGWindowHolder>)vc).presentingWindow = window;
    }

    window.rootViewController = vc;
    window.visibilityAnimationDuration = BAMESSAGING_BANNER_ANIMATION_DURATION;

    [window presentAnimated];

    self.shownWindow = window;
    return true;
}

- (BAPromise *)dismissWindow:(nullable BAMSGOverlayWindow *)window {
    BAPromise *dismissPromise = [BAPromise new];
    [BAThreading performBlockOnMainThread:^{
      if (self.shownWindow == window) {
          BAPromise *windowPromise = [window dismissAnimated];
          [windowPromise then:^(NSObject *_Nullable value) {
            [dismissPromise resolve:value];
          }];
          [windowPromise catch:^(NSError *_Nullable error) {
            [dismissPromise reject:error];
          }];
          self.shownWindow = nil;
      } else {
          // Don't reject, it may just be gone already
          [dismissPromise resolve:nil];
      }
    }];
    return dismissPromise;
}

- (void)presentLandingMessage:(BatchMessage *_Nonnull)message bypassDnD:(BOOL)bypassDnD {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Trying to present landing message while application is in background"];
    }
    [BAThreading performBlockOnMainThreadAsync:^{
      [self displayMessage:message bypassDnD:bypassDnD error:nil];
    }];
}

@end
