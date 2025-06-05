//
//  BAMSGPayloadParser.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BALogger.h>
#import <Batch/BAMSGPayloadParser.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/Versions.h>

#define LOGGER_DOMAIN @"BAMSGPayloadParser"

@implementation BAMSGPayloadParser
+ (BAMSGCEPMessage *)messageForCEPRawMessage:(BatchMessage *)rawMessage bailIfNotAlert:(BOOL)bailNotAlert {
    BAMSGCEPMessage *message = [BAMSGPayloadParser parseBaseCEPMessage:rawMessage.messagePayload];
    message.sourceMessage = rawMessage;

    return message;
}

+ (BAMSGMEPMessage *_Nullable)messageForMEPRawMessage:(BatchMessage *_Nonnull)rawMessage
                                       bailIfNotAlert:(BOOL)bailNotAlert {
    // Basic parsing
    BAMSGMEPMessage *message = [BAMSGPayloadParser parseBaseMEPMessage:rawMessage.messagePayload];

    if ([message isKindOfClass:[BAMSGMessageAlert class]]) {
        message = [BAMSGPayloadParser parseAlertMessage:rawMessage.messagePayload
                                         withBaseObject:(BAMSGMessageAlert *)message];
    } else if ([message isKindOfClass:[BAMSGMessageInterstitial class]]) {
        if (bailNotAlert) {
            return nil;
        }
        message = [BAMSGPayloadParser parseUniversalMessage:rawMessage.messagePayload
                                             withBaseObject:(BAMSGMessageInterstitial *)message];
    } else if ([message isKindOfClass:[BAMSGMessageBanner class]]) {
        if (bailNotAlert) {
            return nil;
        }
        message = [BAMSGPayloadParser parseBannerMessage:rawMessage.messagePayload
                                          withBaseObject:(BAMSGMessageBanner *)message];
    } else if ([message isKindOfClass:[BAMSGMessageModal class]]) {
        if (bailNotAlert) {
            return nil;
        }
        message = [BAMSGPayloadParser parseModalMessage:rawMessage.messagePayload
                                         withBaseObject:(BAMSGMessageModal *)message];
    } else if ([message isKindOfClass:[BAMSGMessageImage class]]) {
        if (bailNotAlert) {
            return nil;
        }
        message = [BAMSGPayloadParser parseImageMessage:rawMessage.messagePayload
                                         withBaseObject:(BAMSGMessageImage *)message];
    } else if ([message isKindOfClass:[BAMSGMessageWebView class]]) {
        if (bailNotAlert) {
            return nil;
        }
        message = [BAMSGPayloadParser parseWebViewMessage:rawMessage.messagePayload
                                           withBaseObject:(BAMSGMessageWebView *)message];
    } else {
        [BAMSGPayloadParser printGenericDebugLog:@"Unknown BAMSGMessage subclass or nil"];
        return nil;
    }

    message.sourceMessage = rawMessage;

    return message;
}

+ (BAMSGMEPMessage *_Nullable)parseBaseMEPMessage:(NSDictionary *_Nonnull)userData {
    NSString *kind = userData[@"kind"];
    if (![kind isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"'kind' is not a NSString"];
        return nil;
    }

    BAMSGMEPMessage *baseMessage = nil;

    if ([kind isEqualToString:@"alert"]) {
        baseMessage = [[BAMSGMessageAlert alloc] init];
    } else if ([kind isEqualToString:@"universal"]) {
        baseMessage = [[BAMSGMessageInterstitial alloc] init];
    } else if ([kind isEqualToString:@"banner"]) {
        baseMessage = [[BAMSGMessageBanner alloc] init];
    } else if ([kind isEqualToString:@"modal"]) {
        baseMessage = [[BAMSGMessageModal alloc] init];
    } else if ([kind isEqualToString:@"image"]) {
        baseMessage = [[BAMSGMessageImage alloc] init];
    } else if ([kind isEqualToString:@"webview"]) {
        baseMessage = [[BAMSGMessageWebView alloc] init];
    } else {
        [BAMSGPayloadParser printGenericDebugLog:[@"Unknown 'kind': " stringByAppendingString:kind]];
        return nil;
    }

    if (![BAMSGPayloadParser isMinAPICompliant:userData]) {
        return nil;
    }

    NSString *body = userData[@"body"];
    if ((id)body == [NSNull null]) {
        body = nil;
    }
    if (body != nil && ![body isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"'body' is not nil but isn't an NSString"];
        return nil;
    }

    baseMessage.bodyText = body;

    NSString *bodyHtml = userData[@"body_html"];
    if ((id)bodyHtml == [NSNull null]) {
        bodyHtml = nil;
    }
    if (bodyHtml != nil) {
        if ([bodyHtml isKindOfClass:[NSString class]]) {
            BATHtmlParser *htmlParser = [[BATHtmlParser alloc] initWithString:bodyHtml];
            NSError *parseErr = [htmlParser parse];
            if (parseErr == nil) {
                NSString *unstyledText = htmlParser.text;
                if (unstyledText.length == 0 && baseMessage.bodyText.length > 0) {
                    [BAMSGPayloadParser
                        printGenericDebugLog:
                            @"'body_html' is empty once parsed, but 'body' isn't: falling back on 'body'"];
                }

                BAMSGHTMLText *parsedHtml = [BAMSGHTMLText new];
                parsedHtml.text = unstyledText;
                parsedHtml.transforms = htmlParser.transforms;
                baseMessage.bodyHtml = parsedHtml;
            } else {
                [BALogger debugForDomain:LOGGER_DOMAIN
                                 message:@"Could not parse 'body_html': %@", parseErr.localizedDescription];
            }
        } else {
            // Not a fatal error, view controllers will fallback
            [BAMSGPayloadParser
                printGenericDebugLog:@"'bodyHtml' is not nil but isn't an NSString: falling back on 'body'"];
        }
    }

    return baseMessage;
}

+ (BAMSGCEPMessage *_Nullable)parseBaseCEPMessage:(NSDictionary *_Nonnull)userData {
    if (![BAMSGPayloadParser isMinAPICompliant:userData key:@"minMLvl"]) {
        return nil;
    }

    BAMSGCEPMessage *baseMessage = [[BAMSGCEPMessage alloc] init];

    return baseMessage;
}

+ (BOOL)isMinAPICompliant:(NSDictionary *_Nonnull)userData {
    return [BAMSGPayloadParser isMinAPICompliant:userData key:@"minapi"];
}

+ (BOOL)isMinAPICompliant:(NSDictionary *_Nonnull)userData key:(NSString *)key {
    NSNumber *minimumMessagingAPIVersion = userData[key];
    if ((id)minimumMessagingAPIVersion == [NSNull null]) {
        minimumMessagingAPIVersion = nil;
    }

    if (minimumMessagingAPIVersion != nil && ![minimumMessagingAPIVersion isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"'minimumMessagingAPIVersion' is not nil but not a NSNumber."];
        return FALSE;
    }

    // Validate the api version before going any further
    NSInteger minimumMessagingAPIVersionInteger = [minimumMessagingAPIVersion integerValue];
    if (minimumMessagingAPIVersionInteger > 0 && minimumMessagingAPIVersionInteger > BAMessagingAPILevel) {
        [BAMSGPayloadParser
            printGenericDebugLog:
                [NSString
                    stringWithFormat:@"minapi too high for this SDK. Got %ld, current SDK messaging API level: %u",
                                     (long)minimumMessagingAPIVersionInteger, BAMessagingAPILevel]];
        [BALogger publicForDomain:@"Messaging"
                          message:@"This SDK is too old to display this message. Please update it."];
        return FALSE;
    }

    return TRUE;
}

+ (BAMSGMessageAlert *_Nullable)parseAlertMessage:(NSDictionary *_Nonnull)userData
                                   withBaseObject:(BAMSGMessageAlert *_Nonnull)alert {
    if (!alert) {
        return nil;
    }

    NSDictionary *cta = userData[@"cta"];
    if ((id)cta == [NSNull null]) {
        cta = nil;
    }
    if (cta != nil && ![cta isKindOfClass:[NSDictionary class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Alert: 'cta' is not nil but not a NSDictionary"];
        return nil;
    }

    BAMSGCTA *parsedCTA = nil;

    if (cta) {
        parsedCTA = [BAMSGPayloadParser parseCTA:cta];
    }

    NSString *title = userData[@"title"];
    if ((id)title == [NSNull null]) {
        title = nil;
    }
    if (title != nil && ![title isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Alert: 'title' is not nil but not a NSString"];
        return nil;
    }

    NSString *cancelButtonText = userData[@"cancelLabel"];
    if (![cancelButtonText isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Alert: 'cancelLabel' is not a NSString"];
        return nil;
    }

    alert.titleText = title;
    alert.cancelButtonText = cancelButtonText;
    alert.acceptCTA = parsedCTA;

    if ([alert.titleText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length ==
            0 &&
        [alert.bodyText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length ==
            0) {
        [BAMSGPayloadParser
            printGenericDebugLog:@"Alert: 'title' and 'body' are both empty or null. At least one must be filled."];
        return nil;
    }

    return alert;
}

+ (BAMSGMessageInterstitial *_Nullable)parseUniversalMessage:(NSDictionary *_Nonnull)userData
                                              withBaseObject:(BAMSGMessageInterstitial *_Nonnull)universal {
    if (!universal) {
        return nil;
    }

    NSString *heading = userData[@"h1"];
    if ((id)heading == [NSNull null]) {
        heading = nil;
    }

    if (heading != nil && ![heading isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'heading' is not nil but not a NSString"];
        return nil;
    }

    if ([heading stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        heading = nil;
    }

    NSString *title = userData[@"h2"];
    if ((id)title == [NSNull null]) {
        title = nil;
    }

    if (title != nil && ![title isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'title' is not nil but not a NSString"];
        return nil;
    }

    if ([title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        title = nil;
    }

    NSString *subtitle = userData[@"h3"];
    if ((id)subtitle == [NSNull null]) {
        subtitle = nil;
    }

    if (subtitle != nil && ![subtitle isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'title' is not nil but not a NSString"];
        return nil;
    }

    if ([subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        subtitle = nil;
    }

    NSString *hero = userData[@"hero"];
    if ((id)hero == [NSNull null]) {
        hero = nil;
    }

    if (hero != nil && ![hero isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'hero' is not nil but not a NSString"];
        return nil;
    }

    NSString *heroDescription = userData[@"hdesc"];
    if ((id)heroDescription == [NSNull null]) {
        heroDescription = nil;
    }

    if (heroDescription != nil && ![heroDescription isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'hdesc' is not nil but not a NSString"];
        return nil;
    }

    NSString *video = userData[@"video"];
    if ((id)video == [NSNull null]) {
        video = nil;
    }

    if (video != nil && ![video isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'video' is not nil but not a NSString"];
        return nil;
    }

    NSString *css = userData[@"style"];
    if (![css isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'style' is not a NSString"];
        return nil;
    }

    NSMutableArray<BAMSGCTA *> *parsedCTAs = [NSMutableArray new];

    NSArray *ctas = userData[@"cta"];
    if ((id)ctas == [NSNull null]) {
        ctas = nil;
    }

    if (ctas != nil && ![ctas isKindOfClass:[NSArray class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'ctas' is not nil but not a NSArray"];
        return nil;
    }

    for (NSDictionary *cta in ctas) {
        if (![cta isKindOfClass:[NSDictionary class]]) {
            [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'cta' is not a NSDictionary, skipping"];
            continue;
        }

        BAMSGCTA *parsedCTA = [BAMSGPayloadParser parseCTA:cta];

        if (!parsedCTA) {
            return nil;
        }

        [parsedCTAs addObject:parsedCTA];
    }

    NSNumber *showCloseButton = userData[@"close"];
    if ((id)showCloseButton == [NSNull null]) {
        showCloseButton = nil;
    }

    if (showCloseButton != nil && ![showCloseButton isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'close' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *attachCTAsBottom = userData[@"attach_cta_bottom"];
    if ((id)attachCTAsBottom == [NSNull null]) {
        attachCTAsBottom = nil;
    }

    if (attachCTAsBottom != nil && ![attachCTAsBottom isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'attach_cta_bottom' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *stackCTAsH = userData[@"stack_cta_h"];
    if ((id)stackCTAsH == [NSNull null]) {
        stackCTAsH = nil;
    }

    if (stackCTAsH != nil && ![stackCTAsH isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'stack_cta_h' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *stretchCTAsH = userData[@"stretch_cta_h"];
    if ((id)stretchCTAsH == [NSNull null]) {
        stretchCTAsH = nil;
    }

    if (stretchCTAsH != nil && ![stretchCTAsH isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'stretch_cta_h' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *flipHeroVertical = userData[@"flip_hero_v"];
    if ((id)flipHeroVertical == [NSNull null]) {
        flipHeroVertical = nil;
    }

    if (flipHeroVertical != nil && ![flipHeroVertical isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'flip_hero_v' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *flipHeroHorizontal = userData[@"flip_hero_h"];
    if ((id)flipHeroHorizontal == [NSNull null]) {
        flipHeroHorizontal = nil;
    }

    if (flipHeroHorizontal != nil && ![flipHeroHorizontal isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'flip_hero_h' is not nil but not a NSNumber"];
        return nil;
    }

    NSNumber *heroSplitRatio = userData[@"hero_split_ratio"];
    if ((id)heroSplitRatio == [NSNull null]) {
        heroSplitRatio = nil;
    }

    if (heroSplitRatio != nil && ![heroSplitRatio isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'hero_split_ratio' is not nil but not a NSNumber"];
        return nil;
    }

    // Hero split ratio sanity checks
    if (heroSplitRatio != nil) {
        float heroSplitRatioFloatValue = [heroSplitRatio floatValue];
        if (heroSplitRatioFloatValue <= 0 || heroSplitRatioFloatValue >= 1) {
            [BAMSGPayloadParser
                printGenericDebugLog:
                    @"Universal: 'hero_split_ratio' is less or equal than 0 or greater than or equal to 1. Ignoring"];
            heroSplitRatio = nil;
        }
    }

    NSNumber *autoClose = userData[@"auto_close"];
    if ((id)autoClose == [NSNull null]) {
        autoClose = nil;
    }

    if (autoClose != nil && ![autoClose isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'auto_close' is not nil but not a NSNumber"];
        return nil;
    }

    universal.headingText = heading;
    universal.titleText = title;
    universal.subtitleText = subtitle;
    universal.ctas = parsedCTAs;
    universal.css = css;
    universal.heroImageURL = hero;
    universal.videoURL = video;
    universal.heroDescription = heroDescription;
    universal.heroSplitRatio = heroSplitRatio;

    if (showCloseButton != nil) {
        universal.showCloseButton = [showCloseButton boolValue];
    }

    if (attachCTAsBottom != nil) {
        universal.attachCTAsBottom = [attachCTAsBottom boolValue];
    }

    if (stackCTAsH != nil) {
        universal.stackCTAsHorizontally = [stackCTAsH boolValue];
    }

    if (stretchCTAsH != nil) {
        universal.stretchCTAsHorizontally = [stretchCTAsH boolValue];
    }

    if (flipHeroHorizontal != nil) {
        universal.flipHeroHorizontal = [flipHeroHorizontal boolValue];
    }

    if (flipHeroVertical != nil) {
        universal.flipHeroVertical = [flipHeroVertical boolValue];
    }
    if (autoClose != nil) {
        universal.autoClose = [autoClose doubleValue] / 1000.0;
    }

    return universal;
}

/**
 Parses shared banner attributes into an existing object, which should already has shared message information parsed

 Returns true if succeeded, false if errored
 */
+ (BOOL)parseBaseBannerMessage:(NSDictionary *_Nonnull)userData intoObject:(BAMSGMessageBaseBanner *_Nonnull)banner {
    if (!banner) {
        return false;
    }

    NSString *title = userData[@"title"];
    if ((id)title == [NSNull null]) {
        title = nil;
    }

    if (title != nil && ![title isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'title' is not nil but not a NSString"];
        return false;
    }

    if ([title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        title = nil;
    }

    NSString *css = userData[@"style"];
    if (![css isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'style' is not a NSString"];
        return false;
    }

    NSString *imageURL = userData[@"image"];
    if ((id)imageURL == [NSNull null]) {
        imageURL = nil;
    }
    if (imageURL != nil && ![imageURL isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'image' is not nil but not a NSString"];
        return false;
    }

    NSString *imageDescription = userData[@"image_description"];
    if ((id)imageDescription == [NSNull null]) {
        imageDescription = nil;
    }
    if (imageDescription != nil && ![imageDescription isKindOfClass:[NSString class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'image_description' is not nil but not a NSString"];
        return false;
    }

    NSMutableArray<BAMSGCTA *> *parsedCTAs = [NSMutableArray new];

    NSArray *ctas = userData[@"cta"];
    if ((id)ctas == [NSNull null]) {
        ctas = nil;
    }

    if (ctas != nil && ![ctas isKindOfClass:[NSArray class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'ctas' is not nil but not a NSArray"];
        return false;
    }

    for (NSDictionary *cta in ctas) {
        if (![cta isKindOfClass:[NSDictionary class]]) {
            [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'cta' is not a NSDictionary, skipping"];
            continue;
        }

        BAMSGCTA *parsedCTA = [BAMSGPayloadParser parseCTA:cta];

        if (!parsedCTA) {
            return false;
        }

        [parsedCTAs addObject:parsedCTA];
    }

    NSNumber *showCloseButton = userData[@"close"];
    if ((id)showCloseButton == [NSNull null]) {
        showCloseButton = nil;
    }

    if (showCloseButton != nil && ![showCloseButton isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'close' is not nil but not a NSNumber"];
        return false;
    }

    NSString *ctaDirection = userData[@"cta_direction"];
    if ((id)ctaDirection == [NSNull null]) {
        ctaDirection = nil;
    }

    if (ctaDirection != nil) {
        if (![ctaDirection isKindOfClass:[NSString class]]) {
            [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'cta_direction' is not nil but not a NSString"];
            return false;
        }
        ctaDirection = [ctaDirection lowercaseString];
        if ([@"h" isEqualToString:ctaDirection]) {
            banner.ctaDirection = BAMSGBannerCTADirectionHorizontal;
        } else if ([@"v" isEqualToString:ctaDirection]) {
            banner.ctaDirection = BAMSGBannerCTADirectionVertical;
        } else {
            [BAMSGPayloadParser
                printGenericDebugLog:@"Base banner: 'ctaDirection' is a NSString but neither 'h' or 'v': ignoring."];
        }
    }

    NSNumber *allowSwipeToDismiss = userData[@"swipe_dismiss"];
    if ((id)allowSwipeToDismiss == [NSNull null]) {
        allowSwipeToDismiss = nil;
    }

    if (allowSwipeToDismiss != nil && ![allowSwipeToDismiss isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'swipe_dismiss' is not nil but not a NSNumber"];
        return false;
    }

    NSDictionary *rawGlobalTapAction = userData[@"action"];
    if ((id)rawGlobalTapAction == [NSNull null]) {
        rawGlobalTapAction = nil;
    }

    if (rawGlobalTapAction != nil && ![rawGlobalTapAction isKindOfClass:[NSDictionary class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'action' is not nil but not a NSDictionary"];
        return false;
    }

    NSNumber *globalTapDelay = userData[@"global_tap_delay"];
    if ((id)globalTapDelay == [NSNull null]) {
        globalTapDelay = nil;
    }

    if (globalTapDelay != nil && ![globalTapDelay isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'global_tap_delay' is not nil but not a NSNumber"];
        return false;
    }

    NSNumber *autoClose = userData[@"auto_close"];
    if ((id)autoClose == [NSNull null]) {
        autoClose = nil;
    }

    if (autoClose != nil && ![autoClose isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Base banner: 'auto_close' is not nil but not a NSNumber"];
        return false;
    }

    banner.titleText = title;
    banner.ctas = parsedCTAs;
    banner.css = css;
    banner.imageURL = imageURL;
    banner.imageDescription = imageDescription;

    if (showCloseButton != nil) {
        banner.showCloseButton = [showCloseButton boolValue];
    }

    if (allowSwipeToDismiss != nil) {
        banner.allowSwipeToDismiss = [allowSwipeToDismiss boolValue];
    }

    if (rawGlobalTapAction) {
        banner.globalTapAction = [self parseGlobalAction:rawGlobalTapAction];
    }

    if (globalTapDelay != nil) {
        banner.globalTapDelay = [globalTapDelay doubleValue] / 1000.0;
    }

    if (autoClose != nil) {
        banner.autoClose = [autoClose doubleValue] / 1000.0;
    }

    return true;
}

+ (BAMSGMessageBanner *_Nullable)parseBannerMessage:(NSDictionary *_Nonnull)userData
                                     withBaseObject:(BAMSGMessageBanner *_Nonnull)banner {
    return [self parseBaseBannerMessage:userData intoObject:banner] ? banner : nil;
}

+ (BAMSGMessageModal *_Nullable)parseModalMessage:(NSDictionary *_Nonnull)userData
                                   withBaseObject:(BAMSGMessageModal *_Nonnull)modal {
    return [self parseBaseBannerMessage:userData intoObject:modal] ? modal : nil;
}

+ (BAMSGMessageImage *_Nullable)parseImageMessage:(NSDictionary *_Nonnull)userData
                                   withBaseObject:(BAMSGMessageImage *_Nonnull)image {
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:userData errorDomain:LOGGER_DOMAIN];

    image.allowSwipeToDismiss = [[json objectForKey:@"swipe_dismiss" kindOfClass:[NSNumber class]
                                           fallback:@(true)] boolValue];

    // fullscreen
    image.isFullscreen = [[json objectForKey:@"fullscreen" kindOfClass:[NSNumber class] fallback:@(true)] boolValue];
    // image
    image.imageURL = [json objectForKey:@"image" kindOfClass:[NSString class] fallback:nil];
    if ([image.imageURL length] == 0) {
        [BAMSGPayloadParser printGenericDebugLog:@"Image: 'image' is required and can't be empty"];
        return nil;
    }
    // width
    CGFloat width = [[json objectForKey:@"width" kindOfClass:[NSNumber class] fallback:@0] doubleValue];
    // height
    CGFloat height = [[json objectForKey:@"height" kindOfClass:[NSNumber class] fallback:@0] doubleValue];
    // fallback on CGSizeZero if no width or height are specified. Message presenter will morph to the right size upon
    // image download.
    image.imageSize = (width == 0 || height == 0) ? CGSizeZero : CGSizeMake(width, height);

    // image_description
    image.imageDescription = [json objectForKey:@"image_description" kindOfClass:[NSString class] fallback:@""];
    // action
    NSError *err;
    NSDictionary *actionDict = [json objectForKey:@"action" kindOfClass:[NSDictionary class] allowNil:false error:&err];
    if (err != nil) {
        [BAMSGPayloadParser
            printGenericDebugLog:[NSString
                                     stringWithFormat:@"Image: 'action' couldn't be parsed properly. Err: %@", err]];
        return nil;
    }
    image.globalTapAction = [self parseGlobalAction:actionDict];
    if (image.globalTapAction == nil) {
        [BAMSGPayloadParser printGenericDebugLog:@"Image: 'action' is required"];
        return nil;
    }
    // style
    image.css = [json objectForKey:@"style" kindOfClass:[NSString class] fallback:@""];

    // auto_close
    NSNumber *autoClose = userData[@"auto_close"];
    if ((id)autoClose == [NSNull null]) {
        autoClose = nil;
    }
    if (autoClose != nil && ![autoClose isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Universal: 'auto_close' is not nil but not a NSNumber"];
        return nil;
    }

    // global_tap_delay
    NSNumber *globalTapDelay = userData[@"global_tap_delay"];
    if ((id)globalTapDelay == [NSNull null]) {
        globalTapDelay = nil;
    }

    if (globalTapDelay != nil && ![globalTapDelay isKindOfClass:[NSNumber class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Image: 'global_tap_delay' is not nil but not a NSNumber"];
        return false;
    }

    if (autoClose != nil) {
        image.autoClose = [autoClose doubleValue] / 1000.0;
    }

    if (globalTapDelay != nil) {
        image.globalTapDelay = [globalTapDelay doubleValue] / 1000.0;
    }

    return image;
}

+ (BAMSGMessageWebView *_Nullable)parseWebViewMessage:(NSDictionary *_Nonnull)userData
                                       withBaseObject:(BAMSGMessageWebView *_Nonnull)webViewMessage {
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:userData errorDomain:LOGGER_DOMAIN];

    // url
    NSError *err;
    NSString *rawURL = [json objectForKey:@"url" kindOfClass:[NSString class] allowNil:false error:&err];
    if (err != nil) {
        [BAMSGPayloadParser
            printGenericDebugLog:[NSString stringWithFormat:@"Image: 'url' couldn't be parsed properly. Err: %@", err]];
        return nil;
    }
    NSURL *url = [NSURL URLWithString:rawURL];
    if (url == nil) {
        [BAMSGPayloadParser printGenericDebugLog:[NSString stringWithFormat:@"Image: 'url' is not a valid URL."]];
        return nil;
    }
    NSString *scheme = [url.scheme lowercaseString];
    if (![@"http" isEqualToString:scheme] && ![@"https" isEqualToString:scheme]) {
        [BAMSGPayloadParser
            printGenericDebugLog:
                [NSString
                    stringWithFormat:@"Image: 'url' is not valid: only HTTP and HTTPS URL schemes are supported."]];
        return nil;
    }
    webViewMessage.url = url;

    // style
    webViewMessage.css = [json objectForKey:@"style" kindOfClass:[NSString class] fallback:@""];

    NSNumber *devMode = [json objectForKey:@"dev" kindOfClass:[NSNumber class] fallback:@(false)];
    webViewMessage.developmentMode = [devMode boolValue];

    NSNumber *openDeeplinksInApp = [json objectForKey:@"inAppDeeplinks" kindOfClass:[NSNumber class] fallback:@(false)];
    webViewMessage.openDeeplinksInApp = [openDeeplinksInApp boolValue];

    NSNumber *timeout = [json objectForKey:@"timeout" kindOfClass:[NSNumber class] fallback:@(0)];
    webViewMessage.timeout = [timeout doubleValue] / 1000.0;

    NSNumber *layoutWorkaround = [json objectForKey:@"iOSLayoutWorkaround" kindOfClass:[NSNumber class] fallback:nil];
    if (layoutWorkaround != nil) {
        switch (layoutWorkaround.integerValue) {
            case 0:
                webViewMessage.layoutWorkaround = BAMSGWebViewLayoutWorkaroundDoNothing;
                break;
            case 1:
                webViewMessage.layoutWorkaround = BAMSGWebViewLayoutWorkaroundRelayoutPeriodically;
                break;
            case 2:
                webViewMessage.layoutWorkaround = BAMSGWebViewLayoutWorkaroundApplyInsetsNatively;
                break;
        }
    }

    return webViewMessage;
}

+ (BAMSGAction *_Nullable)parseGlobalAction:(NSDictionary *_Nonnull)userData {
    if (userData == nil) {
        return nil;
    }

    NSString *actionString = userData[@"a"];
    if ((id)actionString == [NSNull null]) {
        actionString = nil;
    }
    if (actionString != nil &&
        (![actionString isKindOfClass:[NSString class]] ||
         [actionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)) {
        [BAMSGPayloadParser printGenericDebugLog:@"Global Action: 'action' is not nil but not a NSString or is empty"];
        return nil;
    }

    NSDictionary<NSString *, NSObject *> *args = userData[@"args"];
    if ((id)args == [NSNull null]) {
        args = nil;
    }

    if (args != nil && ![args isKindOfClass:[NSDictionary class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"Global Action: 'args' is not nil but not a NSDictionary"];
        return nil;
    }

    BAMSGAction *action = [[BAMSGAction alloc] init];
    action.actionIdentifier = actionString;
    action.actionArguments = args != nil ? args : [NSDictionary new];

    return action;
}

+ (BAMSGCTA *_Nullable)parseCTA:(NSDictionary *_Nonnull)userData {
    NSString *label = userData[@"l"];
    if (![label isKindOfClass:[NSString class]] ||
        [label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) {
        [BAMSGPayloadParser printGenericDebugLog:@"CTA: 'label' is not a NSString or is empty"];
        return nil;
    }

    NSString *action = userData[@"a"];
    if ((id)action == [NSNull null]) {
        action = nil;
    }
    if (action != nil &&
        (![action isKindOfClass:[NSString class]] ||
         [action stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0)) {
        [BAMSGPayloadParser printGenericDebugLog:@"CTA: 'action' is not nil but not a NSString or is empty"];
        return nil;
    }

    NSDictionary<NSString *, NSObject *> *args = userData[@"args"];
    if ((id)args == [NSNull null]) {
        args = nil;
    }

    if (args != nil && ![args isKindOfClass:[NSDictionary class]]) {
        [BAMSGPayloadParser printGenericDebugLog:@"CTA: 'args' is not nil but not a NSDictionary"];
        return nil;
    }

    BAMSGCTA *cta = [[BAMSGCTA alloc] init];
    cta.label = label;
    cta.actionIdentifier = action;
    cta.actionArguments = args != nil ? args : [NSDictionary new];

    return cta;
}

+ (void)printGenericDebugLog:(NSString *)msg {
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Error while decoding payload: %@", msg];
}

@end
