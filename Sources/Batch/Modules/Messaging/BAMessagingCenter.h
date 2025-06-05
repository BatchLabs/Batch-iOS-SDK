//
//  BAMessagingCenter.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Batch/BABatchInAppDelegateWrapper.h>
#import <Batch/BABatchMessagingDelegateWrapper.h>
#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BAMSGBannerViewController.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BAMSGModalViewController.h>
#import <Batch/BAMSGOverlayWindow.h>
#import <Batch/BAMessagingAnalyticsDelegate.h>
#import <Batch/BatchMessaging.h>

#import <Batch/BAInjection.h>

extern NSString *_Nonnull const kBATMessagingMessageDidAppear;
extern NSString *_Nonnull const kBATMessagingMessageDidDisappear;

NS_ASSUME_NONNULL_BEGIN

@interface BAMessagingCenter : NSObject <BACenterProtocol, BAMessagingAnalyticsDelegate>

@property (readonly) BOOL automaticMode;

@property (readonly) BOOL canReconfigureAVAudioSession;

@property (readonly) NSTimeInterval imageDownloadTimeout;

@property (nonatomic) BOOL doNotDisturb;

@property (nullable) BAMSGOverlayWindow *shownWindow;

@property (readonly) BOOL enableDynamicType;

+ (instancetype _Nonnull)instance BATCH_USE_INJECTION_OUTSIDE_TESTS;

- (void)setDelegate:(id<BatchMessagingDelegate> _Nullable)delegate;

- (id<BatchMessagingDelegate> _Nullable)delegate;

- (void)setInAppDelegate:(id<BatchInAppDelegate> _Nullable)delegate;

- (id<BatchInAppDelegate> _Nullable)inAppDelegate;

- (void)setImageDownloadTimeout:(NSTimeInterval)timeout;

- (void)setCanReconfigureAVAudioSession:(BOOL)canReconfigureAVAudioSession;

- (void)setAutomaticMode:(BOOL)automatic;

- (BOOL)hasPendingMessage;

- (BatchMessage *_Nullable)popPendingMessage;

- (BOOL)showPendingMessage;

- (void)setFontOverride:(nullable UIFont *)font boldFont:(nullable UIFont *)boldFont;

- (void)setFontOverride:(nullable UIFont *)font
               boldFont:(nullable UIFont *)boldFont
             italicFont:(nullable UIFont *)italicFont
         boldItalicFont:(nullable UIFont *)boldItalicFont;

- (void)setEnableDynamicType:(BOOL)enableDynamicType;

/**
 Process an in-app message (which is the marketing name for landing output of a local campaign)
 This method will check if the app is in the foreground, and then try to display the message, or
 forward it to the delegate if the automatic mode has been disabled

 @param message In-App message to display
 */
- (void)handleInAppMessage:(nonnull BatchInAppMessage *)message;

- (UIViewController *_Nullable)loadViewControllerForMessage:(BatchMessage *_Nonnull)message
                                                      error:(NSError *_Nullable *_Nullable)error;

- (BOOL)presentMessagingViewController:(nonnull UIViewController *)vc error:(NSError **)error;

/*
 Same as the non internal method, but removes automatic mode checks and does the actual work
 */
- (UIViewController *_Nullable)internalLoadViewControllerForMessage:(BatchMessage *_Nonnull)message
                                                              error:(NSError *_Nullable *_Nullable)error;

- (void)performAction:(nonnull BAMSGAction *)action
               source:(nullable id<BatchUserActionSource>)source
        ctaIdentifier:(NSString *_Nonnull)ctaIdentifier
    messageIdentifier:(nullable NSString *)identifier;

- (BAPromise *)dismissWindow:(nullable BAMSGOverlayWindow *)window;

- (void)presentLandingMessage:(BatchMessage *_Nonnull)message bypassDnD:(BOOL)bypassDnD;

@end

NS_ASSUME_NONNULL_END
