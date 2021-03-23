#import <Batch/BAMSGBannerViewController.h>

#import <Batch/BAMessagingCenter.h>
#import <Batch/BAEventDispatcherCenter.h>

#import <Batch/BAMSGStackViewItem.h>
#import <Batch/BAMSGLabel.h>
#import <Batch/BAMSGButton.h>
#import <Batch/BAMSGCloseButton.h>
#import <Batch/BAMSGStylableView.h>
#import <Batch/BAMSGRemoteImageView.h>
#import <Batch/BAThreading.h>
#import <Batch/BAMSGGradientView.h>
#import <Batch/BAMSGVideoView.h>
#import <Batch/BAMSGPannableAnchoredContainerView.h>
#import <Batch/BAMSGPannableAlertContainerView.h>
#import <Batch/BAMSGCountdownView.h>
#import <Batch/BAUptimeProvider.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BatchMessagingPrivate.h>

static NSString *kBAMSGInterstitialViewControllerHeroConstraint = @"BAMainHeroConstraint";

@import AVFoundation;

@interface BAMSGBaseBannerViewController ()
{
    BAMSGCountdownView *countdownView;
    BAMSGRemoteImageView *imageView;
    
    UIView *content;
    BAMSGStackView *innerContent;
    UIScrollView *bodyLabelWrapper;
    
    UIView *ctasContainer;
    BAMSGStackView *innerCtasContainer;
    
    BOOL viewHierarchyReady;
    
    BAMSGPannableAnchoredContainerVerticalAnchor panAnchor;
    
    // Device uptime at which the view was last presented, useful for global tap delay
    NSTimeInterval lastViewAppearanceUptime;
}

@end

@implementation BAMSGBaseBannerViewController

- (instancetype)initWithStyleRules:(nonnull BACSSDocument*)style
{
    self = [super initWithStyleRules:style];
    if (self)
    {
        self.ctas = [NSArray new];
        self.ctaStackDirection = BAMSGBannerCTADirectionHorizontal;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.globalTapAction = nil;
        self.allowSwipeToDismiss = YES;
        
        viewHierarchyReady = NO;
        panAnchor = BAMSGPannableAnchoredContainerVerticalAnchorOther;
        lastViewAppearanceUptime = 0;
    }
    return self;
}

- (void)loadView {
    self.view = [BAMSGBaseContainerView new];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Skip the setup here, as the trait collection change will trigger that
    [self setupViewContents];
}

- (void)setupViewContents {
    if (content != nil) {
        // View has already been setup, skip
        // Use this to work around a "bug" (or at least weird iOS behaviour) where willTransitionToTraitCollection
        // can be called on first appearance but not in every case
        return;
    }
    
    viewHierarchyReady = NO;
    
    self.view.opaque = NO;
    
    content = [self makeContentView];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content];
    if ([self.view isKindOfClass:[BAMSGPannableAnchoredContainerView class]]) {
        [(BAMSGPannableAnchoredContainerView*)self.view setBiggestUserVisibleView:content];
    }
    
    innerContent = [BAMSGStackView new];
    innerContent.delegate = self;
    innerContent.translatesAutoresizingMaskIntoConstraints = NO;
    innerContent.clipsToBounds = YES;
    [content addSubview:innerContent];
    
    [self applyMainContainerViewRules];
    
    if (self.showCloseButton)
    {
        self.closeButton = [BAMSGCloseButton new];
        
        [self.closeButton addTarget:self
                        action:@selector(closeButtonAction)
              forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:self.closeButton];
        
        [self linkViewToPannableContainer:self.closeButton];
        
        [self applyCloseButtonRulesForContentView:content
                                       parentView:self.view];
    }
    
    BACSSDOMNode *contentNode = [BACSSDOMNode new];
    contentNode.identifier = @"content";
    [self applyContainerViewRulesForNode:contentNode
                               innerView:innerContent
                              parentView:content
                       shouldUseTopGuide:panAnchor == BAMSGPannableAnchoredContainerVerticalAnchorTop];
    
    [self fillInnerContentView];
    
    if (self.closeButton != nil) {
        [self.view bringSubviewToFront:self.closeButton];
    }
    
    viewHierarchyReady = YES;
}

- (UIView*)makeContentView
{
    return [BAMSGBaseContainerView new];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.globalTapDelay > 0) {
        lastViewAppearanceUptime = [BAUptimeProvider uptime];
    }
    
    [bodyLabelWrapper flashScrollIndicators];
    
    [[BANotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batchMessageDidAppearNotification:)
                                                 name:kBATMessagingMessageDidAppear
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[BANotificationCenter defaultCenter] removeObserver:self
                                                    name:kBATMessagingMessageDidAppear
                                                  object:nil];
}

/**
 Tries to guess which VC we're drawing over
 */
- (UIViewController *)guessOverlayedViewController
{
    UIViewController *rootVC = self.overlayedWindow.rootViewController;
    UIViewController *guessedVC;
    guessedVC = rootVC.presentedViewController;
    if (guessedVC == nil) {
        guessedVC = rootVC;
    }
    if (![guessedVC isKindOfClass:[UIViewController class]]) {
        return nil;
    }
    return guessedVC;
}

- (BOOL)prefersStatusBarHidden
{
    return false;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.overridenStatusBarStyle ? nil : [self guessOverlayedViewController];
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.overridenStatusBarStyle ? nil : [self guessOverlayedViewController];
}

- (BOOL)shouldAutorotate
{
    UIViewController *childVC = [self guessOverlayedViewController];
    if ([childVC respondsToSelector:@selector(shouldAutorotate)]) {
        return [childVC shouldAutorotate];
    }
    return true;
}

- (BOOL)shouldDisplayInSeparateWindow
{
    return true;
}

- (void)reconstructContentView
{
    [(BAMSGBaseContainerView*)self.view removeAllSubviews];
    content = nil;
    [self setupRootStyle];
    [self setupViewContents];
    // Update autoclosing animation
    [self doAnimateAutoclosing];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
 
    // On a trait collection change, just throw the views away and reconstruct them from the CSS.
    // That's kinda like Android, and may not seem performant, but trust me: recomputing what changed and swapping constraints
    // would be MUCH more complicated
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self reconstructContentView];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
    }];
}

- (void)batchMessageDidAppearNotification:(NSNotification*)notification
{
    if ([notification.object isKindOfClass:[BAMSGMessageInterstitial class]]) {
        // Dismiss the banner if a fullscreen template comes on screen
        [self dismiss];
    }
}

#pragma mark Public (non-lifecycle) methos

- (BOOL)canBeClosed
{
    return self.showCloseButton || [self.ctas count] > 0 || self.autoclosingDuration > 0;
}

#pragma mark Layouting

- (void)linkViewToPannableContainer:(UIView*)view
{
    if ([content isKindOfClass:[BAMSGPannableAlertContainerView class]])
    {
        [(BAMSGPannableAlertContainerView*)content setLinkedView:view];
    }
}

/**
 Apply the close button positionment and style rules according to the content view (used for positioning)
 and the parent view (used to set the constraints on)
 
 The content view must be in the parent view too
 */
- (void)applyCloseButtonRulesForContentView:(UIView*)contentView
                                 parentView:(UIView*)parentView
{
    BACSSDOMNode *closeNode = [BACSSDOMNode new];
    closeNode.identifier = @"close";
    
    BACSSRules* rules = [self rulesForNode:closeNode];
    
    [self.closeButton applyRules:rules];
    
    NSMutableArray<NSLayoutConstraint*>* constraints = [NSMutableArray new];
    
    NSLayoutAttribute alignAttr = NSLayoutAttributeRight;
    UIEdgeInsets margin = UIEdgeInsetsZero;
    
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        // "margin: x x x x" rules have been splitted elsewhere for easier handling
        if ([@"margin-top" isEqualToString:rule])
        {
            margin.top = [value floatValue];
        }
        else if ([@"margin-left" isEqualToString:rule])
        {
            margin.left = [value floatValue];
        }
        else if ([@"margin-right" isEqualToString:rule])
        {
            // Right margins are negative with Auto Layout
            margin.right = -[value floatValue];
        }
        else if ([@"size" isEqualToString:rule])
        {
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
        }
        else if ([@"align" isEqualToString:rule])
        {
            //align: right is not handled as this is the default
            if ([@"left" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeLeft;
            }
            else if ([@"center" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeCenterX;
            }
        }
    }
    
    // Only apply the needed margin if not filled
    float alignAttrMargin = 0;
    
    if (alignAttr == NSLayoutAttributeLeft)
    {
        alignAttrMargin = margin.left;
    }
    else if (alignAttr == NSLayoutAttributeRight)
    {
        alignAttrMargin = margin.right;
    }
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                        attribute:alignAttr
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:innerContent
                                                        attribute:alignAttr
                                                       multiplier:1.0
                                                         constant:alignAttrMargin]];
    
    // Top margin
    [constraints addObject:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                        attribute:NSLayoutAttributeTop
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:innerContent
                                                        attribute:NSLayoutAttributeTop
                                                       multiplier:1.0
                                                         constant:margin.top]];
    
    [parentView addConstraints:constraints];
}

/**
 Apply an absolute positionment and style rules on a view according to its parent view
 
 The view must be in the parent view
 */
- (void)applyAbsolutePositionmentRulesForView:(id<BAMSGStylableView>)view
                                         node:(BACSSDOMNode*)node
                                   parentView:(UIView*)parentView
{
    BACSSRules* rules = [self rulesForNode:node];
    
    [view applyRules:rules];
    
    NSMutableArray<NSLayoutConstraint*>* constraints = [NSMutableArray new];
    
    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterY;
    NSLayoutAttribute hAlignAttr = NSLayoutAttributeCenterX;
    UIEdgeInsets margin = UIEdgeInsetsZero;
    BOOL fillsHeight = NO;
    BOOL maxMinHeightApplied = NO;
    BOOL widthApplied = NO;
    BOOL maxMinWidthApplied = NO;
    BOOL marginUseSafeArea = NO;
    
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        if ([@"z-index" isEqualToString:rule])
        {
            if ([@"back" isEqualToString:value]) {
                [parentView sendSubviewToBack:(UIView*)view];
            } else if ([@"front" isEqualToString:value]) {
                [parentView bringSubviewToFront:(UIView*)view];
            }
        }
        else if ([@"margin-top" isEqualToString:rule])
        {
            margin.top = [value floatValue];
        }
        else if ([@"margin-bottom" isEqualToString:rule])
        {
            margin.bottom = [value floatValue];
        }
        else if ([@"margin-left" isEqualToString:rule])
        {
            margin.left = [value floatValue];
        }
        else if ([@"margin-right" isEqualToString:rule])
        {
            margin.right = [value floatValue];
        }
        else if ([@"margin-uses-safe-area" isEqualToString:rule])
        {
            marginUseSafeArea = [value boolValue];
        }
        else if ([@"height" isEqualToString:rule])
        {
            if (maxMinHeightApplied) { continue; }
            
            if ([@"100%" isEqualToString:value] && parentView != nil)
            {
                fillsHeight = YES;
                
                [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:content
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1.0
                                                                     constant:0]];
            }
            else if ([@"fill" isEqualToString:value] && parentView != nil)
            {
                fillsHeight = YES;
                // Not really elegant, yeah.
                // We need to do that so that autolayout does not go nuts and lets the intrisic content size push the image fullscreen
                if ([view isKindOfClass:[BAMSGImageView class]]) {
                    ((BAMSGImageView*)view).enableIntrinsicContentSize = NO;
                }
                
                [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:content
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0
                                                                     constant:0]];
                [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:content
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:0]];
            }
            else if (![@"auto" isEqualToString:value])
            {
                NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                               attribute:NSLayoutAttributeHeight
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:[value floatValue]];
                hConstraint.priority = 800;
                [constraints addObject:hConstraint];
            }
        }
        else if ([@"width" isEqualToString:rule])
        {
            if (maxMinWidthApplied) { continue; }
            
            if (![@"auto" isEqualToString:value])
            {
                widthApplied = YES;
                NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:view
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:[value floatValue]];
                hConstraint.priority = 800;
                [constraints addObject:hConstraint];
            }
        }
        else if ([@"max-width" isEqualToString:rule])
        {
            if (widthApplied) { continue; }
            maxMinWidthApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"min-width" isEqualToString:rule])
        {
            if (widthApplied) { continue; }
            maxMinWidthApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:view
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"vertical-align" isEqualToString:rule])
        {
            //align: center is not handled as this is the default
            if ([@"top" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeTop;
            }
            else if ([@"bottom" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeBottom;
            }
            else if ([@"center" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeCenterY;
            }
        }
        else if ([@"align" isEqualToString:rule])
        {
            //align: center is not handled as this is the default
            if ([@"left" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeLeft;
            }
            else if ([@"right" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeRight;
            }
            else if ([@"center" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeCenterX;
            }
        }
    }
    
    NSLayoutAttribute matchingAlignAttr = alignAttr;
    id alignView;
    if (marginUseSafeArea != 0) {
        if (@available(iOS 11.0, *)) {
            alignView = parentView.safeAreaLayoutGuide;
        } else if (alignAttr == NSLayoutAttributeTop) {
            alignView = self.topLayoutGuide;
            matchingAlignAttr = NSLayoutAttributeBottom;
        } else {
            alignView = parentView;
        }
    } else {
        alignView = parentView;
    }
    
    // Vertical alignment
    
    if (!fillsHeight) {
        // Only apply the needed padding if not filled
        float alignAttrPadding = 0;
        
        if (alignAttr == NSLayoutAttributeTop)
        {
            alignAttrPadding = margin.top;
        }
        else if (alignAttr == NSLayoutAttributeBottom)
        {
            // Autolayout uses negative values when not using the visual syntax
            alignAttrPadding = -margin.bottom;
        }
        
        NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:view
                                                             attribute:alignAttr
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:alignView
                                                             attribute:matchingAlignAttr
                                                            multiplier:1.0
                                                              constant:alignAttrPadding];
        // Use a lower priority than the main padding constraint
        c.priority = 850;
        
        [constraints addObject:c];
    }
    
    
    // Horizontal alignment
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(>=%f@1000)-[view]-(>=%f@1000)-|", margin.left, margin.right]
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(view)]];
    
    if (!widthApplied) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(==%f@600)-[view]-(==%f@600)-|", margin.left, margin.right]
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(view)]];
    }
    
    float hAlignAttrPadding = 0;
    
    if (hAlignAttr == NSLayoutAttributeLeft)
    {
        hAlignAttrPadding = margin.left;
    }
    else if (hAlignAttr == NSLayoutAttributeRight)
    {
        hAlignAttrPadding = margin.right;
    }
    
    NSLayoutConstraint *vc = [NSLayoutConstraint constraintWithItem:view
                                                          attribute:hAlignAttr
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:alignView
                                                          attribute:hAlignAttr
                                                         multiplier:1.0
                                                           constant:hAlignAttrPadding];
    
    [constraints addObject:vc];
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)applyMainContainerViewRules
{
    UIView *parentView = self.view;
    UIView *innerView = content;
    
    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = @"content";
    BACSSRules* rules = [self rulesForNode:node];
    
    NSMutableArray<NSLayoutConstraint*>* constraints = [NSMutableArray new];
    
    NSLayoutAttribute alignAttr = NSLayoutAttributeCenterY;
    NSLayoutAttribute hAlignAttr = NSLayoutAttributeCenterX;
    UIEdgeInsets margin = UIEdgeInsetsZero;
    BOOL heightApplied = NO;
    BOOL maxMinHeightApplied = NO;
    BOOL widthApplied = NO;
    BOOL maxMinWidthApplied = NO;
    
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        if ([@"margin-top" isEqualToString:rule])
        {
            margin.top = [value floatValue];
        }
        else if ([@"margin-bottom" isEqualToString:rule])
        {
            margin.bottom = [value floatValue];
        }
        else if ([@"margin-left" isEqualToString:rule])
        {
            margin.left = [value floatValue];
        }
        else if ([@"margin-right" isEqualToString:rule])
        {
            margin.right = [value floatValue];
        }
        else if ([@"height" isEqualToString:rule])
        {
            if (maxMinHeightApplied) { continue; }
            
            if (![@"auto" isEqualToString:value])
            {
                heightApplied = YES;
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
        }
        else if ([@"max-height" isEqualToString:rule])
        {
            if (heightApplied) { continue; }
            maxMinHeightApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"min-height" isEqualToString:rule])
        {
            if (heightApplied) { continue; }
            maxMinHeightApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"width" isEqualToString:rule])
        {
            if (maxMinWidthApplied) { continue; }
            
            if (![@"auto" isEqualToString:value])
            {
                widthApplied = YES;
                NSLayoutConstraint *hConstraint = [NSLayoutConstraint constraintWithItem:innerView
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0
                                                                                constant:[value floatValue]];
                hConstraint.priority = 800;
                [constraints addObject:hConstraint];
            }
        }
        else if ([@"max-width" isEqualToString:rule])
        {
            if (widthApplied) { continue; }
            maxMinWidthApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationLessThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"min-width" isEqualToString:rule])
        {
            if (widthApplied) { continue; }
            maxMinWidthApplied = YES;
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:[value floatValue]]];
        }
        else if ([@"vertical-align" isEqualToString:rule])
        {
            //align: center is not handled as this is the default
            if ([@"top" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeTop;
            }
            else if ([@"bottom" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeBottom;
            }
            else if ([@"center" isEqualToString:value])
            {
                alignAttr = NSLayoutAttributeCenterY;
            }
        }
        else if ([@"align" isEqualToString:rule])
        {
            //align: center is not handled as this is the default
            if ([@"left" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeLeft;
            }
            else if ([@"right" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeRight;
            }
            else if ([@"center" isEqualToString:value])
            {
                hAlignAttr = NSLayoutAttributeCenterX;
            }
        }
    }
    
    // Padding goes before everything
    [parentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(>=%f@1000)-[innerView]-(>=%f@1000)-|", margin.top, margin.bottom]
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(innerView)]];
    
    // Vertical alignment
    
    // Tell the pannable container about the vertical align
    if ([self.view isKindOfClass:[BAMSGPannableAnchoredContainerView class]]) {
        switch (alignAttr) {
            case NSLayoutAttributeTop:
                panAnchor = BAMSGPannableAnchoredContainerVerticalAnchorTop;
                break;
            case NSLayoutAttributeBottom:
                panAnchor = BAMSGPannableAnchoredContainerVerticalAnchorBottom;
                break;
            default:
                panAnchor = BAMSGPannableAnchoredContainerVerticalAnchorOther;
                break;
        }
        [(BAMSGPannableAnchoredContainerView*)self.view setVerticalAnchor:panAnchor];
    }
    
    // Only apply the needed padding if not filled
    float alignAttrPadding = 0;
    
    if (alignAttr == NSLayoutAttributeTop)
    {
        alignAttrPadding = margin.top;
    }
    else if (alignAttr == NSLayoutAttributeBottom)
    {
        // Autolayout uses negative values when not using the visual syntax
        alignAttrPadding = -margin.bottom;
    }
    
    NSLayoutAttribute matchingAlignAttr = alignAttr;
    id edgeAlignView;
    if (alignAttrPadding != 0) {
        if (@available(iOS 11.0, *)) {
            edgeAlignView = parentView.safeAreaLayoutGuide;
        } else if (alignAttr == NSLayoutAttributeTop) {
            edgeAlignView = self.topLayoutGuide;
            matchingAlignAttr = NSLayoutAttributeBottom;
        } else {
            edgeAlignView = parentView;
        }
    } else {
        edgeAlignView = parentView;
    }
    
    NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:innerView
                                                         attribute:alignAttr
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:edgeAlignView
                                                         attribute:matchingAlignAttr
                                                        multiplier:1.0
                                                          constant:alignAttrPadding];
    // Use a lower priority than the main padding constraint
    c.priority = 850;
    
    [constraints addObject:c];
    
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(>=%f@1000)-[innerView]-(>=%f@1000)-|", margin.left, margin.right]
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(innerView)]];
    
    if (!widthApplied) {
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(==%f@600)-[innerView]-(==%f@600)-|", margin.left, margin.right]
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(innerView)]];
    }
    
    
    
    // Horizontal alignment
    // Special case: if the view is centered and has margin, add a constraint to make it start after the safe area+margin on both sides
    // It might look better if we ignored the margin, but we want to be consistent with previous versions of the SDK that already
    // applied the margin after the safe area
    if (hAlignAttr == NSLayoutAttributeCenterX)
    {
        if (margin.left != 0 && margin.right != 0) {
            if (@available(iOS 11.0, *)) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                    attribute:NSLayoutAttributeLeft
                                                                    relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                       toItem:parentView.safeAreaLayoutGuide
                                                                    attribute:NSLayoutAttributeLeft
                                                                   multiplier:1.0
                                                                     constant:margin.left]];
                
                [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                    attribute:NSLayoutAttributeRight
                                                                    relatedBy:NSLayoutRelationLessThanOrEqual
                                                                       toItem:parentView.safeAreaLayoutGuide
                                                                    attribute:NSLayoutAttributeRight
                                                                   multiplier:1.0
                                                                     constant:-margin.right]];
            }
        }
        
        [constraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:parentView
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1.0
                                                             constant:0]];
    }
    else
    {
        float hAlignAttrPadding = 0;
        
        if (hAlignAttr == NSLayoutAttributeLeft)
        {
            hAlignAttrPadding = margin.left;
        }
        else if (hAlignAttr == NSLayoutAttributeRight)
        {
            hAlignAttrPadding = -margin.right;
        }
        
        id hEdgeAlignView;
        if (hAlignAttrPadding != 0) {
            if (@available(iOS 11.0, *)) {
                hEdgeAlignView = parentView.safeAreaLayoutGuide;
            } else {
                hEdgeAlignView = parentView;
            }
        } else {
            hEdgeAlignView = parentView;
        }
        
        NSLayoutConstraint *vc = [NSLayoutConstraint constraintWithItem:innerView
                                                              attribute:hAlignAttr
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:hEdgeAlignView
                                                              attribute:hAlignAttr
                                                             multiplier:1.0
                                                               constant:hAlignAttrPadding];
        
        
        [constraints addObject:vc];
    }
    
    [parentView addConstraints:constraints];
}

- (void)applyContainerViewRulesForNode:(BACSSDOMNode*)node
                             innerView:(UIView*)innerView
                            parentView:(UIView*)parentView
                     shouldUseTopGuide:(BOOL)shouldUseTopGuide
{
    BACSSRules* rules = [self rulesForNode:node];
    
    [BAMSGStylableViewHelper applyCommonRules:rules
                                       toView:parentView];
    
    NSMutableArray<NSLayoutConstraint*>* constraints = [NSMutableArray new];
    
    UIEdgeInsets padding = UIEdgeInsetsZero;
    
    BOOL useSafeArea = YES;
    BOOL usePaddingForSafeArea = NO;
    
    // Assuming the rules are lowercased, and variables already resolved
    for (NSString *rule in [rules allKeys])
    {
        NSString *value = rules[rule];
        
        if ([@"padding-top" isEqualToString:rule])
        {
            padding.top = [value floatValue];
        }
        else if ([@"padding-bottom" isEqualToString:rule])
        {
            padding.bottom = [value floatValue];
        }
        else if ([@"padding-left" isEqualToString:rule])
        {
            padding.left = [value floatValue];
        }
        else if ([@"padding-right" isEqualToString:rule])
        {
            padding.right = [value floatValue];
        }
        else if ([@"safe-area" isEqualToString:rule])
        {
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
    
    id topGuide = self.topLayoutGuide;
    
    // Padding goes before everything
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(==%f@800)-[innerView]-(==%f@800)-|", padding.top, padding.bottom]
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(topGuide, innerView)]];
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|-(==%f@800)-[innerView]-(==%f@800)-|", padding.left, padding.right]
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(innerView)]];
    
    if (useSafeArea) {
        if (@available(iOS 11.0, *)) {
            UILayoutGuide *safeGuide = parentView.safeAreaLayoutGuide;
            NSMutableArray<NSLayoutConstraint*> *safeLayoutConstraints = [NSMutableArray new];
            [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:safeGuide
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:usePaddingForSafeArea ? padding.top : 0]];
            [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:safeGuide
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:usePaddingForSafeArea ? -padding.bottom : 0]];
            [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:innerView
                                                                          attribute:NSLayoutAttributeLeft
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:safeGuide
                                                                          attribute:NSLayoutAttributeLeft
                                                                         multiplier:1.0
                                                                           constant:usePaddingForSafeArea ? padding.left : 0]];
            [safeLayoutConstraints addObject:[NSLayoutConstraint constraintWithItem:innerView
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
        } else if (shouldUseTopGuide) {
            // topLayoutGuide is only allowed if:
            //  - shouldUseTopGuide is true
            //  - useSafeArea is true
            // shouldUseTopGuide is a hint given by the caller, since only the view highest on the screen should use that
            // as the topLayoutGuide depends on the view controller.
            // The safe area guide is WAY better, as it works in every view no matter where they are on the screen,
            // so the burden of figuring that out is not on us.
            // It's complex and hardly maintainable, but this whole class is like that anyway, so enjoy changing that
            // and be sure you test on iOS 8,9,10,11. Yes, all of them :)
            NSLayoutConstraint *topGuideConstraint = [NSLayoutConstraint constraintWithItem:innerView
                                                                                  attribute:NSLayoutAttributeTop
                                                                                  relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                     toItem:self.topLayoutGuide
                                                                                  attribute:NSLayoutAttributeBottom
                                                                                 multiplier:1.0
                                                                                   constant:usePaddingForSafeArea ? padding.top : 0];
            topGuideConstraint.priority = 1000;
            [NSLayoutConstraint activateConstraints:@[topGuideConstraint]];
        }
    }
    
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)fillInnerContentView
{
    BOOL willShowCTAs = [self.ctas count] > 0;
    
    if (self.imageURL)
    {
        NSURL *url = [NSURL URLWithString:self.imageURL];
        imageView = [BAMSGRemoteImageView new];
        imageView.userInteractionEnabled = NO;
        if (![BANullHelper isStringEmpty:self.imageDescription]) {
            imageView.accessibilityLabel = self.imageDescription;
            imageView.isAccessibilityElement = true;
        }
        [imageView setImageURL:url];
        [content addSubview:imageView];
        
        BACSSDOMNode *node = [BACSSDOMNode new];
        node.identifier = @"img";
        [self applyAbsolutePositionmentRulesForView:imageView
                                               node:node
                                         parentView:content];
    }

    if (self.titleText)
    {
        BAMSGStackViewItem *item = [self labelStackViewItemForLabel:self.titleText
                                                 withNodeIdentifier:@"title"];
        
        [innerContent addItem:item];
    }
    
    // Body text is not optional
    // We could use the "labelStackViewItemForLabel" method but we need HTML support
    // and we need to wrap it in a scrollview
    BACSSDOMNode *bodyNode = [BACSSDOMNode new];
    bodyNode.identifier = @"body";
    bodyNode.classes = @[@"text"];
    BACSSRules* bodyNodeRules = [self rulesForNode:bodyNode];
    
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
    // Minimum/maximum scrollview height
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:28]];
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1
                                                                  constant:150]];
    
    [bodyLabelWrapper addConstraint:[NSLayoutConstraint constraintWithItem:bodyLabelWrapper
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationLessThanOrEqual
                                                                    toItem:bodyLabelView
                                                                 attribute:NSLayoutAttributeHeight
                                                                multiplier:1
                                                                  constant:0]];
    
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
    
    bodyWrapperItem.attachToParentBottom = !willShowCTAs;
    
    [innerContent addItem:bodyWrapperItem];
    
    if (willShowCTAs)
    {
        ctasContainer = [BAMSGBaseContainerView new];
        ctasContainer.translatesAutoresizingMaskIntoConstraints = NO;
        
        BACSSDOMNode *ctasNode = [BACSSDOMNode new];
        ctasNode.identifier = @"ctas";
        
        
        BAMSGStackViewItem *ctas = [BAMSGStackViewItem new];
        ctas.view = ctasContainer;
        ctas.rules = [self rulesForNode:ctasNode];
        ctas.attachToParentBottom = YES;
        [innerContent addItem:ctas];
        
        [self fillCtasContainer];
    }
    
    if (self.autoclosingDuration > 0)
    {
        countdownView = [BAMSGCountdownView new];
        countdownView.translatesAutoresizingMaskIntoConstraints = NO;
        [content addSubview:countdownView];
        
        BACSSDOMNode *node = [BACSSDOMNode new];
        node.identifier = @"countdown";
        [self applyAbsolutePositionmentRulesForView:countdownView
                                               node:node
                                         parentView:content];
    }
}

- (void)fillCtasContainer
{
    if ([self.ctas count] == 0)
    {
        return;
    }
    
    // Instanciate and position the inner view
    innerCtasContainer = [BAMSGStackView new];
    innerCtasContainer.horizontal = self.ctaStackDirection == BAMSGBannerCTADirectionHorizontal;
    innerCtasContainer.delegate = self;
    innerCtasContainer.translatesAutoresizingMaskIntoConstraints = NO;
    innerCtasContainer.clipsToBounds = YES;
    [ctasContainer addSubview:innerCtasContainer];
    
    // We want the CTA container to be as small as possible, and let the content view grow.
    [ctasContainer setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisVertical];
    [ctasContainer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];

    BACSSDOMNode *contentNode = [BACSSDOMNode new];
    contentNode.identifier = @"ctas";
    [self applyContainerViewRulesForNode:contentNode
                               innerView:innerCtasContainer
                              parentView:ctasContainer
                       shouldUseTopGuide:false];
    
    BACSSDOMNode *innerCTANode = [BACSSDOMNode new];
    innerCTANode.identifier = @"ctas-inner";
    [BAMSGStylableViewHelper applyCommonRules:[self rulesForNode:innerCTANode]
                                       toView:innerCtasContainer];
    
    if (self.ctaStackDirection == BAMSGBannerCTADirectionHorizontal)
    {
        [self addHorizontalCtasToStackView:innerCtasContainer
                              previousView:nil];
        
        [innerCtasContainer sizeAllItemsEqually];
    }
    else
    {
        [self addCtasToStackView:innerCtasContainer
                    previousView:nil];
    }
    
}

- (void)addCtasToStackView:(BAMSGStackView*)stackView
              previousView:(UIView*)previousView
{
    int i = 1;
    for (BAMSGCTA *cta in self.ctas)
    {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:cta.label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%d", i]
                                                           previousView:previousView
                                                                    tag:i
                                                             horizontal:stackView.horizontal];
        
        if (i == [self.ctas count])
        {
            ctaItem.attachToParentBottom = YES;
        }
        
        [stackView addItem:ctaItem];
        previousView = ctaItem.view;
        i++;
    }
}

// Same as addCtasToStackView:previousView: but horizontal CTAs are reversed
- (void)addHorizontalCtasToStackView:(BAMSGStackView*)stackView
                        previousView:(UIView*)previousView
{
    // Invert the CTA order, so that the positive button is on the right
    
    for (NSUInteger i = [self.ctas count]; i > 0; i--)
    {
        BAMSGStackViewItem *ctaItem = [self buttonStackViewItemForLabel:self.ctas[i-1].label
                                                     withNodeIdentifier:[NSString stringWithFormat:@"cta%lu", (unsigned long)i]
                                                           previousView:previousView
                                                                    tag:i
                                                             horizontal:stackView.horizontal];
        
        if (i == 1)
        {
            ctaItem.attachToParentBottom = YES;
        }
        [stackView addItem:ctaItem];
        previousView = ctaItem.view;
    }
}

- (BAMSGStackViewItem*)labelStackViewItemForLabel:(NSString*)label withNodeIdentifier:(NSString*)nodeIdentifier
{
    UILabel *labelView = [BAMSGLabel new];
    labelView.numberOfLines = 0;
    labelView.minimumScaleFactor = 0.5;
    
    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = nodeIdentifier;
    node.classes = @[@"text"];
    
    BAMSGStackViewItem *item = [BAMSGStackViewItem new];
    item.view = labelView;
    item.rules = [self rulesForNode:node];
    
    // Setting the text after the rules saves a setText execution
    labelView.text = label;
    
    return item;
}

- (BAMSGStackViewItem*)buttonStackViewItemForLabel:(NSString*)label
                                withNodeIdentifier:(NSString*)nodeIdentifier
                                      previousView:(UIView*)previousView
                                               tag:(NSInteger)tag
                                        horizontal:(BOOL)horizontal
{
    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = nodeIdentifier;
    node.classes = @[@"btn", horizontal ? @"btn-h" : @"btn-v"];
    
    BAMSGButton *btnView = [BAMSGButton new];
    [btnView setTitle:label forState:UIControlStateNormal];
    btnView.tag = tag;
    [btnView addTarget:self
                action:@selector(ctaTapped:)
      forControlEvents:UIControlEventTouchUpInside];
    
    BAMSGStackViewItem *item = [BAMSGStackViewItem new];
    item.view = btnView;
    item.rules = [self rulesForNode:node];
    
    return item;
}

#pragma mark CTA callbacks

- (void)ctaTapped:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        NSInteger ctaID = [(UIButton*)sender tag] - 1;
        [self performCtaAtIndex:ctaID];
    }
    else
    {
        [BALogger publicForDomain:@"Messaging"
                          message:@"Internal error - A CTA was triggered but something unexpected happened. This shouldn't happen: please report this to Batch support: https://batch.com"];
    }
}

- (void)didDetectGlobalTap:(UIGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.isDismissed) {
            return;
        }
        
        if (self.globalTapDelay > 0 && [BAUptimeProvider uptime] < (lastViewAppearanceUptime + self.globalTapDelay) ) {
            [BALogger publicForDomain:@"Messaging"
                              message:@"View was tapped on, but the accidental touch prevention delay hasn't elapsed: rejecting tap."];
            return;
        }
        
        [self dismiss];
        
        if (self.globalTapAction != nil) {
            [self.messagingAnalyticsDelegate messageGlobalTapActionTriggered:self.messageDescription action:self.messageDescription.globalTapAction];
            
            [BAMessagingCenter.instance performAction:self.globalTapAction source:self.messageDescription.sourceMessage actionIndex:BatchMessageGlobalActionIndex messageIdentifier:self.messageDescription.sourceMessage.devTrackingIdentifier];
        } else {
            [BALogger publicForDomain:@"Messaging"
                              message:@"Internal error - A global tap action was triggered but something unexpected happened. This shouldn't happen: please report this to Batch support: https://batch.com"];
        }
    }
}

#pragma mark BAMSGStackViewDelegate methods

- (nonnull NSString*)separatorPrefixForStackView:(nonnull BAMSGStackView*)stackView
{
    return @"ctas";
}

- (nonnull BACSSRules*)stackView:(nonnull BAMSGStackView*)stackView
                                     rulesForSeparatorID:(nonnull NSString*)separatorID
{
    BACSSDOMNode *separatorNode = [BACSSDOMNode new];
    separatorNode.identifier = separatorID;
    separatorNode.classes = @[[NSString stringWithFormat:@"%@-%@", [self separatorPrefixForStackView:stackView], (stackView.horizontal ? @"h-sep" : @"sep")]];
    
    return [self rulesForNode:separatorNode];
}

#pragma mark - Parent

- (BAMSGMessage *_Nonnull)message {
    return self.messageDescription;
}

#pragma mark BAMSGPannableContainerViewDelegate methods

- (void)pannableContainerWasDismissed:(BAMSGPannableAnchoredContainerView*)container
{
    // Consider that swiping to dismiss simulates a close button tap
    [self closeButtonAction];
}

#pragma mark - Autoclosing

- (void)setupAutoclosing {} // Autoclosing setup is handled all in this class

- (void)doAnimateAutoclosing {
    if (self.autoclosingDuration <= 0) { return; }
    
    NSTimeInterval timeLeft = [self autoclosingRemainingTime];
    [countdownView setPercentage:timeLeft / self.autoclosingDuration];
    
    [self.view layoutIfNeeded];
    [countdownView layoutIfNeeded];
    
    [UIView animateWithDuration:timeLeft
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         [self->countdownView setPercentage:0];
                     }
                     completion:nil];
}

#pragma mark - Dismissal

- (BAPromise*)doDismiss {
    if (self.presentingWindow) {
        return [BAMessagingCenter.instance dismissWindow:self.presentingWindow];
    } else {
        return [self _doDismissSelfModal];
    }
    return [BAPromise rejected:nil];
}

@end
