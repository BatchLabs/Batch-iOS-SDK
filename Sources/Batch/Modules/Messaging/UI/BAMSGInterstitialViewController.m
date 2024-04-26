//
//  BAMSGInterstitialViewController.m
//  ViewTest
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGInterstitialViewController.h>

#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAMessagingCenter.h>

#import <Batch/BAMSGButton.h>
#import <Batch/BAMSGCloseButton.h>
#import <Batch/BAMSGGradientView.h>
#import <Batch/BAMSGImageView.h>
#import <Batch/BAMSGLabel.h>
#import <Batch/BAMSGStackViewItem.h>
#import <Batch/BAMSGStylableView.h>
#import <Batch/BAMSGVideoView.h>
#import <Batch/BATGIFAnimator.h>
#import <Batch/BATGIFFile.h>
#import <Batch/BAThreading.h>
#import <Batch/BatchMessagingPrivate.h>

static NSString *kBAMSGInterstitialViewControllerHeroConstraint = @"BAMainHeroConstraint";

@import AVFoundation;

@interface BAMSGInterstitialViewController () <BATGIFAnimatorDelegate> {
    UIImage *_heroImage;

    BAMSGImageView *heroImageContainer;
    BAMSGImageView *heroImageView;
    BAMSGVideoView *videoView;
    BATGIFAnimator *gifAnimator;

    UIView *content;
    BAMSGStackView *innerContent;
    UIView *heroLoadingPlaceholder;
    UIActivityIndicatorView *heroActivityIndicator;
    UIScrollView *bodyLabelWrapper;

    UIView *ctasContainer;
    BAMSGStackView *innerCtasContainer;

    // Is the SDK downloading an image -> Should we display a loader?
    BOOL shouldWaitForImage;
    // Not the same as "shouldWaitForImage", as shouldWaitForImage controls the loader state while this controls if the
    // hero space should be reserved
    BOOL displayHeroContent;

    NSString *previousAudioCategory;

    BOOL viewHierarchyReady;
}

@end

@implementation BAMSGInterstitialViewController

- (instancetype)initWithStyleRules:(nonnull BACSSDocument *)style
                    hasHeroContent:(BOOL)hasHeroContent
                shouldWaitForImage:(BOOL)waitForImage {
    self = [super initWithStyleRules:style];
    if (self) {
        self.ctas = [NSArray new];
        self.attachCTAsBottom = NO;
        self.stackCTAsHorizontally = NO;
        self.stretchCTAsHorizontally = NO;
        self.heroSplitRatio = 0.4;
        self.flipHeroVertical = NO;
        self.flipHeroHorizontal = NO;

        // Set that delegate to make iOS 13's swipe to dismiss listenable
        self.presentationController.delegate = self;
        [self readModalPresentationStyleFromStyle:style];

        displayHeroContent = hasHeroContent;
        shouldWaitForImage = waitForImage;
        viewHierarchyReady = NO;
    }
    return self;
}

- (void)loadView {
    self.view = [BAMSGGradientView new];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    viewHierarchyReady = NO;

    [self setupAudioSession];

    self.view.opaque = YES;

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
        self.closeButton = [BAMSGCloseButton new];

        [self.closeButton addTarget:self
                             action:@selector(closeButtonAction)
                   forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:self.closeButton];

        [self applyCloseButtonRules];
    }

    BACSSDOMNode *contentNode = [BACSSDOMNode new];
    contentNode.identifier = @"content";
    if ([self.ctas count] > 0) {
        if (self.attachCTAsBottom) {
            contentNode.classes = @[ @"detached_ctas" ];
        } else {
            contentNode.classes = @[ @"attached_ctas" ];
        }
    } else {
        contentNode.classes = @[ @"no_ctas" ];
    }

    [self applyContainerViewRulesForNode:contentNode innerView:innerContent parentView:content fillHeightByDefault:NO];

    [self fillContentView];

    viewHierarchyReady = YES;
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

    [gifAnimator startAnimating];
    [videoView viewDidAppear];

    [bodyLabelWrapper flashScrollIndicators];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [gifAnimator stopAnimating];
    [videoView viewDidDisappear];
    [self tearDownAudioSession];
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
            if ([constraint.identifier isEqualToString:kBAMSGInterstitialViewControllerHeroConstraint]) {
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

- (void)readModalPresentationStyleFromStyle:(nonnull BACSSDocument *)style API_AVAILABLE(ios(13.0)) {
    BACSSDOMNode *rootContainerNode = [BACSSDOMNode new];
    rootContainerNode.identifier = @"root";
    BACSSRules *rootRules = [style flatRulesForNode:rootContainerNode withEnvironment:[self computeCSSEnvironment]];

    NSString *presentationString = rootRules[@"modal-presentation"];

    if ([presentationString length] > 0) {
        NSInteger presentationStyle = self.modalPresentationStyle;
        if ([presentationString isEqualToString:@"default"]) {
            return;
        } else if ([presentationString isEqualToString:@"auto"]) {
            presentationStyle = UIModalPresentationAutomatic;
        } else if ([presentationString isEqualToString:@"over-fullscreen"]) {
            presentationStyle = UIModalPresentationOverFullScreen;
        } else if ([presentationString isEqualToString:@"fullscreen"]) {
            presentationStyle = UIModalPresentationFullScreen;
        } else if ([presentationString isEqualToString:@"over-current-context"]) {
            presentationStyle = UIModalPresentationOverCurrentContext;
        } else if ([presentationString isEqualToString:@"current-context"]) {
            presentationStyle = UIModalPresentationCurrentContext;
        } else if ([presentationString isEqualToString:@"page-sheet"]) {
            presentationStyle = UIModalPresentationPageSheet;
        }

        self.modalPresentationStyle = presentationStyle;
    }
}

#pragma mark Public (non-lifecycle) methos

- (BOOL)canBeClosed {
    return self.showCloseButton || [self.ctas count] > 0 || self.autoclosingDuration > 0;
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

- (void)didFinishLoadingGIFHero:(nullable NSData *)gifData {
    if (gifData == nil) {
        return;
    }

    __weak BAMSGInterstitialViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      NSError *err = nil;
      BATGIFFile *gifFile = [[BATGIFFile alloc] initWithData:gifData error:&err];

      if (gifFile == nil) {
          [BALogger debugForDomain:@"Messaging"
                           message:@"Could not load gif file: (%ld) %@", (long)(err ? err.code : 0),
                                   err ? err.localizedDescription : @"unknown"];
          // Try to fall back on a static UIImage
          UIImage *img = [UIImage imageWithData:gifData];
          if (img != nil) {
              [weakSelf didFinishLoadingHero:img];
          }
          return;
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        BAMSGInterstitialViewController *strongSelf = weakSelf;
        if (strongSelf) {
            // Prevents the loader from showing if the hero failed to load (nil image) but the view hasn't been
            // constructed yet
            strongSelf->shouldWaitForImage = NO;

            [strongSelf->heroActivityIndicator stopAnimating];
            [strongSelf->heroActivityIndicator removeFromSuperview];
            [strongSelf->heroLoadingPlaceholder removeFromSuperview];

            BATGIFAnimator *animator = [[BATGIFAnimator alloc] initWithFile:gifFile];
            animator.delegate = strongSelf;
            strongSelf->gifAnimator = animator;
            [animator startAnimating];
        }
      });
    });
}

#pragma mark GIF Animator delegate methods

- (void)animator:(BATGIFAnimator *)animator needsToDisplayImage:(UIImage *)image {
    // Don't use setHeroImage, we only want this to be set on the heroImage, not the container
    // That means that blurring won't be supported on GIFs, but it would be tough to maintain
    // performance on that anyway
    heroImageView.image = image;
}

#pragma mark Layouting

- (BOOL)shouldShowHeroView {
    return displayHeroContent;
}

- (void)applyCloseButtonRules {
    BACSSDOMNode *closeNode = [BACSSDOMNode new];
    closeNode.identifier = @"close";

    BACSSRules *rules = [self rulesForNode:closeNode];

    [self.closeButton applyRules:rules];

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
            [constraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];

            [constraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
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

    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:alignAttr
                                                              relatedBy:alignRelation
                                                                 toItem:self.view
                                                              attribute:alignAttr
                                                             multiplier:1.0
                                                               constant:alignAttrMargin]];

    // Top margin
    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:margin.top]];

    // Add low priority safe area constraints. Padding will win over it.
    if (alignAttr == NSLayoutAttributeLeft) {
        alignAttrMargin = safeAreaMargin.left;
    } else if (alignAttr == NSLayoutAttributeRight) {
        alignAttrMargin = safeAreaMargin.right;
    }

    UILayoutGuide *safeGuide = self.view.safeAreaLayoutGuide;
    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:safeGuide
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:safeAreaMargin.top]];
    [marginConstraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                              attribute:alignAttr
                                                              relatedBy:alignRelation
                                                                 toItem:safeGuide
                                                              attribute:alignAttr
                                                             multiplier:1.0
                                                               constant:alignAttrMargin]];

    [NSLayoutConstraint activateConstraints:marginConstraints];

    [self.view addConstraints:constraints];
}

- (void)applyContainerViewRulesForNode:(BACSSDOMNode *)node
                             innerView:(UIView *)innerView
                            parentView:(UIView *)parentView
                   fillHeightByDefault:(BOOL)defaultFillHeight {
    BACSSRules *rules = [self rulesForNode:node];

    [BAMSGStylableViewHelper applyCommonRules:rules toView:parentView];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray new];

    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterY;
    UIEdgeInsets padding = UIEdgeInsetsZero;
    BOOL heightApplied = NO;
    BOOL maxMinHeightApplied = NO;
    BOOL wantsHeightFilled = defaultFillHeight;

    BOOL useSafeArea = NO;
    BOOL usePaddingForSafeArea = NO;
    float safeAreaPriority = 1000;
    BOOL fitToSafeArea = true;

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
        } else if ([@"safe-area-priority" isEqualToString:rule]) {
            if (![@"default" isEqualToString:value]) {
                safeAreaPriority = MAX(0, MIN(1000, [value floatValue]));
            }
        }
        // Controls how the safe area will be used
        //  - default means that the view will be asked to hug the safe area (with padding or not)
        //  - loose means that the view can't cross the safe area, but can be smaller
        else if ([@"safe-area-fit" isEqualToString:rule]) {
            if ([@"default" isEqualToString:value]) {
                fitToSafeArea = true;
            } else if ([@"loose" isEqualToString:value]) {
                fitToSafeArea = false;
            }
        }
    }

    BOOL addedSafeAreaConstraints = NO;

    if (useSafeArea) {
        UILayoutGuide *safeGuide = parentView.safeAreaLayoutGuide;
        NSMutableArray<NSLayoutConstraint *> *safeLayoutConstraints = [NSMutableArray new];
        [safeLayoutConstraints
            addObject:[NSLayoutConstraint
                          constraintWithItem:innerView
                                   attribute:NSLayoutAttributeTop
                                   relatedBy:fitToSafeArea ? NSLayoutRelationEqual : NSLayoutRelationGreaterThanOrEqual
                                      toItem:safeGuide
                                   attribute:NSLayoutAttributeTop
                                  multiplier:1.0
                                    constant:usePaddingForSafeArea ? padding.top : 0]];
        [safeLayoutConstraints
            addObject:[NSLayoutConstraint
                          constraintWithItem:innerView
                                   attribute:NSLayoutAttributeBottom
                                   relatedBy:fitToSafeArea ? NSLayoutRelationEqual : NSLayoutRelationLessThanOrEqual
                                      toItem:safeGuide
                                   attribute:NSLayoutAttributeBottom
                                  multiplier:1.0
                                    constant:usePaddingForSafeArea ? -padding.bottom : 0]];
        [safeLayoutConstraints
            addObject:[NSLayoutConstraint
                          constraintWithItem:innerView
                                   attribute:NSLayoutAttributeLeft
                                   relatedBy:fitToSafeArea ? NSLayoutRelationEqual : NSLayoutRelationGreaterThanOrEqual
                                      toItem:safeGuide
                                   attribute:NSLayoutAttributeLeft
                                  multiplier:1.0
                                    constant:usePaddingForSafeArea ? padding.left : 0]];
        [safeLayoutConstraints
            addObject:[NSLayoutConstraint
                          constraintWithItem:innerView
                                   attribute:NSLayoutAttributeRight
                                   relatedBy:fitToSafeArea ? NSLayoutRelationEqual : NSLayoutRelationLessThanOrEqual
                                      toItem:safeGuide
                                   attribute:NSLayoutAttributeRight
                                  multiplier:1.0
                                    constant:usePaddingForSafeArea ? -padding.right : 0]];
        for (NSLayoutConstraint *c in safeLayoutConstraints) {
            c.priority = safeAreaPriority;
        }
        [NSLayoutConstraint activateConstraints:safeLayoutConstraints];
        addedSafeAreaConstraints = YES;
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
            hAlignView = parentView.safeAreaLayoutGuide;
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
        if (fitToSafeArea) {
            [constraints
                addObjectsFromArray:
                    [NSLayoutConstraint
                        constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(>=%f)-[innerView]-(>=%f)-|",
                                                                               padding.left, padding.right]
                                            options:0
                                            metrics:nil
                                              views:NSDictionaryOfVariableBindings(innerView)]];
        } else {
            [constraints
                addObjectsFromArray:
                    [NSLayoutConstraint
                        constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(%f@700)-[innerView]-(%f@700)-|",
                                                                               padding.left, padding.right]
                                            options:0
                                            metrics:nil
                                              views:NSDictionaryOfVariableBindings(innerView)]];
        }

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

    BACSSRules *rules = [self rulesForNode:videoNode];

    [videoView applyRules:rules];

    [self setHeroContentBaseRules:videoView rules:rules];
}

- (void)fillImageContainerViewWithHero {
    heroImageView = [BAMSGImageView new];
    heroImageView.image = self.heroImage;
    if (![BANullHelper isStringEmpty:self.messageDescription.heroDescription]) {
        heroImageView.accessibilityLabel = self.messageDescription.heroDescription;
        heroImageView.isAccessibilityElement = true;
    }

    [heroImageContainer addSubview:heroImageView];

    BACSSDOMNode *imageNode = [BACSSDOMNode new];
    imageNode.identifier = @"image";
    imageNode.classes = @[ @"image" ];

    BACSSRules *rules = [self rulesForNode:imageNode];

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
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        heroActivityIndicator.color = [UIColor whiteColor];
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
        BACSSRules *placeholderRules = [self rulesForNode:placeholderNode];
        [BAMSGStylableViewHelper applyCommonRules:placeholderRules toView:heroLoadingPlaceholder];

        for (NSString *rule in [placeholderRules allKeys]) {
            NSString *value = placeholderRules[rule];

            if ([@"loader" isEqualToString:rule]) {
                if ([@"light" isEqualToString:value]) {
                    heroActivityIndicator.color = [UIColor whiteColor];
                } else if ([@"dark" isEqualToString:value]) {
                    heroActivityIndicator.color = [UIColor grayColor];
                }
            }
        }
    }
}

- (void)setHeroContentBaseRules:(UIView *)heroContent rules:(BACSSRules *)rules {
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
    if (self.headingText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.headingText withNodeIdentifier:@"h1"];

        [innerContent addItem:item];
    }

    if (self.titleText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.titleText withNodeIdentifier:@"h2"];

        [innerContent addItem:item];
    }

    if (self.subtitleText) {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.subtitleText withNodeIdentifier:@"h3"];

        [innerContent addItem:item];
    }

    // Body text is not optional
    // We could use the "labelStackViewItemForLabel" method but we need HTML support
    // and we need to wrap it in a scrollview
    BACSSDOMNode *bodyNode = [BACSSDOMNode new];
    bodyNode.identifier = @"body";
    bodyNode.classes = @[ @"text" ];
    BACSSRules *bodyNodeRules = [self rulesForNode:bodyNode];

    BAMSGLabel *bodyLabelView = [BAMSGLabel new];
    bodyLabelView.numberOfLines = 0;
    bodyLabelView.minimumScaleFactor = 0.5;
    bodyLabelView.translatesAutoresizingMaskIntoConstraints = false;
    [bodyLabelView setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisVertical];
    [bodyLabelView applyRules:bodyNodeRules];

    bodyLabelWrapper = [UIScrollView new];
    bodyLabelWrapper.translatesAutoresizingMaskIntoConstraints = false;
    [bodyLabelWrapper setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisVertical];
    [bodyLabelWrapper addSubview:bodyLabelView];

    NSLayoutConstraint *scrollSizeConstraint = [NSLayoutConstraint constraintWithItem:bodyLabelWrapper
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                               toItem:bodyLabelView
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:1
                                                                             constant:0];
    scrollSizeConstraint.priority = 250;
    [bodyLabelWrapper addConstraint:scrollSizeConstraint];

    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1
                                                                  constant:0]];
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeTrailing
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1
                                                                  constant:0]];
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1
                                                                  constant:0]];
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0]];
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1
                                                                  constant:0]];

    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                    toItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1
                                                                  constant:0]];

    BAMSGStackViewItem *bodyWrapperItem = [BAMSGStackViewItem new];
    bodyWrapperItem.view = bodyLabelWrapper;
    // The wrapper uses the body label layouting rules
    bodyWrapperItem.rules = bodyNodeRules;

    if (self.bodyHtml != nil) {
        [bodyLabelView setText:self.bodyHtml.text transforms:self.bodyHtml.transforms];
    } else {
        bodyLabelView.text = self.bodyText;
    }

    if ([self.ctas count] == 0 || self.attachCTAsBottom) {
        bodyWrapperItem.attachToParentBottom = YES;
    }

    [innerContent addItem:bodyWrapperItem];

    if (!self.attachCTAsBottom) {
        [self addCtasToStackView:innerContent];
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
        [self addHorizontalCtasToStackView:innerCtasContainer];

        if (self.stretchCTAsHorizontally) {
            [innerCtasContainer sizeAllItemsEqually];
        }
    } else {
        [self addCtasToStackView:innerCtasContainer];
    }
}

- (void)addCtasToStackView:(BAMSGStackView *)stackView {
    int i = 1;
    for (BAMSGCTA *cta in self.ctas) {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:cta.label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%d", i]
                                                                    tag:i
                                                             horizontal:stackView.horizontal];

        if (i == [self.ctas count]) {
            ctaItem.attachToParentBottom = YES;
        }

        [stackView addItem:ctaItem];
        i++;
    }
}

// Same as addCtasToStackView:previousView: but horizontal CTAs are reversed
- (void)addHorizontalCtasToStackView:(BAMSGStackView *)stackView {
    int i = (int)self.ctas.count;
    for (BAMSGCTA *cta in [self.ctas reverseObjectEnumerator]) {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:cta.label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%d", i]
                                                                    tag:i
                                                             horizontal:stackView.horizontal];

        if (i == 1) {
            ctaItem.attachToParentBottom = YES;
        }

        [stackView addItem:ctaItem];
        i--;
    }
}

- (BAMSGStackViewItem *)labelStackViewItemForLabel:(NSString *)label withNodeIdentifier:(NSString *)nodeIdentifier {
    UILabel *labelView = [BAMSGLabel new];
    labelView.numberOfLines = 0;
    labelView.minimumScaleFactor = 0.5;

    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = nodeIdentifier;
    node.classes = @[ @"text" ];

    BAMSGStackViewItem *item = [BAMSGStackViewItem new];
    item.view = labelView;
    item.rules = [self rulesForNode:node];

    // Setting the text after the rules saves a setText execution
    labelView.text = label;

    return item;
}

- (BAMSGStackViewItem *)buttonStackViewItemForLabel:(NSString *)label
                                 withNodeIdentifier:(NSString *)nodeIdentifier
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
        constraint.identifier = kBAMSGInterstitialViewControllerHeroConstraint;
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
        constraint.identifier = kBAMSGInterstitialViewControllerHeroConstraint;
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

- (void)ctaTapped:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        NSInteger ctaID = [(UIButton *)sender tag] - 1;
        [self performCtaAtIndex:ctaID];
    } else {
        [BALogger publicForDomain:@"Messaging"
                          message:@"Internal error - A CTA was triggered but something unexpected happened. This "
                                  @"shouldn't happen: please report this to Batch support: https://batch.com"];
    }
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

- (nonnull BACSSRules *)stackView:(nonnull BAMSGStackView *)stackView
              rulesForSeparatorID:(nonnull NSString *)separatorID {
    BACSSDOMNode *separatorNode = [BACSSDOMNode new];
    separatorNode.identifier = separatorID;
    separatorNode.classes = @[ [NSString stringWithFormat:@"%@-%@", [self separatorPrefixForStackView:stackView],
                                                          (stackView.horizontal ? @"h-sep" : @"sep")] ];

    return [self rulesForNode:separatorNode];
}

#pragma mark - Parent

- (BAMSGMessage *)message {
    return self.messageDescription;
}

#pragma mark - Dismissal

- (BAPromise *)doDismiss {
    return [self _doDismissSelfModal];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    return self.modalPresentationStyle;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    [self userDidCloseMessage];
}

@end
