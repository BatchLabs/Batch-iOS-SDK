//
//  BAMSGWebviewViewController.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGWebviewViewController.h>

#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BAMSGAction.h>
#import <Batch/BAMSGActivityIndicatorView.h>
#import <Batch/BAMSGCloseButton.h>
#import <Batch/BAMSGImageDownloader.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BAMSGPannableAlertContainerView.h>
#import <Batch/BAMSGRemoteImageView.h>
#import <Batch/BAMSGViewToolbox.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BATWebviewBridgeLegacyWKHandler.h>
#import <Batch/BATWebviewBridgeWKHandler.h>
#import <Batch/BATWebviewJavascriptBridge.h>
#import <Batch/BATWebviewUtils.h>
#import <Batch/BAUptimeProvider.h>
#import <Batch/BAWindowHelper.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/BatchUser.h>

#import <WebKit/WebKit.h>

NSString *const BAMSGWebviewPublicLoggerDomain = @"Messaging - WebView";

NSString *const BAMSGWebviewDevMenuTitle = @"Development menu";
NSString *const BAMSGWebviewDevMenuReload = @"Reload";

@interface BAMSGWebviewViewController () <WKNavigationDelegate,
                                          WKUIDelegate,
                                          UIContextMenuInteractionDelegate,
                                          BATWebviewJavascriptBridgeDelegate,
                                          BATWebviewBridgeLegacyWKHandlerWebViewSource>

@property (nonatomic) BAMSGActivityIndicatorView *loaderView;

@property (nonatomic) WKWebView *webView;

@end

@implementation BAMSGWebviewViewController {
    BATWebviewJavascriptBridge *_bridge;
    NSInteger _originalWebViewScrollBehaviour;
    BOOL _webViewUsesSafeArea;
    // As WKWebView will throw an error when we abort a frame navigation, make it possible to override the error
    NSError *_nextNavigationErrorOverride;
}

- (instancetype)initWithMessage:(BAMSGMessageWebView *)message andStyle:(BACSSDocument *)style {
    self = [super initWithStyleRules:style];
    if (self) {
        _message = message;

        _bridge = [[BATWebviewJavascriptBridge alloc] initWithMessage:message delegate:self];

        // The WebView's default behaviour is to be fullscreen, going under the unsafe area
        _webViewUsesSafeArea = false;

        _nextNavigationErrorOverride = nil;

        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        // Webview format has a simple fade in/out animation
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupActivityIndicator];

    CGRect windowFrame = [BAWindowHelper keyWindow].frame;
    _webView = [[WKWebView alloc] initWithFrame:windowFrame configuration:[self webViewConfiguration]];
    if (@available(iOS 16.4, *)) {
        _webView.inspectable = true;
    }
    // Back up the original value in case Apple changes it in an iOS release
    _originalWebViewScrollBehaviour = _webView.scrollView.contentInsetAdjustmentBehavior;
    _webView.clipsToBounds = YES;
    [_webView setOpaque:NO];
    _webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_webView];

    self.closeButton = [BAMSGCloseButton new];
    self.closeButton.showBorder = true;
    [self.closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.closeButton];

    [self setupConstraints];

    [self setupWebviewSettings];
    [self loadPageWithCacheEnabled:_message.developmentMode ? false : true];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setupActivityIndicator {
    BACSSDOMNode *node = [BACSSDOMNode new];
    node.identifier = @"root";
    BACSSRules *rules = [self rulesForNode:node];

    _loaderView = [[BAMSGActivityIndicatorView alloc] initWithPreferredSize:BAMSGActivityIndicatorViewSizeLarge];
    _loaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _loaderView.hidesWhenStopped = YES;
    [_loaderView applyRules:rules];
    [_loaderView startAnimating];
    [self.view addSubview:_loaderView];
}

- (void)setupConstraints {
    [_webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self setupCloseButton];
    [self setupWebViewStyle];

    // This NEEDS to be after setupWebViewStyle as _webViewUsesSafeArea is read from the CSS there
    [BAMSGViewToolbox setView:_webView fullframeToSuperview:self.view useSafeArea:_webViewUsesSafeArea];

    // Center close button to top right corner of content view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                          attribute:NSLayoutAttributeRight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeRight
                                                         multiplier:1
                                                           constant:-15]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.closeButton
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.topLayoutGuide
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:10]];

    // Center the loader view
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loaderView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0.0]];

    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_loaderView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0.0]];
}

- (void)setupCloseButton {
    BACSSDOMNode *closeNode = [BACSSDOMNode new];
    closeNode.identifier = @"close";

    BACSSRules *rules = [self rulesForNode:closeNode];
    [self.closeButton applyRules:rules];

    // On dev mode we want to add actions on long pressing close
    if (_message.developmentMode) {
        if (@available(iOS 13.0, *)) {
            // Attach the context menu on the close button
            [self.closeButton addInteraction:[[UIContextMenuInteraction alloc] initWithDelegate:self]];
        } else {
            // On iOS 12 and lower, use a gesture recognizer to manually show a dialog with the development options
            UILongPressGestureRecognizer *longPressRecognizer =
                [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCloseButton:)];
            [self.closeButton addGestureRecognizer:longPressRecognizer];
        }
    }
}

- (void)setupWebViewStyle {
    BACSSDOMNode *webviewNode = [BACSSDOMNode new];
    webviewNode.identifier = @"webview";
    BACSSRules *webviewRules = [self rulesForNode:webviewNode];

    [BAMSGStylableViewHelper applyCommonRules:webviewRules toView:_webView];

    for (NSString *rule in [webviewRules allKeys]) {
        NSString *value = webviewRules[rule];
        if ([@"safe-area" isEqualToString:rule]) {
            if ([@"no" isEqualToString:value]) {
                _webViewUsesSafeArea = NO;
            } else if ([@"auto" isEqualToString:value] || [@"yes" isEqualToString:value]) {
                _webViewUsesSafeArea = YES;
            }
        }
    }
}

- (BOOL)shouldDisplayInSeparateWindow {
    return NO;
}

#pragma mark - Context menu

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0)) {
    // As of writing, we only support one context menu: the development menu on the close button
    // This is why we make our view controller conform to UIContextMenuInteractionDelegate rather
    // than split it up in another object. It's quite a complicated API for simple use cases.
    __weak BAMSGWebviewViewController *weakSelf = self;
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *_Nullable(NSArray<UIMenuElement *> *_Nonnull suggestedActions) {
                       return [weakSelf developmentContextMenu];
                     }];
}

#pragma mark - Development

- (UIMenu *)developmentContextMenu NS_AVAILABLE_IOS(13_0) {
    __weak BAMSGWebviewViewController *weakSelf = self;
    NSArray<UIAction *> *items = @[ [UIAction actionWithTitle:BAMSGWebviewDevMenuReload
                                                        image:[UIImage systemImageNamed:@"arrow.clockwise"]
                                                   identifier:nil
                                                      handler:^(__kindof UIAction *_Nonnull action) {
                                                        [weakSelf reloadWebView];
                                                      }] ];
    return [UIMenu menuWithTitle:BAMSGWebviewDevMenuTitle children:items];
}

- (void)showDevelopmentMenu:(nonnull UIView *)sourceView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BAMSGWebviewDevMenuTitle
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = sourceView;

    [alert addAction:[UIAlertAction actionWithTitle:BAMSGWebviewDevMenuReload
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                              [self reloadWebView];
                                            }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *_Nonnull action){
                                            }]];

    [self presentViewController:alert animated:true completion:nil];
}

- (void)showDevelopmentError:(nonnull NSString *)errorMessage sourceError:(nullable NSError *)sourceError {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WebView Error"
                                                                   message:errorMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *_Nonnull action) {
                                              [self closeAfterError:sourceError];
                                            }]];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)reloadWebView {
    [self loadPageWithCacheEnabled:false];
}

#pragma mark - Webview Setup

- (void)scheduleWebViewRelayouts {
    // Work around a layout bug where WKWebView's content window might not take all space
    // See nativelyApplyViewport
    [self.webView setNeedsLayout];
    // Yes, this is terrible. But WKWebView can still fail at relayouting
    // I hope to find a better way
    __weak WKWebView *weakWebView = self.webView;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
      [weakWebView setNeedsLayout];
    });
    // Yes, we need to do it at different time intervals because some websites will work with the other
    // relayouts, some will not.
    // There has to be some underlying issue that I'm missing, but this will do for now
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(200 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
      [weakWebView setNeedsLayout];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakWebView setNeedsLayout];
    });
}

- (void)nativelyApplyViewport {
    // Work around an issue where WKWebView does not properly apply the meta viewport on initial load
    // https://stackoverflow.com/questions/60896073/ios-meta-tag-viewport-fit-cover-works-only-when-inserted-manually
    // One workaround is to repeteadly call setNeedsLayout after some time. However this is makes for a ugly
    // visual transition, as the view shifts.
    //
    // What this workaround does is:
    // - Hide the webview until we're done
    // - On navigation commit (and finish), run some javascript that extracts the value of <meta name="viewport" ...
    // - Parse viewport-fit
    // - Apply the viewport-fit value natively on the scrollview
    // (Note that at this point: maybe implement a way of toggling which workaround we want to try?)

    __weak BAMSGWebviewViewController *weakSelf = self;

    NSString *viewportExtractionJavascript =
        @"document.querySelector('meta[name=\"viewport\"]').getAttribute(\"content\")";
    [_webView evaluateJavaScript:viewportExtractionJavascript
               completionHandler:^(id _Nullable result, NSError *_Nullable error) {
                 BOOL isViewportCover = false;
                 if ([result isKindOfClass:NSString.class]) {
                     NSString *stringResult = (NSString *)result;
                     if ([stringResult rangeOfString:@"viewport-fit=cover" options:NSCaseInsensitiveSearch].location !=
                         NSNotFound) {
                         isViewportCover = true;
                     }
                 }

                 [BALogger debugForDomain:@"WebView" message:@"Viewport-fit is cover: %i", isViewportCover];

                 BAMSGWebviewViewController *strongSelf = weakSelf;
                 if (strongSelf != nil) {
                     strongSelf->_webView.scrollView.contentInsetAdjustmentBehavior =
                         isViewportCover ? UIScrollViewContentInsetAdjustmentNever
                                         : strongSelf->_originalWebViewScrollBehaviour;
                     [strongSelf->_webView setAlpha:1];
                     [strongSelf->_webView setNeedsLayout];
                 }
               }];
}

- (void)setupWebviewSettings {
    _webView.allowsBackForwardNavigationGestures = false;
    _webView.scrollView.alwaysBounceVertical = false;
    _webView.scrollView.bounces = false;
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;

    [_webView setAlpha:0];
}

- (WKWebViewConfiguration *)webViewConfiguration {
    WKUserContentController *userContentController = [WKUserContentController new];
    if (@available(iOS 14.0, *)) {
        [userContentController
            addScriptMessageHandlerWithReply:[[BATWebviewBridgeWKHandler alloc] initWithBridge:_bridge]
                                contentWorld:WKContentWorld.pageWorld
                                        name:@"batchBridge"];
    } else {
        [userContentController addScriptMessageHandler:[[BATWebviewBridgeLegacyWKHandler alloc] initWithBridge:_bridge
                                                                                               webViewProvider:self]
                                                  name:@"batchBridge"];
    }

    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.userContentController = userContentController;
    config.allowsInlineMediaPlayback = true;
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAudio;

    return config;
}

- (void)loadPageWithCacheEnabled:(BOOL)cacheEnabled {
    [BALogger debugForDomain:BAMSGWebviewPublicLoggerDomain
                     message:@"Loading (with cache: %d) URL: %@", cacheEnabled, self.message.url];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.message.url];

    if (self.message.timeout > 0) {
        request.timeoutInterval = self.message.timeout;
    }

    NSString *region = [BatchUser region];
    if (![BANullHelper isStringEmpty:region]) {
        [request addValue:region forHTTPHeaderField:@"X-Batch-Custom-Region"];
    }
    NSString *language = [BatchUser language];
    if (![BANullHelper isStringEmpty:language]) {
        [request addValue:language forHTTPHeaderField:@"X-Batch-Custom-Language"];
    }

    if (!cacheEnabled) {
        request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    }

    [_webView loadRequest:request];
}

#pragma mark - User actions

#pragma mark - Close

- (void)closeAfterError:(nullable NSError *)error {
    [self.messagingAnalyticsDelegate message:self.message
                               closedByError:[BATMessagingCloseErrorHelper guessErrorCauseForError:error]];
    [self dismiss];
}

- (BOOL)showCloseButton {
    return true;
}

- (void)didLongPressCloseButton:(UILongPressGestureRecognizer *)gestureRecognizer {
    // Only react to UIGestureRecognizerStateBegan, other states happen on finger drag
    // and finger lift.
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self showDevelopmentMenu:gestureRecognizer.view];
    }
}

#pragma mark - Dismissal

- (BAPromise *)doDismiss {
    return [self _doDismissSelfModal];
}

- (void)dismissWithAnalyticsID:(nullable NSString *)analyticsIdentifier {
    [self performAction:@"batch.dismiss" arguments:@{} analyticsID:analyticsIdentifier];
}

#pragma mark - Actions

- (void)performAction:(NSString *)actionIdentifier
            arguments:(NSDictionary<NSString *, id> *)arguments
          analyticsID:(NSString *)analyticsIdentifier {
    BAMSGAction *action = [BAMSGAction new];
    action.actionIdentifier = actionIdentifier;
    action.actionArguments = arguments;

    // Sanitize analyticsIdentifier
    if ([BANullHelper isStringEmpty:analyticsIdentifier]) {
        // Trim
        analyticsIdentifier = nil;
    }
    NSInteger idLength = [analyticsIdentifier length];
    if (idLength > 0 && idLength > 30) {
        [BALogger publicForDomain:@"Messaging"
                          message:@"Could not track webview event: The analytics ID is invalid: it should be 30 "
                                  @"characters or less. "
                                   "The action will be tracked without an analytics ID, but will still be performed."];
        analyticsIdentifier = nil;
    }

    [self.messagingAnalyticsDelegate messageWebViewClickTracked:self.message
                                                         action:action
                                            analyticsIdentifier:analyticsIdentifier];

    [[self dismiss] then:^(NSObject *_Nullable ignored) {
      BAMessagingCenter *messagingCenter = [BAInjection injectClass:BAMessagingCenter.class];
      [messagingCenter performAction:action
                              source:self.message.sourceMessage
                  webViewAnalyticsID:analyticsIdentifier
                   messageIdentifier:self.message.sourceMessage.devTrackingIdentifier];
    }];
}

- (void)openDeeplink:(nonnull NSString *)url
    openInAppOverride:(nullable NSNumber *)openInAppOverride
          analyticsID:(nullable NSString *)analyticsIdentifier {
    if ([BANullHelper isStringEmpty:analyticsIdentifier]) {
        // If there is no explicit analyticsIdentifier, try to extract it from the URL
        analyticsIdentifier = [BATWebviewUtils analyticsIdForURL:url];
    }

    NSMutableDictionary *deeplinkArgs = [NSMutableDictionary new];
    deeplinkArgs[@"l"] = url;

    BOOL openInApp = self.message.openDeeplinksInApp;
    if (openInAppOverride != nil) {
        openInApp = [openInAppOverride boolValue];
    }
    deeplinkArgs[@"li"] = [NSNumber numberWithBool:openInApp];

    [self performAction:@"batch.deeplink" arguments:deeplinkArgs analyticsID:analyticsIdentifier];
}

- (void)bridge:(nonnull BATWebviewJavascriptBridge *)bridge
    shouldPerformAction:(nonnull NSString *)actionIdentifier
              arguments:(nonnull NSDictionary<NSString *, id> *)arguments
            analyticsID:(nullable NSString *)analyticsIdentifier {
    [self performAction:actionIdentifier arguments:arguments analyticsID:analyticsIdentifier];
}

#pragma mark - BATWebviewBridgeLegacyWKHandlerWebViewSource

- (nullable WKWebView *)backingWebViewForLegacyHandler:(BATWebviewBridgeLegacyWKHandler *)handler {
    return _webView;
}

#pragma mark - BATWebviewJavascriptBridgeDelegate

- (void)bridge:(nonnull BATWebviewJavascriptBridge *)bridge
    shouldDismissMessageWithAnalyticsID:(nullable NSString *)analyticsIdentifier {
    [self dismissWithAnalyticsID:analyticsIdentifier];
}

- (void)bridge:(nonnull BATWebviewJavascriptBridge *)bridge
    shouldOpenDeeplink:(nonnull NSString *)url
     openInAppOverride:(nullable NSNumber *)openInAppOverride
           analyticsID:(nullable NSString *)analyticsIdentifier {
    [self openDeeplink:url openInAppOverride:openInAppOverride analyticsID:analyticsIdentifier];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [_loaderView stopAnimating];

    if (_message.layoutWorkaround == BAMSGWebViewLayoutWorkaroundRelayoutPeriodically) {
        [self scheduleWebViewRelayouts];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self.webView setNeedsLayout];

    if (_message.layoutWorkaround == BAMSGWebViewLayoutWorkaroundApplyInsetsNatively) {
        [self nativelyApplyViewport];
    } else {
        [self.webView setAlpha:1];
    }
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    BOOL shouldOverrideHandling = false;

    // Do not handle iframe requests
    if (navigationAction.targetFrame.isMainFrame) {
        NSURL *targetURL = navigationAction.request.URL;
        NSString *scheme = [targetURL.scheme lowercaseString];
        NSString *host = [targetURL.host lowercaseString];

        // WKWebView disallows navigation to anything else than http/https by default
        // Override this, and handle those link ourselves as it would otherwise throw
        // an error.
        if (host != nil && ![@"https" isEqualToString:scheme] && ![@"http" isEqualToString:scheme]) {
            shouldOverrideHandling = true;
        }

        // Special case itunes.apple.com and apps.apple.com.
        // Sometimes, iOS will translate those to itms://, and sometimes it wont. This ensures it does.
        // They almost never want to be opened in the webview.
        if ([@"itunes.apple.com" isEqualToString:host] || [@"apps.apple.com" isEqualToString:host]) {
            shouldOverrideHandling = true;
        }

        if (shouldOverrideHandling) {
            // As we're going outside of the webview, make it act like an external link.
            // This will put the link through the deeplink interceptor, close the format, and
            // handle analytics.
            decisionHandler(WKNavigationActionPolicyCancel);
            [self openDeeplink:targetURL.absoluteString openInAppOverride:nil analyticsID:nil];
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
                      decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    // Do not handle iFrame responses
    BOOL isForMainFrame = navigationResponse.forMainFrame;
    // Should never happen but you never know
    BOOL isHTTPResponse = [navigationResponse.response isKindOfClass:NSHTTPURLResponse.class];

    if (!isForMainFrame || !isHTTPResponse) {
        decisionHandler(WKNavigationResponsePolicyAllow);
        return;
    }

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)navigationResponse.response;

    NSInteger statusCode = [httpResponse statusCode];
    [BALogger debugForDomain:BAMSGWebviewPublicLoggerDomain
                     message:@"WKNavigationDelegate - Decide policy for response (code: %ld, url: %@)", statusCode,
                             httpResponse.URL];

    WKNavigationResponsePolicy wantedPolicy = WKNavigationResponsePolicyAllow;

    if (statusCode == 310 || statusCode >= 400) {
        // It's an error. Ignore 1xx, webkit probably handles this itself
        wantedPolicy = WKNavigationResponsePolicyCancel;

        // So far, there is only one error for WEBVIEW_ERROR_DOMAIN, so don't make a code enum just yet.
        // WebKit will throw a navigation error: don't handle this error right now, but keep it for later
        _nextNavigationErrorOverride = [NSError
            errorWithDomain:WEBVIEW_ERROR_DOMAIN
                       code:1
                   userInfo:@{
                       NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HTTP Error Code %ld", statusCode]
                   }];
    }

    decisionHandler(wantedPolicy);
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation
                       withError:(NSError *)error {
    [BALogger debugForDomain:BAMSGWebviewPublicLoggerDomain message:@"WKNavigationDelegate - Failed navigation"];
    [self handleNavigationError:error];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(null_unspecified WKNavigation *)navigation
            withError:(NSError *)error {
    [BALogger debugForDomain:BAMSGWebviewPublicLoggerDomain
                     message:@"WKNavigationDelegate - Failed provisional navigation"];
    [self handleNavigationError:error];
}

- (void)handleNavigationError:(NSError *)error {
    // Ignoring iOS-specific WebKit error PlugInLoadFailed
    // Error fired when loading video URL without HTML container
    // Shortcut issue : [sc-54815]
    if ([error code] == 204) {
        [BALogger debugForDomain:BAMSGWebviewPublicLoggerDomain
                         message:@"WKNavigationDelegate - Ignoring 204 Error (Plug-in handled load)."];
        return;
    }

    if (_nextNavigationErrorOverride != nil) {
        error = _nextNavigationErrorOverride;
        _nextNavigationErrorOverride = nil;
    }

    [BALogger publicForDomain:BAMSGWebviewPublicLoggerDomain
                      message:@"WebView was closed because of a navigation error"];
    [BALogger errorForDomain:BAMSGWebviewPublicLoggerDomain message:@"WebView navigation error: %@", error];
    if (self.message.developmentMode) {
        NSString *errorMessage =
            [NSString stringWithFormat:@"The WebView encountered an error and will be closed.\nThis error will only be "
                                       @"shown during development.\n\nCause: %@",
                                       error.localizedDescription];
        [self showDevelopmentError:errorMessage sourceError:error];
    } else {
        [self closeAfterError:error];
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [BALogger publicForDomain:BAMSGWebviewPublicLoggerDomain message:@"WebView was closed because its process crashed"];
    if (self.message.developmentMode) {
        NSString *errorMessage = [NSString
            stringWithFormat:
                @"The WebView crashed and will be closed.\nThis error will only be shown during development."];
        [self showDevelopmentError:errorMessage sourceError:nil];
    } else {
        [self closeAfterError:nil];
    }
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView
    runJavaScriptAlertPanelWithMessage:(NSString *)message
                      initiatedByFrame:(WKFrameInfo *)frame
                     completionHandler:(void (^)(void))completionHandler {
    if (self.isDismissed) {
        completionHandler();
        return;
    }

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:message
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:[BAMSGViewToolbox localizedStringUsingUIKit:@"OK"]
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                   completionHandler();
                                                 }]];
    [self presentViewController:controller animated:true completion:nil];
}

- (void)webView:(WKWebView *)webView
    runJavaScriptConfirmPanelWithMessage:(NSString *)message
                        initiatedByFrame:(WKFrameInfo *)frame
                       completionHandler:(void (^)(BOOL))completionHandler {
    if (self.isDismissed) {
        completionHandler(false);
        return;
    }

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:message
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:[BAMSGViewToolbox localizedStringUsingUIKit:@"OK"]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                   completionHandler(true);
                                                 }]];
    [controller addAction:[UIAlertAction actionWithTitle:[BAMSGViewToolbox localizedStringUsingUIKit:@"Cancel"]
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                   completionHandler(false);
                                                 }]];
    [self presentViewController:controller animated:true completion:nil];
}

- (void)webView:(WKWebView *)webView
    runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
                              defaultText:(NSString *)defaultText
                         initiatedByFrame:(WKFrameInfo *)frame
                        completionHandler:(void (^)(NSString *_Nullable))completionHandler {
    if (self.isDismissed) {
        completionHandler(defaultText);
        return;
    }

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:prompt
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    [controller addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
      textField.text = defaultText;
    }];

    [controller addAction:[UIAlertAction actionWithTitle:[BAMSGViewToolbox localizedStringUsingUIKit:@"OK"]
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                   NSArray<UITextField *> *textFields = controller.textFields;
                                                   UITextField *inputText = [textFields firstObject];
                                                   if (inputText != nil) {
                                                       completionHandler(inputText.text);
                                                   } else {
                                                       completionHandler(defaultText);
                                                   }
                                                 }]];

    [controller addAction:[UIAlertAction actionWithTitle:[BAMSGViewToolbox localizedStringUsingUIKit:@"Cancel"]
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                   completionHandler(nil);
                                                 }]];

    [self presentViewController:controller animated:true completion:nil];
}

- (nullable WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
               forNavigationAction:(WKNavigationAction *)navigationAction
                    windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (navigationAction.targetFrame == nil) {
        NSURL *targetURL = navigationAction.request.URL;
        if (targetURL != nil) {
            [self openDeeplink:targetURL.absoluteString openInAppOverride:nil analyticsID:nil];
        } else {
            [BALogger errorForDomain:BRIDGE_ERROR_DOMAIN message:@"Could not open target=_blank link: no target URL"];
        }
    }
    return nil;
}

- (void)webViewDidClose:(WKWebView *)webView {
    [self dismissWithAnalyticsID:nil];
}

@end
