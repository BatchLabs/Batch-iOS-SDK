//
//  BAMSGViewController.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BACSS.h>
#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BAMSGViewController.h>
#import <Batch/BAMSGViewToolbox.h>
#import <Batch/BAMessageEventPayload.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAUptimeProvider.h>
#import <Batch/BAWindowHelper.h>

#define LOGGER_DOMAIN @"BAMSGViewController"

@interface BAMSGViewController ()

@property (nonatomic, assign) NSTimeInterval autoclosingStartTime;
@property (nonatomic) BACSSEnvironment *cssEnvironment;
@property (nonatomic, assign) BOOL overridesStatusbarColor;
@property (nonatomic, assign) BOOL shouldHideStatusbar;

@end

@implementation BAMSGViewController

- (BAMessagingCenter *)messagingCenter {
    return [BAMessagingCenter instance];
}

- (instancetype)init {
    self = [self initWithStyleRules:[BACSSDocument new]];
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [self initWithStyleRules:[BACSSDocument new]];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self initWithStyleRules:[BACSSDocument new]];
    return self;
}

- (nonnull instancetype)initWithStyleRules:(nonnull BACSSDocument *)style {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _style = style;
        _autoclosingDuration = 0;
        _showCloseButton = false;
        _autoclosingStartTime = 0;
        _isDismissed = NO;
        _overridenStatusBarStyle = UIStatusBarStyleDefault;
        _shouldHideStatusbar = NO;
        _messagingAnalyticsDelegate = [BAInjection injectProtocol:@protocol(BAMessagingAnalyticsDelegate)];

        UIKeyCommand *escape = [UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                   modifierFlags:0
                                                          action:@selector(closeButtonAction)];
        [self addKeyCommand:escape];
    }
    return self;
}

- (BAMSGMEPMessage *)message {
    @throw [NSException
        exceptionWithName:NSInternalInconsistencyException
                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                 userInfo:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _cssEnvironment = [self computeCSSEnvironment];

    [self setupRootStyle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setupAutoclosing];
    _isDismissed = false;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([self automaticAutoclosingCountdown]) {
        [self startAutoclosingCountdown];
    }

    [self.messagingAnalyticsDelegate messageShown:self.message];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [self.messagingAnalyticsDelegate messageDismissed:self.message];
    _isDismissed = true;
}

- (BOOL)modalPresentationCapturesStatusBarAppearance {
    // Do not capture the status bar appearance if we're showing on an iOS 13+
    // sheet
    if (@available(iOS 13, *)) {
        switch (self.modalPresentationStyle) {
            case UIModalPresentationFormSheet:
            case UIModalPresentationAutomatic:
            case UIModalPresentationPageSheet:
                return false;
            default:
                return true;
        }
    }
    return true;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return _overridenStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden {
    return _shouldHideStatusbar;
}

#pragma mark - Styling

- (BACSSEnvironment *)computeCSSEnvironment {
    BACSSEnvironment *env = [BACSSEnvironment new];

    env.viewSize = [self computeViewSize];

    switch ([self traitCollection].userInterfaceStyle) {
        case UIUserInterfaceStyleDark:
            env.darkMode = true;
            break;
        case UIUserInterfaceStyleLight:
        case UIUserInterfaceStyleUnspecified:
        default:
            env.darkMode = false;
    }

    return env;
}

- (CGSize)computeViewSize {
    CGSize viewSize = [BAMSGViewToolbox sceneSize];

    // Make sure the size is always portrait
    if (viewSize.width > viewSize.height) {
        CGFloat swap = viewSize.width;
        viewSize.width = viewSize.height;
        viewSize.height = swap;
    }

    return viewSize;
}

- (BACSSRules *)rulesForNode:(BACSSDOMNode *)node {
    return [_style flatRulesForNode:node withEnvironment:self.cssEnvironment];
}

- (void)setupRootStyle {
    BACSSDOMNode *rootContainerNode = [BACSSDOMNode new];
    rootContainerNode.identifier = @"root";
    BACSSRules *rootRules = [self rulesForNode:rootContainerNode];
    [BAMSGStylableViewHelper applyCommonRules:rootRules toView:self.view];
    for (NSString *rule in [rootRules allKeys]) {
        if ([@"statusbar" isEqualToString:rule]) {
            NSString *value = rootRules[rule];
            if ([@"light" isEqualToString:value]) {
                _overridenStatusBarStyle = UIStatusBarStyleLightContent;
                _shouldHideStatusbar = NO;
            } else if ([@"dark" isEqualToString:value]) {
                // Dark is a black statusbar -> Default.
                _overridenStatusBarStyle = UIStatusBarStyleDefault;
                _shouldHideStatusbar = NO;
            } else if ([@"hidden" isEqualToString:value]) {
                _shouldHideStatusbar = YES;
            }

#if !TARGET_OS_VISION
            [self setNeedsStatusBarAppearanceUpdate];
#endif

            break; // We've only got one rule to check, no need to continue
        }
    }
    if (@available(iOS 15.0, *)) {
        self.view.maximumContentSizeCategory = UIContentSizeCategoryExtraExtraExtraLarge;
    }
}

#pragma mark - Dismissal

- (BAPromise *)dismiss {
    if (_isDismissed) {
        return [BAPromise resolved:nil];
    }

    return [self doDismiss];
}

- (BAPromise *)doDismiss {
    [NSException raise:NSInternalInconsistencyException
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return [BAPromise rejected:nil];
}

- (BAPromise *)_doDismissSelfModal {
    BAPromise *dismissPromise = [BAPromise new];
    if (self.presentingViewController != nil) {
        if (self.presentedViewController == nil) {
            [self dismissViewControllerAnimated:YES
                                     completion:^{
                                       [dismissPromise resolve:nil];
                                     }];
        } else {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Refusing to dismiss modal: something is covering us."];
            [dismissPromise reject:nil];
        }
    } else {
        [BALogger
            debugForDomain:LOGGER_DOMAIN
                   message:@"Refusing to dismiss modal: no presenting view controller. We're probably not on screen."];
        [dismissPromise reject:nil];
    }
    return dismissPromise;
}

- (void)closeButtonAction {
    [self.messagingAnalyticsDelegate messageClosed:self.message];

    [self dismiss];
}

- (void)userDidCloseMessage {
    if (_isDismissed) {
        return;
    }
    _isDismissed = YES;

    [self.messagingAnalyticsDelegate messageClosed:self.message];
}

#pragma mark - CTA

- (void)performCtaAtIndex:(NSInteger)index;
{
    [[self dismiss] then:^(NSObject *_Nullable value) {
      if (index < [self.ctas count]) {
          BAMSGCTA *cta = [self.ctas objectAtIndex:index];
          if (!cta) {
              return;
          }

          [BAMessagingCenter.instance messageButtonClicked:self.message ctaIndex:index action:cta];

          NSString *ctaIdentifier =
              [BATCH_MESSAGE_MEP_CTA_INDEX_KEY stringByAppendingString:[NSString stringWithFormat:@"%ld", index]];

          // We don't need to handle BAMSGCTAActionKindClose since we did that earlier
          [BAMessagingCenter.instance performAction:cta
                                             source:self.message.sourceMessage
                                      ctaIdentifier:ctaIdentifier
                                  messageIdentifier:self.message.sourceMessage.devTrackingIdentifier];
      } else {
          [BALogger publicForDomain:@"Messaging"
                            message:@"Internal error - A CTA was triggered but something unexpected happened. This "
                                    @"shouldn't happen: please report this to Batch support: https://batch.com"];
      }
    }];
}

#pragma mark - Autoclosing

- (void)setCloseButtonEnabled:(BOOL)showCloseButton autoclosingDuration:(NSTimeInterval)autoclosingDuration {
    _autoclosingDuration = autoclosingDuration;
    _showCloseButton = showCloseButton;
    if (autoclosingDuration > 0 && (UIAccessibilityIsVoiceOverRunning() || UIAccessibilityIsSwitchControlRunning())) {
        [BALogger
            debugForDomain:@"Messaging"
                   message:
                       @"Voice Over/Switch control running: disabling auto close and forcing close button visibility"];
        _autoclosingDuration = 0;
        _showCloseButton = true;
    }
}

- (void)setupAutoclosing {
    if (self.autoclosingDuration > 0 && self.closeButton != nil) {
        // Show the filled countdown before the first paint to avoid seeing the button in a "normal" state
        [self.closeButton prepareCountdown];
    }
}

- (BOOL)automaticAutoclosingCountdown {
    return true;
}

- (void)startAutoclosingCountdown {
    if (self.autoclosingDuration <= 0 || _autoclosingStartTime != 0) {
        return;
    }

    _autoclosingStartTime = [BAUptimeProvider uptime];

    __weak typeof(self) weakSelf = self;
    dispatch_time_t autoCloseTime = dispatch_time(DISPATCH_TIME_NOW, self.autoclosingDuration * NSEC_PER_SEC);
    dispatch_after(autoCloseTime, dispatch_get_main_queue(), ^(void) {
      [weakSelf internalAutoclosingDidFire];
    });

    [self doAnimateAutoclosing];
}

- (void)doAnimateAutoclosing {
    if (self.autoclosingDuration > 0 && self.closeButton != nil) {
        [self.closeButton animateCountdownForDuration:self.autoclosingDuration completionHandler:nil];
    }
}

- (void)internalAutoclosingDidFire {
    if (_isDismissed) {
        return;
    }
    [self autoclosingDidFire];
}

- (void)autoclosingDidFire {
    [self.messagingAnalyticsDelegate messageAutomaticallyClosed:self.message];

    [self dismiss];
}

- (NSTimeInterval)autoclosingRemainingTime {
    return self.autoclosingDuration - ([BAUptimeProvider uptime] - _autoclosingStartTime);
}

@end
