//
//  BAMSGInterstitialViewController.h
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BatchMessaging.h>
#import <Batch/BACSS.h>
#import <Batch/BACSSParser.h>
#import <Batch/BAMSGStackView.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BAMSGViewController.h>
#import <Batch/BatchMessagingModels.h>

@interface BAMSGInterstitialViewController : BAMSGViewController <BatchMessagingViewController, BAMSGStackViewDelegate, UIAdaptivePresentationControllerDelegate>

@property (nullable) NSString *headingText;
@property (nullable) NSString *titleText;
@property (nullable) NSString *subtitleText;
@property (nullable) NSString *bodyText;
@property (nullable) BAMSGHTMLText *bodyHtml;
@property (nullable) UIImage *heroImage;
@property (nullable) NSURL *videoURL;
@property            BOOL attachCTAsBottom;
@property            BOOL stackCTAsHorizontally;
@property            BOOL stretchCTAsHorizontally;
@property            BOOL flipHeroVertical;
@property            BOOL flipHeroHorizontal;
@property            float heroSplitRatio;

@property (nullable) BAMSGMessageInterstitial *messageDescription;

/// Init an intersitial message VS
/// @param style Style
/// @param hasHeroContent If the message should configure itself to display a hero image/gif/video
/// @param waitForImage Should the message wait for an image to be downloaded. Should be false if you're injecting the heroImage or videoURL
- (nonnull instancetype)initWithStyleRules:(nonnull BACSSDocument*)style
                            hasHeroContent:(BOOL)hasHeroContent
                        shouldWaitForImage:(BOOL)waitForImage;

- (BOOL)canBeClosed;

- (void)didFinishLoadingHero:(nullable UIImage*)heroImage;
- (void)didFinishLoadingGIFHero:(nullable NSData*)gifData;

@end
