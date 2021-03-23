//
//  BAMSGMessage.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGMessage.h>

@implementation BAMSGHTMLText

@end

@implementation BAMSGMessage

@end

@implementation BAMSGMessageAlert

@end

@implementation BAMSGMessageInterstitial

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.showCloseButton = YES;
        self.attachCTAsBottom = NO;
        self.stackCTAsHorizontally = NO;
        self.stretchCTAsHorizontally = NO;
        self.flipHeroVertical = NO;
        self.flipHeroHorizontal = NO;
        self.autoClose = 0;
    }
    return self;
}

@end


@implementation BAMSGMessageBaseBanner

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.allowSwipeToDismiss = YES;
        self.globalTapAction = nil;
        self.globalTapDelay = 0;
        self.showCloseButton = YES;
        self.ctaDirection = BAMSGBannerCTADirectionHorizontal;
        self.autoClose = 0;
    }
    return self;
}

@end


@implementation BAMSGMessageBanner

@end

@implementation BAMSGMessageModal

@end

@implementation BAMSGMessageImage

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.imageSize = CGSizeMake(0, 0);
        self.imageURL = nil;
        self.globalTapDelay = 0;
        self.isFullscreen = YES;
        self.allowSwipeToDismiss = YES;
    }
    return self;
}

@end


@implementation BAMSGMessageWebView

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.url = [NSURL URLWithString:@""];
        self.css = @"";
        self.developmentMode = false;
        self.openDeeplinksInApp = false;
        self.timeout = 0;
        self.layoutWorkaround = BAMSGWebViewLayoutWorkaroundApplyInsetsNatively;
    }
    return self;
}

@end
