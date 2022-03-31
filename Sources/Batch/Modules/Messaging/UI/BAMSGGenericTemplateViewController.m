//
//  BAMSGGenericTemplateViewController.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import "BAMSGInterstitialViewController.h"

#import "BAMessagingCenter.h"

#import "BAMSGButton.h"
#import "BAMSGCloseButton.h"
#import "BAMSGGradientView.h"
#import "BAMSGImageView.h"
#import "BAMSGLabel.h"
#import "BAMSGStackViewItem.h"
#import "BAMSGStylableView.h"
#import "BAMSGVideoView.h"
#import "BAThreading.h"

static NSString *kBAMSGGenericTemplateViewControllerHeroConstraint = @"BAMainHeroConstraint";

@import AVFoundation;

@interface BAMSGInterstitialViewController () {
    UIImage *_heroImage;

    BAMSGImageView *heroImageContainer;
    BAMSGImageView *heroImageView;
    BAMSGVideoView *videoView;

    UIView *content;
    BAMSGStackView *innerContent;
    BAMSGCloseButton *closeButton;
    UIView *heroLoadingPlaceholder;
    UIActivityIndicatorView *heroActivityIndicator;

    UIView *ctasContainer;
    BAMSGStackView *innerCtasContainer;

    UIStatusBarStyle currentStatusbarStyle;
    BOOL shouldHideStatusbar;
    BOOL shouldWaitForImage;

    NSString *previousAudioCategory;

    BOOL viewHierarchyReady;
    CGSize viewSize;

    BOOL autoCloseCountdownStarted;
    BOOL dismissed;
}

@end

@implementation BAMSGInterstitialViewController

- (instancetype)initWithStyleRules:(nonnull BACSSDocument *)style shouldWaitForImage:(BOOL)waitForImage {
    self = [super init];
    if (self) {
        _style = style;
        self.ctas = [NSArray new];
        self.showCloseButton = YES;
        self.attachCTAsBottom = NO;
        self.stackCTAsHorizontally = NO;
        self.stretchCTAsHorizontally = NO;
        self.heroSplitRatio = 0.4;
        self.flipHeroVertical = NO;
        self.flipHeroHorizontal = NO;

        currentStatusbarStyle = UIStatusBarStyleDefault;
        shouldHideStatusbar = NO;
        shouldWaitForImage = waitForImage;
        viewHierarchyReady = NO;

        autoCloseCountdownStarted = NO;
        dismissed = NO;
    }
    return self;
}

- (void)loadView {
    self.view = [BAMSGGradientView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    viewSize = [UIScreen mainScreen].bounds.size;

    // Make sure the size is always portrait
    if (viewSize.width > viewSize.height) {
        CGFloat swap = viewSize.width;
        viewSize.width = viewSize.height;
        viewSize.height = swap;
    }

    viewHierarchyReady = NO;

    [self setupAudioSession];

    self.view.backgroundColor = [UIColor whiteColor];
    self.view.opaque = YES;
    BACSSDOMNode *rootContainerNode = [BACSSDOMNode new];
    rootContainerNode.identifier = @"root";
    NSDictionary<NSString *, NSString *> *rootRules = [self rulesForNode:rootContainerNode];
    [BAMSGStylableViewHelper applyCommonRules:rootRules toView:self.view];
    for (NSString *rule in [rootRules allKeys]) {
        if ([@"statusbar" isEqualToString:rule]) {
            NSString *value = rootRules[rule];
            if ([@"light" isEqualToString:value]) {
                currentStatusbarStyle = UIStatusBarStyleLightContent;
                shouldHideStatusbar = NO;
            } else if ([@"dark" isEqualToString:value]) {
                // Dark is a black statusbar -> Default.
                currentStatusbarStyle = UIStatusBarStyleDefault;
                shouldHideStatusbar = NO;
            } else if ([@"hidden" isEqualToString:value]) {
                shouldHideStatusbar = YES;
            }

            [self setNeedsStatusBarAppearanceUpdate];
            break; // We've only got one rule to check, no need to continue
        }
    }

    /*else */
    // Override the alpha, no semi transparent root
    [self.view setAlpha:1];

    content = [BAMSGGradientView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];

    innerContent = [BAMSGStackView new];
    innerContent.delegate = self;
    innerContent.translatesAutoresizingMaskIntoConstraints = NO;
    innerContent.clipsToBounds = YES;
    [content addSubview:innerContent];

    if (self.attachCTAsBottom && [self.ctas count] > 0) {
        // We want the content view to take the most space, and force the CTA container to be on the bottom
        [content setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                 forAxis:UILayoutConstraintAxisVertical];
        [content setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];

        ctasContainer = [BAMSGBaseContainerView new];
        ctasContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:ctasContainer];

        [self fillCtasContainer];
    } else {
        // Add an empty view to simplify the constraints code
        ctasContainer = [UIView new];
        ctasContainer.translatesAutoresizingMaskIntoConstraints = NO;

        [ctasContainer addConstraint:[NSLayoutConstraint constraintWithItem:ctasContainer
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1.0
                                                                   constant:0]];

        [self.view addSubview:ctasContainer];
    }

    if ([self shouldShowHeroView]) {
        heroImageContainer = [BAMSGImageView new];
        heroImageContainer.alwaysShowImage = NO;
        heroImageContainer.image = self.heroImage;
        [self.view addSubview:heroImageContainer];

        BACSSDOMNode *imageContainerNode = [BACSSDOMNode new];
        imageContainerNode.identifier = @"image-cnt";
        imageContainerNode.classes = @[ @"image" ];
        [heroImageContainer applyRules:[self rulesForNode:imageContainerNode]];

        if (self.videoURL) {
            [self fillImageContainerViewWithVideo];
        } else {
            [self fillImageContainerViewWithHero];
        }

        // Do not setup hero-related root view constraints here, this will be handed by updateViewConstraints
    } else {
        // This doesn't need to change on rotation, so do not set them in updateViewConstraints to optimize it
        [self setupMainConstraintsWithoutHero];
    }

    if (self.showCloseButton) {
        closeButton = [BAMSGCloseButton new];

        if (self.autoCloseAfter > 0) {
            // Show the filled countdown before the first paint to avoid seeing the button in a "normal" state
            [closeButton prepareCountdown];
        }

        [closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:closeButton];

        [self applyCloseButtonRules];
    }

    BACSSDOMNode *contentNode = [BACSSDOMNode new];
    contentNode.identifier = @"content";
    [self applyContainerViewRulesForNode:contentNode innerView:innerContent parentView:content fillHeightByDefault:NO];

    [self fillContentView];

    viewHierarchyReady = YES;
}
- (UIStatusBarStyle)preferredStatusBarStyle {
    return currentStatusbarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return shouldHideStatusbar;
}

- (BOOL)shouldDisplayInSeparateWindow {
    return false;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self setupConstraintsForSize:self.view.bounds.size];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [videoView viewDidAppear];

    [BAMessagingCenter.instance messageShown:self.messageDescription];

    [self startAutoCloseCountdown];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [videoView viewDidDisappear];
    [self tearDownAudioSession];

    [BAMessagingCenter.instance messageDismissed:self.messageDescription];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setupConstraintsForSize:size];
}

- (void)setupConstraintsForSize:(CGSize)size {
    // Only do something if we have a hero view. Otherwise, we've set the hero-less constraints somewhere else
    // since they don't need to change.
    // Same goes for the close button

    // Also, abort if our full view hierarchy isn't ready
    if (viewHierarchyReady && [self shouldShowHeroView]) {
        for (NSLayoutConstraint *constraint in [self.view.constraints copy]) {
            if ([constraint.identifier isEqualToString:kBAMSGGenericTemplateViewControllerHeroConstraint]) {
                [self.view removeConstraint:constraint];
            }
        }

        if (size.width > size.height) {
            [self setupMainConstraintsWithHeroLandscape];
        } else {
            [self setupMainConstraintsWithHeroPortrait];
        }
    }
}

- (void)setupAudioSession {
    // Don't change the audio session if the dev disallowed it, or if there's no video to display
    if (!self.videoURL || ![BAMessagingCenter instance].canReconfigureAVAudioSession) {
        return;
    }

    // Try to save the app's previous audio category
    previousAudioCategory = [[AVAudioSession sharedInstance] category];

    NSError *err = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:&err];
    if (err) {
        [BALogger errorForDomain:@"BAMSGVideoView"
                         message:@"Error while setting AVAudioSession to inactive: %@", [err localizedDescription]];
    }

    err = nil;

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&err];
    if (err) {
        [BALogger errorForDomain:@"BAMSGVideoView"
                         message:@"Error while changing AVAudioSession category: %@", [err localizedDescription]];
        previousAudioCategory = nil;
    }
}

- (void)tearDownAudioSession {
    // Same as setupAudioSession with an extra condition
    if (!previousAudioCategory || !self.videoURL || ![BAMessagingCenter instance].canReconfigureAVAudioSession) {
        return;
    }

    NSError *err = nil;
    // Devs that know how to use AVAudioSession and need it will have to set the session as active when the view is
    // dismissed
    [[AVAudioSession sharedInstance] setActive:NO error:&err];
    if (err) {
        [BALogger errorForDomain:@"BAMSGVideoView"
                         message:@"Error while setting AVAudioSession to inactive: %@", [err localizedDescription]];
    }

    err = nil;

    [[AVAudioSession sharedInstance] setCategory:previousAudioCategory error:&err];
    if (err) {
        [BALogger errorForDomain:@"BAMSGVideoView"
                         message:@"Error while changing AVAudioSession category: %@", [err localizedDescription]];
        previousAudioCategory = nil;
    }
}

- (void)startAutoCloseCountdown {
    if (self.autoCloseAfter <= 0 || autoCloseCountdownStarted) {
        return;
    }

    autoCloseCountdownStarted = true;

    [closeButton animateCountdownForDuration:self.autoCloseAfter completionHandler:nil];
    __weak typeof(self) weakSelf = self;
    dispatch_time_t autoCloseTime = dispatch_time(DISPATCH_TIME_NOW, self.autoCloseAfter * NSEC_PER_SEC);
    dispatch_after(autoCloseTime, dispatch_get_main_queue(), ^(void) {
      [weakSelf autoClose];
    });
}

#pragma mark Public (non-lifecycle) methos

- (BOOL)canBeClosed {
    return self.showCloseButton || [self.ctas count] > 0 || self.autoCloseAfter > 0;
}

- (UIImage *)heroImage {
    return _heroImage;
}

- (void)setHeroImage:(UIImage *)heroImage {
    _heroImage = heroImage;
    heroImageContainer.image = heroImage;
    heroImageView.image = heroImage;
}

- (void)didFinishLoadingHero:(nullable UIImage *)heroImage {
    [BAThreading performBlockOnMainThread:^{
      // Prevents the loader from showing if the hero failed to load (nil image) but the view hasn't been constructed
      // yet
      self->shouldWaitForImage = NO;

      [self->heroActivityIndicator stopAnimating];
      [self->heroActivityIndicator removeFromSuperview];

      if (heroImage) {
          [self->heroLoadingPlaceholder removeFromSuperview];
      }

      self.heroImage = heroImage;
    }];
}

#pragma mark Style
- (NSDictionary<NSString *, NSString *> *)rulesForNode:(BACSSDOMNode *)node {
    return [_style flatRulesForNode:node withViewSize:viewSize];
}

#pragma mark Layouting

- (BOOL)shouldShowHeroView {
    return self.heroImage || shouldWaitForImage || self.videoURL;
}

- (void)applyCloseButtonRules {
    BACSSDOMNode *closeNode = [BACSSDOMNode new];
    closeNode.identifier = @"close";

    NSDictionary<NSString *, NSString *> *rules = [self rulesForNode:closeNode];

    [closeButton applyRules:rules];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];

    NSLayoutAttribute alignAttr = NSLayoutAttributeRight;
    UIEdgeInsets margin = UIEdgeInsetsZero;
    UIEdgeInsets safeAreaMargin = UIEdgeInsetsZero;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        // "margin: x x x x" rules have been splitted elsewhere for easier handling
        if ([@"margin-top" isEqualToString:rule]) {
            margin.top = [value floatValue];
        } else if ([@"margin-left" isEqualToString:rule]) {
            margin.left = [value floatValue];
        } else if ([@"margin-right" isEqualToString:rule]) {
            // Right margins are negative with Auto Layout
            margin.right = -[value floatValue];
        } else if ([@"safe-margin-top" isEqualToString:rule]) {
            safeAreaMargin.top = [value floatValue];
        } else if ([@"margin-left" isEqualToString:rule]) {
            safeAreaMargin.left = [value floatValue];
        } else if ([@"margin-right" isEqualToString:rule]) {
            // Right margins are negative with Auto Layout
            safeAreaMargin.right = -[value floatValue];
        } else if ([@"size" isEqualToString:rule]) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];

            [constraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"align" isEqualToString:rule]) {
            // align: right is not handled as this is the default
            if ([@"left" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeLeft;
            } else if ([@"center" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeCenterX;
            }
        }
    }

    NSMutableArray<NSLayoutConstraint *> *marginConstraints = [NSMutableArray new];

    // Only apply the needed margin if not filled
    float alignAttrMargin = 0;
    NSLayoutRelation alignRelation = NSLayoutRelationEqual;
    if (alignAttr == NSLayoutAttributeLeft) {
        alignAttrMargin = margin.left;
        alignRelation = NSLayoutRelationGreaterThanOrEqual;
    } else if (alignAttr == NSLayoutAttributeRight) {
        // We also need to reverse the relation, since the margin will be negative, meaning that GreaterThan will not
        // give the expected result
        alignAttrMargin = margin.right;
        alignRelation = NSLayoutRelationLessThanOrEqual;
    }

    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                              attribute:alignAttr
                                                              relatedBy:alignRelation
                                                                 toItem:self.view
                                                              attribute:alignAttr
                                                             multiplier:1.0
                                                               constant:alignAttrMargin]];

    // Top margin
    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:margin.top]];

    // Add low priority safe area constraints. Padding will win over it.
    if (@available(iOS 11.0, *)) {
        if (alignAttr == NSLayoutAttributeLeft) {
            alignAttrMargin = safeAreaMargin.left;
        } else if (alignAttr == NSLayoutAttributeRight) {
            alignAttrMargin = safeAreaMargin.right;
        }

        UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
        [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                     toItem:safeGuide
                                                                  attribute:NSLayoutAttributeTop
                                                                 multiplier:1.0
                                                                   constant:safeAreaMargin.top]];
        [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:closeButton
                                                                  attribute:alignAttr
                                                                  relatedBy:alignRelation
                                                                     toItem:safeGuide
                                                                  attribute:alignAttr
                                                                 multiplier:1.0
                                                                   constant:alignAttrMargin]];
    }

    [NSLayoutConstraint activateConstraints:marginConstraints];

    [self.view addConstraints:constraints];
}

- (void)applyContainerViewRulesForNode:(BACSSDOMNode *)node
                             innerView:(UIView *)innerView
                            parentView:(UIView *)parentView
                   fillHeightByDefault:(BOOL)defaultFillHeight {
    NSDictionary<NSString *, NSString *> *rules = [self rulesForNode:node];

    [BAMSGStylableViewHelper applyCommonRules:rules toView:parentView];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];

    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterY;
    UIEdgeInsets padding = UIEdgeInsetsZero;
    BOOL heightApplied = NO;
    BOOL maxMinHeightApplied = NO;
    BOOL wantsHeightFilled = defaultFillHeight;

    BOOL useSafeArea = NO;
    BOOL usePaddingForSafeArea = NO;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        if ([@"padding-top" isEqualToString:rule]) {
            padding.top = [value floatValue];
        } else if ([@"padding-bottom" isEqualToString:rule]) {
            padding.bottom = [value floatValue];
        } else if ([@"padding-left" isEqualToString:rule]) {
            padding.left = [value floatValue];
        } else if ([@"padding-right" isEqualToString:rule]) {
            padding.right = [value floatValue];
        } else if ([@"height" isEqualToString:rule]) {
            if (maxMinHeightApplied) {
                continue;
            }
            heightApplied = YES;

            if ([@"100%" isEqualToString:value]) {
                wantsHeightFilled = YES;
            } else {
                NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:innerView
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:[value floatValue]];
                hConstraint.priority = 800;
                [constraints addObject:hConstraint];
            }
        } else if ([@"max-height" isEqualToString:rule]) {
            if (heightApplied) {
                continue;
            }
            maxMinHeightApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"min-height" isEqualToString:rule]) {
            if (heightApplied) {
                continue;
            }
            maxMinHeightApplied = YES;

            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        } else if ([@"align" isEqualToString:rule]) {
            // align: center is not handled as this is the default
            if ([@"top" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeTop;
            } else if ([@"bottom" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeBottom;
            }
        } else if ([@"safe-area" isEqualToString:rule]) {
            if ([@"no" isEqualToString:value]) {
                useSafeArea = NO;
                usePaddingForSafeArea = NO;
            } else if ([@"auto" isEqualToString:value]) {
                useSafeArea = YES;
                usePaddingForSafeArea = NO;
            } else if ([@"copy-padding" isEqualToString:value]) {
                useSafeArea = YES;
                usePaddingForSafeArea = YES;
            }
        }
    }

    BOOL addedSafeAreaConstraints = NO;

    if (useSafeArea) {
        if (@available(iOS 11.0, *)) {
            UILayoutGuide *safeGuide = parentView.safeAreaLayoutGuide;
            NSMutableArray<NSLayoutConstraint *> *safeLayoutConstraints = [NSMutableArray new];
            [safeLayoutConstraints
                addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                       attribute:NSLayoutAttributeTop
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:safeGuide
                                                       attribute:NSLayoutAttributeTop
                                                      multiplier:1.0
                                                        constant:usePaddingForSafeArea ? padding.top : 0]];
            [safeLayoutConstraints
                addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                       attribute:NSLayoutAttributeBottom
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:safeGuide
                                                       attribute:NSLayoutAttributeBottom
                                                      multiplier:1.0
                                                        constant:usePaddingForSafeArea ? -padding.bottom : 0]];
            [safeLayoutConstraints
                addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                       attribute:NSLayoutAttributeLeft
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:safeGuide
                                                       attribute:NSLayoutAttributeLeft
                                                      multiplier:1.0
                                                        constant:usePaddingForSafeArea ? padding.left : 0]];
            [safeLayoutConstraints
                addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                       attribute:NSLayoutAttributeRight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:safeGuide
                                                       attribute:NSLayoutAttributeRight
                                                      multiplier:1.0
                                                        constant:usePaddingForSafeArea ? -padding.right : 0]];
            for (NSLayoutConstraint *c in safeLayoutConstraints) {
                c.priority = 1000;
            }
            [NSLayoutConstraint activateConstraints:safeLayoutConstraints];
            addedSafeAreaConstraints = YES;
        }
    }

    if (wantsHeightFilled) {
        if (!addedSafeAreaConstraints) {
            [parentView
                addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:[NSString
                                                                   stringWithFormat:@"V:|-(%f)-[innerView]-(%f)-|",
                                                                                    padding.top, padding.bottom]
                                                       options:0
                                                       metrics:nil
                                                         views:NSDictionaryOfVariableBindings(innerView)]];
        }
    } else {
        // Padding goes before everything
        [parentView addConstraints:[NSLayoutConstraint
                                       constraintsWithVisualFormat:
                                           [NSString stringWithFormat:@"V:|-(>=%f@1000)-[innerView]-(>=%f@1000)-|",
                                                                      padding.top, padding.bottom]
                                                           options:0
                                                           metrics:nil
                                                             views:NSDictionaryOfVariableBindings(innerView)]];
        // Only apply the needed padding if not filled
        float alignAttrPadding = 0;

        if (alignAttr == NSLayoutAttributeTop) {
            alignAttrPadding = padding.top;
        } else if (alignAttr == NSLayoutAttributeBottom) {
            // Autolayout uses negative values when not using the visual syntax
            alignAttrPadding = -padding.bottom;
        }

        id hAlignView = parentView;
        if (useSafeArea) {
            if (@available(iOS 11.0, *)) {
                hAlignView = parentView.safeAreaLayoutGuide;
            }
        }

        NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:innerView
                                                             attribute:alignAttr
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:hAlignView
                                                             attribute:alignAttr
                                                            multiplier:1.0
                                                              constant:alignAttrPadding];
        // Use a lower priority than the main padding constraint
        c.priority = 700;

        [constraints addObject:c];
    }

    if (addedSafeAreaConstraints) {
        [constraints
            addObjectsFromArray:[NSLayoutConstraint
                                    constraintsWithVisualFormat:[NSString
                                                                    stringWithFormat:@"|-(>=%f)-[innerView]-(>=%f)-|",
                                                                                     padding.left, padding.right]
                                                        options:0
                                                        metrics:nil
                                                          views:NSDictionaryOfVariableBindings(innerView)]];
    } else {
        [constraints
            addObjectsFromArray:[NSLayoutConstraint
                                    constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(%f)-[innerView]-(%f)-|",
                                                                                           padding.left, padding.right]
                                                        options:0
                                                        metrics:nil
                                                          views:NSDictionaryOfVariableBindings(innerView)]];
    }

    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)fillImageContainerViewWithVideo {
    videoView = [[BAMSGVideoView alloc] initWithURL:self.videoURL];
    videoView.backgroundColor = [UIColor blackColor];
    // videoView.clipsToBounds = YES;
    [heroImageContainer addSubview:videoView];

    BACSSDOMNode *videoNode = [BACSSDOMNode new];
    videoNode.identifier = @"video";

    NSDictionary<NSString *, NSString *> *rules = [self rulesForNode:videoNode];

    [videoView applyRules:rules];

    [self setHeroContentBaseRules:videoView rules:rules];
}

- (void)fillImageContainerViewWithHero {
    heroImageView = [BAMSGImageView new];
    heroImageView.image = self.heroImage;
    heroImageView.accessibilityLabel = self.messageDescription.heroDescription;

    [heroImageContainer addSubview:heroImageView];

    BACSSDOMNode *imageNode = [BACSSDOMNode new];
    imageNode.identifier = @"image";
    imageNode.classes = @[ @"image" ];

    NSDictionary<NSString *, NSString *> *rules = [self rulesForNode:imageNode];

    [heroImageView applyRules:rules];

    [self setHeroContentBaseRules:heroImageView rules:rules];

    if (shouldWaitForImage && !self.heroImage) {
        heroLoadingPlaceholder = [BAMSGGradientView new];
        heroLoadingPlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
        [heroImageContainer addSubview:heroLoadingPlaceholder];
        [heroImageContainer
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"|-(0)-[heroLoadingPlaceholder]-(0)-|"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(heroLoadingPlaceholder)]];

        [heroImageContainer
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-(0)-[heroLoadingPlaceholder]-(0)-|"
                                                   options:0
                                                   metrics:nil
                                                     views:NSDictionaryOfVariableBindings(heroLoadingPlaceholder)]];

        heroActivityIndicator =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        heroActivityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
        heroActivityIndicator.hidesWhenStopped = YES;
        [heroActivityIndicator startAnimating];
        [heroImageContainer addSubview:heroActivityIndicator];

        [heroImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:heroActivityIndicator
                                                                       attribute:NSLayoutAttributeCenterX
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:heroImageContainer
                                                                       attribute:NSLayoutAttributeCenterX
                                                                      multiplier:1.0
                                                                        constant:0.0]];

        [heroImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:heroActivityIndicator
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:heroImageContainer
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0.0]];

        BACSSDOMNode *placeholderNode = [BACSSDOMNode new];
        placeholderNode.identifier = @"placeholder";
        NSDictionary<NSString *, NSString *> *placeholderRules = [self rulesForNode:placeholderNode];
        [BAMSGStylableViewHelper applyCommonRules:placeholderRules toView:heroLoadingPlaceholder];

        for (NSString *rule in [placeholderRules allKeys]) {
            NSString *value = placeholderRules[rule];

            if ([@"loader" isEqualToString:rule]) {
                if ([@"light" isEqualToString:value]) {
                    [heroActivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
                } else if ([@"dark" isEqualToString:value]) {
                    [heroActivityIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
                }
            }
        }
    }
}

- (void)setHeroContentBaseRules:(UIView *)heroContent rules:(NSDictionary<NSString *, NSString *> *)rules {
    UIEdgeInsets margin = UIEdgeInsetsZero;
    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterX;
    bool hasWidth = NO;

    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys]) {
        NSString *value = rules[rule];

        // "margin: x x x x" rules have been splitted elsewhere for easier handling
        if ([@"margin-top" isEqualToString:rule]) {
            margin.top = [value floatValue];
        } else if ([@"margin-left" isEqualToString:rule]) {
            margin.left = [value floatValue];
        } else if ([@"margin-right" isEqualToString:rule]) {
            margin.right = [value floatValue];
        } else if ([@"margin-bottom" isEqualToString:rule]) {
            margin.bottom = [value floatValue];
        } else if ([@"align" isEqualToString:rule]) {
            // align: center is not handled as this is the default
            if ([@"left" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeLeft;
            } else if ([@"right" isEqualToString:value]) {
                alignAttr = NSLayoutAttributeRight;
            }
        } else if ([@"width" isEqualToString:rule]) {
            hasWidth = YES;
            NSLayoutConstraint *widthConst = [NSLayoutConstraint constraintWithItem:heroContent
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:[value floatValue]];
            widthConst.priority = UILayoutPriorityRequired;
            [heroContent addConstraint:widthConst];
        } else if ([@"height" isEqualToString:rule]) {
            NSLayoutConstraint *heightConst = [NSLayoutConstraint constraintWithItem:heroContent
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:[value floatValue]];
            heightConst.priority = UILayoutPriorityRequired;
            [heroContent addConstraint:heightConst];
        }
    }

    // Only apply the needed margin if not filled
    float alignAttrMargin = 0;

    if (alignAttr == NSLayoutAttributeLeft) {
        alignAttrMargin = margin.left;
    } else if (alignAttr == NSLayoutAttributeRight) {
        alignAttrMargin = margin.right;
    }

    [heroImageContainer addConstraint:[NSLayoutConstraint constraintWithItem:heroContent
                                                                   attribute:alignAttr
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:heroImageContainer
                                                                   attribute:alignAttr
                                                                  multiplier:1.0
                                                                    constant:alignAttrMargin]];

    // Lower the horizontal margin priority so we can enforce a width/height, only if there's a width set.
    // Otherwise, it breaks images that are set to "fit"
    NSArray<NSLayoutConstraint *> *margins =
        [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(%f)-[heroContent]-(%f)-|",
                                                                                   margin.left, margin.right]
                                                options:0
                                                metrics:nil
                                                  views:NSDictionaryOfVariableBindings(heroContent)];

    margins = [margins
        arrayByAddingObjectsFromArray:
            [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%f)-[heroContent]-(%f)-|",
                                                                                       margin.top, margin.bottom]
                                                    options:0
                                                    metrics:nil
                                                      views:NSDictionaryOfVariableBindings(heroContent)]];

    for (NSLayoutConstraint *constraint in margins) {
        if (hasWidth) {
            constraint.priority = UILayoutPriorityDefaultHigh;
        }
        [heroImageContainer addConstraint:constraint];
    }
}

- (void)fillContentView {
    UIView *topView = nil;

    if (self.headingText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.headingText
                                                 withNodeIdentifier:@"h1"
                                                       previousView:topView];

        [innerContent addItem:item];
        topView = item.view;
    }

    if (self.titleText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.titleText
                                                 withNodeIdentifier:@"h2"
                                                       previousView:topView];

        [innerContent addItem:item];
        topView = item.view;
    }

    if (self.subtitleText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.subtitleText
                                                 withNodeIdentifier:@"h3"
                                                       previousView:topView];

        [innerContent addItem:item];
        topView = item.view;
    }

    // Body text is not optional
    BAMSGStackViewItem *bodyItem = [self labelStackViewItemForLabel:self.bodyText
                                                 withNodeIdentifier:@"body"
                                                       previousView:topView];

    // Default is 250.
    [bodyItem.view setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisVertical];

    if ([self.ctas count] == 0 || self.attachCTAsBottom) {
        bodyItem.attachToParentBottom = YES;
    }

    [innerContent addItem:bodyItem];

    if (!self.attachCTAsBottom) {
        [self addCtasToStackView:innerContent previousView:bodyItem.view];
    }
}

- (void)fillCtasContainer {
    if ([self.ctas count] == 0) {
        return;
    }

    // Instanciate and position the inner view
    innerCtasContainer = [BAMSGStackView new];
    innerCtasContainer.horizontal = self.stackCTAsHorizontally;
    innerCtasContainer.delegate = self;
    innerCtasContainer.translatesAutoresizingMaskIntoConstraints = NO;
    innerCtasContainer.clipsToBounds = YES;
    [ctasContainer addSubview:innerCtasContainer];

    // We want the CTA container to be as small as possible, and let the content view grow.
    [ctasContainer setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                                   forAxis:UILayoutConstraintAxisVertical];
    [ctasContainer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

    BACSSDOMNode *contentNode = [BACSSDOMNode new];
    contentNode.identifier = @"ctas";
    [self applyContainerViewRulesForNode:contentNode
                               innerView:innerCtasContainer
                              parentView:ctasContainer
                     fillHeightByDefault:YES];

    BACSSDOMNode *innerCTANode = [BACSSDOMNode new];
    innerCTANode.identifier = @"ctas-inner";
    [BAMSGStylableViewHelper applyCommonRules:[self rulesForNode:innerCTANode] toView:innerCtasContainer];

    if (self.stackCTAsHorizontally) {
        [self addHorizontalCtasToStackView:innerCtasContainer previousView:nil];

        if (self.stretchCTAsHorizontally) {
            [innerCtasContainer sizeAllItemsEqually];
        }
    } else {
        [self addCtasToStackView:innerCtasContainer previousView:nil];
    }
}

- (void)addCtasToStackView:(BAMSGStackView *)stackView previousView:(UIView *)previousView {
    int i = 1;
    for (BAMSGCTA *cta in self.ctas) {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:cta.label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%d", i]
                                                           previousView:previousView
                                                                    tag:i
                                                             horizontal:stackView.horizontal];

        if (i == [self.ctas count]) {
            ctaItem.attachToParentBottom = YES;
        }

        [stackView addItem:ctaItem];
        previousView = ctaItem.view;
        i++;
    }
}

// Same as addCtasToStackView:previousView: but horizontal CTAs are reversed
- (void)addHorizontalCtasToStackView:(BAMSGStackView *)stackView previousView:(UIView *)previousView {
    int i = (int)self.ctas.count;
    for (BAMSGCTA *cta in [self.ctas reverseObjectEnumerator]) {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:cta.label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%d", i]
                                                           previousView:previousView
                                                                    tag:i
                                                             horizontal:stackView.horizontal];

        if (i == 1) {
            ctaItem.attachToParentBottom = YES;
        }

        [stackView addItem:ctaItem];
        previousView = ctaItem.view;
        i--;
    }
}

- (BAMSGStackViewItem *)labelStackViewItemForLabel:(NSString *)label
                                withNodeIdentifier:(NSString *)nodeIdentifier
                                      previousView:(UIView *)previousView {
    UILabel *labelView = [BAMSGLabel new];
    labelView.numberOfLines = 0;
    labelView.minimumScaleFactor = 0.5;
    labelView.text = label;

    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = nodeIdentifier;
    node.classes = @[ @"text" ];

    BAMSGStackViewItem *item = [BAMSGStackViewItem new];
    item.view = labelView;
    item.rules = [self rulesForNode:node];

    return item;
}

- (BAMSGStackViewItem *)buttonStackViewItemForLabel:(NSString *)label
                                 withNodeIdentifier:(NSString *)nodeIdentifier
                                       previousView:(UIView *)previousView
                                                tag:(NSInteger)tag
                                         horizontal:(BOOL)horizontal {
    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = nodeIdentifier;
    node.classes = @[ @"btn" ];

    BAMSGButton *btnView = [BAMSGButton new];
    [btnView setTitle:label forState:UIControlStateNormal];
    btnView.tag = tag;
    [btnView addTarget:self action:@selector(ctaTapped:) forControlEvents:UIControlEventTouchUpInside];

    BAMSGStackViewItem *item = [BAMSGStackViewItem new];
    item.view = btnView;
    item.rules = [self rulesForNode:node];

    return item;
}

#pragma mark Constraints setup

- (void)setupMainConstraintsWithHeroPortrait {
    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:heroImageContainer
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeHeight
                                                       multiplier:self.heroSplitRatio
                                                         constant:1]];

    NSMutableArray *visualConstraints =
        [NSMutableArray arrayWithObjects:@"|-(0)-[heroImageContainer]-(0)-|", @"|-(0)-[content]-(0)-|",
                                         @"|-(0)-[ctasContainer]-(0)-|", nil];

    // Let the content view eat what's left
    if (!self.flipHeroVertical) {
        [visualConstraints addObject:@"V:|-(0)-[heroImageContainer]-(0)-[content]-(0)-[ctasContainer]-(0)-|"];
    } else {
        [visualConstraints addObject:@"V:|-(0)-[content]-(0)-[heroImageContainer]-(0)-[ctasContainer]-(0)-|"];
    }

    for (NSString *visualConstraint in visualConstraints) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraint
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(
                                                                                             heroImageContainer,
                                                                                             content, ctasContainer)]];
    }

    for (NSLayoutConstraint *constraint in constraints) {
        constraint.identifier = kBAMSGGenericTemplateViewControllerHeroConstraint;
        [self.view addConstraint:constraint];
    }
}

- (void)setupMainConstraintsWithHeroLandscape {
    NSMutableArray *constraints = [NSMutableArray new];

    [constraints addObject:[NSLayoutConstraint constraintWithItem:heroImageContainer
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self.view
                                                        attribute:NSLayoutAttributeWidth
                                                       multiplier:self.heroSplitRatio
                                                         constant:1]];

    NSMutableArray *visualConstraints = [NSMutableArray
        arrayWithObjects:@"V:|-(0)-[heroImageContainer]-(0)-|", @"V:|-(0)-[content]-(0)-[ctasContainer]-(0)-|", nil];

    if (!self.flipHeroHorizontal) {
        [visualConstraints addObject:@"|-(0)-[heroImageContainer]-(0)-[content]-(0)-|"];
        [visualConstraints addObject:@"[heroImageContainer]-(0)-[ctasContainer]-(0)-|"];
    } else {
        [visualConstraints addObject:@"|-(0)-[content]-(0)-[heroImageContainer]-(0)-|"];
        [visualConstraints addObject:@"|-(0)-[ctasContainer]-(0)-[heroImageContainer]"];
    }

    for (NSString *visualConstraint in visualConstraints) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraint
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(
                                                                                             heroImageContainer,
                                                                                             content, ctasContainer)]];
    }

    for (NSLayoutConstraint *constraint in constraints) {
        constraint.identifier = kBAMSGGenericTemplateViewControllerHeroConstraint;
        [self.view addConstraint:constraint];
    }
}

- (void)setupMainConstraintsWithoutHero {
    [self.view addConstraints:[NSLayoutConstraint
                                  constraintsWithVisualFormat:@"V:|-(0)-[content]-(0)-[ctasContainer]-(0)-|"
                                                      options:0
                                                      metrics:nil
                                                        views:NSDictionaryOfVariableBindings(content, ctasContainer)]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[content]-(0)-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(content)]];

    [self.view
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[ctasContainer]-(0)-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:NSDictionaryOfVariableBindings(ctasContainer)]];
}

#pragma mark CTA callbacks

- (void)autoClose {
    if (dismissed) {
        return;
    }

    dismissed = true;
    [self dismissViewControllerAnimated:YES completion:nil];

    [BAMessagingCenter.instance messageAutomaticallyClosed:self.messageDescription];
}

- (void)closeButtonTapped {
    dismissed = true;
    [self dismissViewControllerAnimated:YES completion:nil];

    [BAMessagingCenter.instance messageClosed:self.messageDescription];
}

- (void)ctaTapped:(id)sender {
    dismissed = true;
    [self dismissViewControllerAnimated:YES
                             completion:^{
                               if ([sender isKindOfClass:[UIButton class]]) {
                                   NSInteger ctaID = [(UIButton *)sender tag] - 1;
                                   if (ctaID < [self.ctas count]) {
                                       BAMSGCTA *cta = [self.ctas objectAtIndex:ctaID];
                                       if (!cta) {
                                           return;
                                       }

                                       [BAThreading performBlockOnMainThreadAsync:^{
                                         [BAMessagingCenter.instance messageButtonClicked:self.messageDescription
                                                                                 ctaIndex:ctaID
                                                                                   action:cta.actionIdentifier];

                                         // We don't need to handle BAMSGCTAActionKindClose since we did that earlier
                                         [BAMessagingCenter.instance
                                             performAction:cta
                                                    source:self.messageDescription.sourceMessage];
                                       }];
                                   } else {
                                       [BALogger publicForDomain:@"Messaging"
                                                         message:@"Internal error - A CTA was triggered but something "
                                                                 @"unexpected happened. This shouldn't happen: please "
                                                                 @"report this to Batch support: https://batch.com"];
                                   }
                               } else {
                                   [BALogger publicForDomain:@"Messaging"
                                                     message:@"Internal error - A CTA was triggered but something "
                                                             @"unexpected happened. This shouldn't happen: please "
                                                             @"report this to Batch support: https://batch.com"];
                               }
                             }];
}

#pragma mark BAMSGStackViewDelegate methods

- (nonnull NSString *)separatorPrefixForStackView:(nonnull BAMSGStackView *)stackView {
    if (stackView == innerContent) {
        return @"cnt";
    } else if (stackView == innerCtasContainer) {
        return @"ctas";
    }

    return @"unknown";
}

- (nonnull NSDictionary<NSString *, NSString *> *)stackView:(nonnull BAMSGStackView *)stackView
                                        rulesForSeparatorID:(nonnull NSString *)separatorID {
    BACSSDOMNode *separatorNode = [BACSSDOMNode new];
    separatorNode.identifier = separatorID;
    separatorNode.classes = @[ [NSString stringWithFormat:@"%@-%@", [self separatorPrefixForStackView:stackView],
                                                          (stackView.horizontal ? @"h-sep" : @"sep")] ];

    return [self rulesForNode:separatorNode];
}

@end
