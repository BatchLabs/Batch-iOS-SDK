//  Copyright © Batch.com. All rights reserved.

#import <XCTest/XCTest.h>

#import "BAMSGAction.h"
#import "BAMSGCTA.h"
#import "BAMSGMessage.h"
#import "BAMSGPayloadParser.h"
#import "BatchMessagingPrivate.h"
#import "Versions.h"

// Raw dictionaries lock the MEP wire keys, discriminators, and API-level gate.
@interface BAMSGPayloadParserTests : XCTestCase
@end

@implementation BAMSGPayloadParserTests

#pragma mark - Fixtures

- (BatchMessage *)mepRawMessage:(NSDictionary *)payload {
    NSMutableDictionary *fullPayload = [NSMutableDictionary dictionaryWithDictionary:payload];
    if (fullPayload[@"id"] == nil) {
        fullPayload[@"id"] = @"payload-parser-tests";
    }
    return [BatchMessage messageForPayload:fullPayload isCEPMessage:NO];
}

- (id)parseMEP:(NSDictionary *)payload {
    return [BAMSGPayloadParser messageForMEPRawMessage:[self mepRawMessage:payload] bailIfNotAlert:NO];
}

/// Parses and fails the test if the payload was rejected. Use this whenever the test goes on to read
/// a property: a `nil` message answers `nil` to every getter and a zeroed struct to `imageSize`, which
/// would make the assertions below pass for the very regression they are meant to catch.
- (id)requireMEP:(NSDictionary *)payload {
    id message = [self parseMEP:payload];
    XCTAssertNotNil(message, @"the payload was rejected, but this test reads its properties");
    return message;
}

/// Minimal payloads that parse successfully, one per kind. They are returned mutable so a test can
/// add or remove the single key it is about.
- (NSMutableDictionary *)alertPayload {
    return [@{@"kind" : @"alert", @"cancelLabel" : @"Close", @"body" : @"Alert body"} mutableCopy];
}

- (NSMutableDictionary *)universalPayload {
    return [@{@"kind" : @"universal", @"style" : @"@import sdk(\"generic1\");"} mutableCopy];
}

/// Banners and modals share one parser: 'kind' is the only thing that differs.
- (NSMutableDictionary *)bannerPayloadForKind:(NSString *)kind {
    return [@{@"kind" : kind, @"style" : @"@import sdk(\"banner1\");"} mutableCopy];
}

- (NSMutableDictionary *)imagePayload {
    NSDictionary *action = @{@"a" : @"batch.dismiss"};
    return [@{@"kind" : @"image", @"image" : @"https://batch.com/image.png", @"action" : action} mutableCopy];
}

- (NSMutableDictionary *)webViewPayload {
    return [@{@"kind" : @"webview", @"url" : @"https://batch.com/webview.html"} mutableCopy];
}

#pragma mark - Kind dispatch

- (void)testKindSelectsTheConcreteMessageClass {
    XCTAssertTrue([[self parseMEP:[self alertPayload]] isMemberOfClass:[BAMSGMessageAlert class]]);
    XCTAssertTrue([[self parseMEP:[self universalPayload]] isMemberOfClass:[BAMSGMessageInterstitial class]]);
    XCTAssertTrue([[self parseMEP:[self bannerPayloadForKind:@"banner"]] isMemberOfClass:[BAMSGMessageBanner class]]);
    XCTAssertTrue([[self parseMEP:[self bannerPayloadForKind:@"modal"]] isMemberOfClass:[BAMSGMessageModal class]]);
    XCTAssertTrue([[self parseMEP:[self imagePayload]] isMemberOfClass:[BAMSGMessageImage class]]);
    XCTAssertTrue([[self parseMEP:[self webViewPayload]] isMemberOfClass:[BAMSGMessageWebView class]]);
}

- (void)testUnknownKindIsRejectedRatherThanProducingABaseMessage {
    XCTAssertNil([self parseMEP:(@{@"kind" : @"carousel", @"style" : @"@import sdk(\"generic1\");"})]);
}

- (void)testMissingOrNonStringKindIsRejected {
    XCTAssertNil([self parseMEP:@{@"style" : @"@import sdk(\"generic1\");"}]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @34, @"style" : @"@import sdk(\"generic1\");"})]);
    XCTAssertNil([self parseMEP:(@{@"kind" : [NSNull null], @"style" : @"@import sdk(\"generic1\");"})]);
}

- (void)testParsedMessageKeepsItsSourceMessage {
    BatchMessage *raw = [self mepRawMessage:[self bannerPayloadForKind:@"banner"]];

    BAMSGMEPMessage *message = [BAMSGPayloadParser messageForMEPRawMessage:raw bailIfNotAlert:NO];

    XCTAssertNotNil(message);
    XCTAssertEqual(raw, message.sourceMessage);
}

- (void)testBailIfNotAlertOnlyLetsAlertsThrough {
    NSArray<NSDictionary *> *nonAlertPayloads = @[
        [self universalPayload], [self bannerPayloadForKind:@"banner"], [self bannerPayloadForKind:@"modal"],
        [self imagePayload], [self webViewPayload]
    ];

    for (NSDictionary *payload in nonAlertPayloads) {
        BatchMessage *raw = [self mepRawMessage:payload];
        XCTAssertNil([BAMSGPayloadParser messageForMEPRawMessage:raw bailIfNotAlert:YES], @"kind: %@",
                     payload[@"kind"]);
    }

    BatchMessage *alert = [self mepRawMessage:[self alertPayload]];
    XCTAssertNotNil([BAMSGPayloadParser messageForMEPRawMessage:alert bailIfNotAlert:YES]);
}

#pragma mark - minapi gate

- (void)testMinAPIEqualToTheCurrentLevelIsAccepted {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"minapi"] = @(BAMessagingAPILevel);

    XCTAssertNotNil([self parseMEP:payload]);
}

- (void)testMinAPIAboveTheCurrentLevelIsDropped {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"minapi"] = @(BAMessagingAPILevel + 1);

    XCTAssertNil([self parseMEP:payload]);
}

- (void)testAbsentOrNullMinAPIMeansNoGate {
    NSMutableDictionary *payload = [self universalPayload];
    XCTAssertNotNil([self parseMEP:payload]);

    payload[@"minapi"] = [NSNull null];
    XCTAssertNotNil([self parseMEP:payload]);

    payload[@"minapi"] = @0;
    XCTAssertNotNil([self parseMEP:payload]);
}

- (void)testNonNumberMinAPIIsRejected {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"minapi"] = @"34";

    XCTAssertNil([self parseMEP:payload]);
}

#pragma mark - Body

- (void)testBodyAndBodyHTMLAreBothKeptWhenPresent {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"body"] = @"plain body";
    payload[@"body_html"] = @"styled <b>body</b>";

    BAMSGMEPMessage *message = [self requireMEP:payload];

    XCTAssertEqualObjects(@"plain body", message.bodyText);
    XCTAssertEqualObjects(@"styled body", message.bodyHtml.text);
    XCTAssertEqual(message.bodyHtml.transforms.count, 1);
}

- (void)testBodyHTMLIsAbsentWhenOnlyPlainBodyIsSent {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"body"] = @"plain body";

    BAMSGMEPMessage *message = [self requireMEP:payload];

    XCTAssertEqualObjects(@"plain body", message.bodyText);
    XCTAssertNil(message.bodyHtml);
}

- (void)testNonStringBodyIsFatal {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"body"] = @42;

    XCTAssertNil([self parseMEP:payload]);
}

- (void)testUnparsableOrNonStringBodyHTMLFallsBackOnBody {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"body"] = @"plain body";
    payload[@"body_html"] = @"mismatched <u>markup</k>";

    BAMSGMEPMessage *message = [self requireMEP:payload];
    XCTAssertEqualObjects(@"plain body", message.bodyText);
    XCTAssertNil(message.bodyHtml);

    payload[@"body_html"] = @42;
    message = [self requireMEP:payload];
    XCTAssertEqualObjects(@"plain body", message.bodyText);
    XCTAssertNil(message.bodyHtml);
}

- (void)testNullBodyIsTreatedAsAbsent {
    NSMutableDictionary *payload = [self universalPayload];
    payload[@"body"] = [NSNull null];

    BAMSGMEPMessage *message = [self requireMEP:payload];

    XCTAssertNil(message.bodyText);
}

#pragma mark - Alert

- (void)testAlertPayload {
    BAMSGMessageAlert *alert = [self requireMEP:@{
        @"kind" : @"alert",
        @"title" : @"Alert title",
        @"body" : @"Alert body",
        @"cancelLabel" : @"Later",
        @"cta" : @{@"l" : @"Open", @"a" : @"batch.deeplink", @"args" : @{@"l" : @"https://batch.com"}}
    }];

    XCTAssertEqualObjects(@"Alert title", alert.titleText);
    XCTAssertEqualObjects(@"Alert body", alert.bodyText);
    XCTAssertEqualObjects(@"Later", alert.cancelButtonText);
    XCTAssertEqualObjects(@"Open", alert.acceptCTA.label);
    XCTAssertEqualObjects(@"batch.deeplink", alert.acceptCTA.actionIdentifier);
    XCTAssertEqualObjects(@{@"l" : @"https://batch.com"}, alert.acceptCTA.actionArguments);
}

- (void)testAlertWithoutCancelLabelIsRejected {
    XCTAssertNil([self parseMEP:(@{@"kind" : @"alert", @"body" : @"Alert body"})]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @"alert", @"body" : @"Alert body", @"cancelLabel" : @42})]);
}

- (void)testAlertWithBlankTitleAndBodyIsRejected {
    XCTAssertNil(
        [self parseMEP:(@{@"kind" : @"alert", @"cancelLabel" : @"Close", @"title" : @"   ", @"body" : @"\n"})]);
}

- (void)testAlertRejectsAnArrayOfCTAs {
    XCTAssertNil([self parseMEP:(@{
                           @"kind" : @"alert",
                           @"cancelLabel" : @"Close",
                           @"body" : @"Alert body",
                           @"cta" : @[ @{@"l" : @"Open"} ]
                       })]);
}

- (void)testAlertWithMalformedCTAIsStillDisplayedWithoutIt {
    BAMSGMessageAlert *alert = [self requireMEP:@{
        @"kind" : @"alert",
        @"cancelLabel" : @"Close",
        @"body" : @"Alert body",
        @"cta" : @{@"a" : @"batch.dismiss"}
    }];

    XCTAssertNil(alert.acceptCTA);
}

#pragma mark - Universal (interstitial)

- (void)testUniversalPayload {
    BAMSGMessageInterstitial *universal = [self requireMEP:@{
        @"kind" : @"universal",
        @"style" : @"@import sdk(\"generic1\");",
        @"h1" : @"Heading",
        @"h2" : @"Title",
        @"h3" : @"Subtitle",
        @"hero" : @"https://batch.com/hero.png",
        @"hdesc" : @"Hero description",
        @"video" : @"https://batch.com/hero.mp4",
        @"close" : @NO,
        @"attach_cta_bottom" : @YES,
        @"stack_cta_h" : @YES,
        @"stretch_cta_h" : @YES,
        @"flip_hero_v" : @YES,
        @"flip_hero_h" : @YES,
        @"hero_split_ratio" : @0.4,
        @"auto_close" : @5000,
    }];

    XCTAssertEqualObjects(@"@import sdk(\"generic1\");", universal.css);
    XCTAssertEqualObjects(@"Heading", universal.headingText);
    XCTAssertEqualObjects(@"Title", universal.titleText);
    XCTAssertEqualObjects(@"Subtitle", universal.subtitleText);
    XCTAssertEqualObjects(@"https://batch.com/hero.png", universal.heroImageURL);
    XCTAssertEqualObjects(@"Hero description", universal.heroDescription);
    XCTAssertEqualObjects(@"https://batch.com/hero.mp4", universal.videoURL);
    XCTAssertFalse(universal.showCloseButton);
    XCTAssertTrue(universal.attachCTAsBottom);
    XCTAssertTrue(universal.stackCTAsHorizontally);
    XCTAssertTrue(universal.stretchCTAsHorizontally);
    XCTAssertTrue(universal.flipHeroVertical);
    XCTAssertTrue(universal.flipHeroHorizontal);
    XCTAssertEqualObjects(@0.4, universal.heroSplitRatio);
    XCTAssertEqual(universal.autoClose, 5.0);
}

- (void)testUniversalBlankTextsAreNormalizedToNil {
    BAMSGMessageInterstitial *universal = [self requireMEP:@{
        @"kind" : @"universal",
        @"style" : @"@import sdk(\"generic1\");",
        @"h1" : @"  ",
        @"h2" : @"",
        @"h3" : [NSNull null],
    }];

    XCTAssertNil(universal.headingText);
    XCTAssertNil(universal.titleText);
    XCTAssertNil(universal.subtitleText);
}

- (void)testUniversalOutOfRangeHeroSplitRatioIsIgnored {
    NSMutableDictionary *payload = [self universalPayload];

    payload[@"hero_split_ratio"] = @1;
    XCTAssertNil([(BAMSGMessageInterstitial *)[self requireMEP:payload] heroSplitRatio]);

    payload[@"hero_split_ratio"] = @0;
    XCTAssertNil([(BAMSGMessageInterstitial *)[self requireMEP:payload] heroSplitRatio]);

    payload[@"hero_split_ratio"] = @0.99;
    XCTAssertEqualObjects(@0.99, [(BAMSGMessageInterstitial *)[self requireMEP:payload] heroSplitRatio]);
}

- (void)testUniversalWithoutStyleIsRejected {
    XCTAssertNil([self parseMEP:(@{@"kind" : @"universal", @"h1" : @"Heading"})]);
}

- (void)testUniversalRejectsANonArrayCTAList {
    XCTAssertNil([self
        parseMEP:(@{@"kind" : @"universal", @"style" : @"@import sdk(\"generic1\");", @"cta" : @{@"l" : @"Open"}})]);
}

- (void)testUniversalSkipsNonDictionaryCTAEntries {
    BAMSGMessageInterstitial *universal = [self requireMEP:@{
        @"kind" : @"universal",
        @"style" : @"@import sdk(\"generic1\");",
        @"cta" : @[ @"not an object", @{@"l" : @"First"}, @42, @{@"l" : @"Second"} ]
    }];

    XCTAssertEqual(universal.ctas.count, 2);
    XCTAssertEqualObjects(@"First", universal.ctas[0].label);
    XCTAssertEqualObjects(@"Second", universal.ctas[1].label);
}

- (void)testUniversalWithAMalformedCTAObjectIsRejected {
    XCTAssertNil([self parseMEP:(@{
                           @"kind" : @"universal",
                           @"style" : @"@import sdk(\"generic1\");",
                           @"cta" : @[ @{@"l" : @"Fine"}, @{@"a" : @"batch.dismiss"} ]
                       })]);

    XCTAssertNil([self parseMEP:(@{
                           @"kind" : @"universal",
                           @"style" : @"@import sdk(\"generic1\");",
                           @"cta" : @[ @{@"l" : @"Fine", @"a" : @"batch.deeplink", @"args" : @"not an object"} ]
                       })]);
}

- (void)testCTAKeysAndDefaults {
    BAMSGMessageInterstitial *universal = [self requireMEP:@{
        @"kind" : @"universal",
        @"style" : @"@import sdk(\"generic1\");",
        @"cta" : @[
            @{@"l" : @"Open", @"a" : @"batch.deeplink", @"args" : @{@"l" : @"https://batch.com", @"li" : @YES}},
            @{@"l" : @"Dismiss", @"a" : [NSNull null]},
        ]
    }];

    XCTAssertEqual(universal.ctas.count, 2);
    XCTAssertEqualObjects(@"Open", universal.ctas[0].label);
    XCTAssertEqualObjects(@"batch.deeplink", universal.ctas[0].actionIdentifier);
    XCTAssertEqualObjects((@{@"l" : @"https://batch.com", @"li" : @YES}), universal.ctas[0].actionArguments);

    XCTAssertNil(universal.ctas[1].actionIdentifier);
    XCTAssertEqualObjects(@{}, universal.ctas[1].actionArguments);
}

#pragma mark - Banner and modal

- (void)testBannerPayload {
    BAMSGMessageBanner *banner = [self requireMEP:@{
        @"kind" : @"banner",
        @"style" : @"@import sdk(\"banner1\");",
        @"title" : @"Banner title",
        @"image" : @"https://batch.com/image.png",
        @"image_description" : @"An image",
        @"close" : @YES,
        @"swipe_dismiss" : @NO,
        @"cta_direction" : @"V",
        @"global_tap_delay" : @1500,
        @"auto_close" : @10000,
        @"action" : @{@"a" : @"batch.deeplink", @"args" : @{@"l" : @"https://batch.com"}},
        @"cta" : @[ @{@"l" : @"Open", @"a" : @"batch.dismiss"} ],
    }];

    XCTAssertEqualObjects(@"@import sdk(\"banner1\");", banner.css);
    XCTAssertEqualObjects(@"Banner title", banner.titleText);
    XCTAssertEqualObjects(@"https://batch.com/image.png", banner.imageURL);
    XCTAssertEqualObjects(@"An image", banner.imageDescription);
    XCTAssertTrue(banner.showCloseButton);
    XCTAssertFalse(banner.allowSwipeToDismiss);
    XCTAssertEqual(BAMSGBannerCTADirectionVertical, banner.ctaDirection);
    XCTAssertEqual(banner.globalTapDelay, 1.5);
    XCTAssertEqual(banner.autoClose, 10.0);
    XCTAssertEqualObjects(@"batch.deeplink", banner.globalTapAction.actionIdentifier);
    XCTAssertEqualObjects(@{@"l" : @"https://batch.com"}, banner.globalTapAction.actionArguments);
    XCTAssertEqual(banner.ctas.count, 1);
    XCTAssertEqualObjects(@"Open", banner.ctas[0].label);
}

- (void)testModalSharesTheBannerPayload {
    BAMSGMessageModal *modal = [self requireMEP:@{
        @"kind" : @"modal",
        @"style" : @"@import sdk(\"modal1\");",
        @"title" : @"Modal title",
        @"cta_direction" : @"diagonal",
    }];

    XCTAssertEqualObjects(@"Modal title", modal.titleText);
    XCTAssertEqualObjects(@"@import sdk(\"modal1\");", modal.css);
    XCTAssertEqual(BAMSGBannerCTADirectionHorizontal, modal.ctaDirection);
}

- (void)testBannerWithoutStyleIsRejected {
    XCTAssertNil([self parseMEP:(@{@"kind" : @"banner", @"title" : @"Banner title"})]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @"modal", @"title" : @"Modal title"})]);
}

- (void)testBannerRejectsANonDictionaryGlobalAction {
    XCTAssertNil([self
        parseMEP:(@{@"kind" : @"banner", @"style" : @"@import sdk(\"banner1\");", @"action" : @"batch.dismiss"})]);
}

- (void)testBannerWithAnEmptyGlobalActionIdentifierKeepsTheBanner {
    BAMSGMessageBanner *banner =
        [self requireMEP:@{@"kind" : @"banner", @"style" : @"@import sdk(\"banner1\");", @"action" : @{@"a" : @"   "}}];

    XCTAssertNil(banner.globalTapAction);
}

#pragma mark - Image

- (void)testImagePayload {
    BAMSGMessageImage *image = [self requireMEP:@{
        @"kind" : @"image",
        @"image" : @"https://batch.com/image.png",
        @"image_description" : @"An image",
        @"style" : @"@import sdk(\"image1\");",
        @"width" : @300,
        @"height" : @250,
        @"fullscreen" : @NO,
        @"swipe_dismiss" : @NO,
        @"auto_close" : @7000,
        @"global_tap_delay" : @2000,
        @"action" : @{@"a" : @"batch.deeplink", @"args" : @{@"l" : @"https://batch.com"}},
    }];

    XCTAssertEqualObjects(@"https://batch.com/image.png", image.imageURL);
    XCTAssertEqualObjects(@"An image", image.imageDescription);
    XCTAssertEqualObjects(@"@import sdk(\"image1\");", image.css);
    XCTAssertTrue(CGSizeEqualToSize(CGSizeMake(300, 250), image.imageSize));
    XCTAssertFalse(image.isFullscreen);
    XCTAssertFalse(image.allowSwipeToDismiss);
    XCTAssertEqual(image.autoClose, 7.0);
    XCTAssertEqual(image.globalTapDelay, 2.0);
    XCTAssertEqualObjects(@"batch.deeplink", image.globalTapAction.actionIdentifier);
    XCTAssertEqualObjects(@{@"l" : @"https://batch.com"}, image.globalTapAction.actionArguments);
}

- (void)testImageDefaults {
    BAMSGMessageImage *image = [self requireMEP:[self imagePayload]];

    XCTAssertTrue(image.isFullscreen);
    XCTAssertTrue(image.allowSwipeToDismiss);
    XCTAssertEqualObjects(@"", image.css);
    XCTAssertEqualObjects(@"", image.imageDescription);
    XCTAssertEqual(image.autoClose, 0.0);
    XCTAssertEqual(image.globalTapDelay, 0.0);
}

- (void)testImageSizeNeedsBothDimensions {
    NSMutableDictionary *payload = [self imagePayload];
    payload[@"width"] = @300;

    BAMSGMessageImage *image = [self requireMEP:payload];

    XCTAssertTrue(CGSizeEqualToSize(CGSizeZero, image.imageSize));
}

- (void)testImageWithoutAUsableURLIsRejected {
    NSMutableDictionary *payload = [self imagePayload];

    [payload removeObjectForKey:@"image"];
    XCTAssertNil([self parseMEP:payload]);

    payload[@"image"] = @"";
    XCTAssertNil([self parseMEP:payload]);
}

- (void)testImageWithoutActionIsRejected {
    NSMutableDictionary *payload = [self imagePayload];

    [payload removeObjectForKey:@"action"];
    XCTAssertNil([self parseMEP:payload]);

    payload[@"action"] = @"batch.dismiss";
    XCTAssertNil([self parseMEP:payload]);
}

- (void)testImageFallsBackOnDefaultsForWronglyTypedOptionals {
    NSMutableDictionary *payload = [self imagePayload];
    payload[@"fullscreen"] = @"false";
    payload[@"width"] = @"300";
    payload[@"image_description"] = @42;

    BAMSGMessageImage *image = [self requireMEP:payload];

    XCTAssertTrue(image.isFullscreen);
    XCTAssertTrue(CGSizeEqualToSize(CGSizeZero, image.imageSize));
    XCTAssertEqualObjects(@"", image.imageDescription);
}

#pragma mark - WebView

- (void)testWebViewPayload {
    BAMSGMessageWebView *webView = [self requireMEP:@{
        @"kind" : @"webview",
        @"url" : @"https://batch.com/webview.html",
        @"style" : @"@import sdk(\"webview1\");",
        @"dev" : @YES,
        @"inAppDeeplinks" : @YES,
        @"timeout" : @12500,
    }];

    XCTAssertEqualObjects([NSURL URLWithString:@"https://batch.com/webview.html"], webView.url);
    XCTAssertEqualObjects(@"@import sdk(\"webview1\");", webView.css);
    XCTAssertTrue(webView.developmentMode);
    XCTAssertTrue(webView.openDeeplinksInApp);
    XCTAssertEqual(webView.timeout, 12.5);
}

- (void)testWebViewLayoutWorkaroundMapping {
    NSMutableDictionary *payload = [self webViewPayload];

    payload[@"iOSLayoutWorkaround"] = @0;
    XCTAssertEqual(BAMSGWebViewLayoutWorkaroundDoNothing,
                   [(BAMSGMessageWebView *)[self requireMEP:payload] layoutWorkaround]);

    payload[@"iOSLayoutWorkaround"] = @1;
    XCTAssertEqual(BAMSGWebViewLayoutWorkaroundRelayoutPeriodically,
                   [(BAMSGMessageWebView *)[self requireMEP:payload] layoutWorkaround]);

    payload[@"iOSLayoutWorkaround"] = @2;
    XCTAssertEqual(BAMSGWebViewLayoutWorkaroundApplyInsetsNatively,
                   [(BAMSGMessageWebView *)[self requireMEP:payload] layoutWorkaround]);
}

- (void)testWebViewDefaults {
    BAMSGMessageWebView *webView = [self requireMEP:[self webViewPayload]];

    XCTAssertEqualObjects(@"", webView.css);
    XCTAssertFalse(webView.developmentMode);
    XCTAssertFalse(webView.openDeeplinksInApp);
    XCTAssertEqual(webView.timeout, 0.0);
    XCTAssertEqual(BAMSGWebViewLayoutWorkaroundApplyInsetsNatively, webView.layoutWorkaround);
}

- (void)testWebViewRequiresAnHTTPURL {
    XCTAssertNil([self parseMEP:@{@"kind" : @"webview"}]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @"webview", @"url" : @42})]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @"webview", @"url" : @"file:///etc/passwd"})]);
    XCTAssertNil([self parseMEP:(@{@"kind" : @"webview", @"url" : @"myapp://webview"})]);

    XCTAssertNotNil([self parseMEP:(@{@"kind" : @"webview", @"url" : @"HTTP://batch.com/webview.html"})]);
}

@end
