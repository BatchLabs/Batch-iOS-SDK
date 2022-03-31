//
//  BAUnlockPlugin.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import "BatchUnlock.h"

#import "BAUnlockWebservice.h"
#import "BAWebserviceMulticastDelegate.h"
#import "BAWebservicePool.h"

#import "BACoreCenter.h"
#import "BAUnlockCenter.h"

#import "BAItems.h"
#import "BAParameter.h"

#import "BAWebserviceQueryCode.h"
#import "BAWebserviceQueryConditional.h"
#import "BAWebserviceQueryConditionalCode.h"
#import "BAWebserviceQueryRestore.h"
#import "BAWebserviceQueryUnlockAutomatic.h"

#import "BAWebserviceResponseCode.h"
#import "BAWebserviceResponseConditional.h"
#import "BAWebserviceResponseConditionalCode.h"
#import "BAWebserviceResponseRestore.h"
#import "BAWebserviceResponseUnlockAutomatic.h"
#import "BAWebserviceResponseValidation.h"

#import "BAErrorHelper.h"
#import "BARandom.h"
#import "BAStringUtils.h"

@implementation BAUnlockWebservice

static const NSString *WebserviceUnlockIdentifierUnlockAuto = @"unlockauto";
static const NSString *WebserviceUnlockIdentifierCallback = @"callback";
static const NSString *WebserviceUnlockIdentifierCodeCallback = @"codecallback";
static const NSString *WebserviceUnlockIdentifierCode = @"code";
static const NSString *WebserviceUnlockIdentifierRestore = @"restore";

+ (NSString *)cryptorKeyForWebserviceType:(NSString *)type {
    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:type] ||
        [WebserviceUnlockIdentifierCallback isEqualToString:type] ||
        [WebserviceUnlockIdentifierCodeCallback isEqualToString:type] ||
        [WebserviceUnlockIdentifierCode isEqualToString:type] ||
        [WebserviceUnlockIdentifierRestore isEqualToString:type]) {
        return [NSString stringWithFormat:@"%@%irM", BAPrivateKeyWebservice, 33];
    }

    return nil;
}

+ (NSString *)urlForWebserviceType:(NSString *)type userInfo:(NSDictionary *)info {
    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:type]) {
        return [NSString stringWithFormat:@"%@/%@", kParametersUnlockAutoWebserviceURL,
                                          [[BACoreCenter instance].configuration developperKey]];
    } else if ([WebserviceUnlockIdentifierCallback isEqualToString:type]) {
        return [NSString stringWithFormat:@"%@/%@", kParametersCBWebserviceURL,
                                          [[BACoreCenter instance].configuration developperKey]];
    } else if ([WebserviceUnlockIdentifierCodeCallback isEqualToString:type]) {
        NSString *code = [info objectForKey:@"code"];
        return [NSString stringWithFormat:@"%@/%@/%@", kParametersCBCodeWebserviceURL,
                                          [[BACoreCenter instance].configuration developperKey],
                                          [BAStringUtils encodeString:code withEncoding:NSUTF8StringEncoding]];
    } else if ([WebserviceUnlockIdentifierCode isEqualToString:type]) {
        NSString *code = [info objectForKey:@"code"];
        return [NSString stringWithFormat:@"%@/%@/%@", kParametersCodeWebserviceURL,
                                          [[BACoreCenter instance].configuration developperKey],
                                          [BAStringUtils encodeString:code withEncoding:NSUTF8StringEncoding]];
    } else if ([WebserviceUnlockIdentifierRestore isEqualToString:type]) {
        return [NSString stringWithFormat:@"%@/%@", kParametersRestoreWebserviceURL,
                                          [[BACoreCenter instance].configuration developperKey]];
    }

    return nil;
}

+ (NSString *)shortNameForWebserviceType:(NSString *)type userInfo:(NSDictionary *)info {
    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:type]) {
        return kParametersUnlockAutoWebserviceShortname;
    } else if ([WebserviceUnlockIdentifierCallback isEqualToString:type]) {
        return kParametersCBWebserviceShortname;
    } else if ([WebserviceUnlockIdentifierCodeCallback isEqualToString:type]) {
        return kParametersCBCodeWebserviceShortname;
    } else if ([WebserviceUnlockIdentifierCode isEqualToString:type]) {
        return kParametersCodeWebserviceShortname;
    } else if ([WebserviceUnlockIdentifierRestore isEqualToString:type]) {
        return kParametersRestoreWebserviceShortname;
    }

    return nil;
}

+ (NSArray *)queriesForWebservice:(BAStandardWebservice *)webservice {
    NSMutableArray *queries = [[NSMutableArray alloc] init];

    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:webservice.type]) {
        BAWebserviceQueryUnlockAutomatic *autoQuery =
            [[BAWebserviceQueryUnlockAutomatic alloc] initWithIdentifier:[BARandom generateUUID]];
        [queries addObject:autoQuery];
    } else if ([WebserviceUnlockIdentifierCallback isEqualToString:webservice.type]) {
        NSArray *condition = [webservice.userInfo objectForKey:@"conditions"];

        BAWebserviceQueryConditional *callbackQuery =
            [[BAWebserviceQueryConditional alloc] initWithIdentifier:[BARandom generateUUID] andConditions:condition];
        [queries addObject:callbackQuery];
    } else if ([WebserviceUnlockIdentifierCodeCallback isEqualToString:webservice.type]) {
        NSString *code = [webservice.userInfo objectForKey:@"code"];
        NSArray *condition = [webservice.userInfo objectForKey:@"conditions"];

        BAWebserviceQueryConditionalCode *codeCallbackQuery =
            [[BAWebserviceQueryConditionalCode alloc] initWithIdentifier:[BARandom generateUUID]
                                                                    code:code
                                                           andConditions:condition];
        [queries addObject:codeCallbackQuery];
    } else if ([WebserviceUnlockIdentifierCode isEqualToString:webservice.type]) {
        NSString *code = [webservice.userInfo objectForKey:@"code"];
        BOOL external = [[webservice.userInfo objectForKey:@"external"] boolValue];

        BAWebserviceQueryCode *codeQuery = [[BAWebserviceQueryCode alloc] initWithIdentifier:[BARandom generateUUID]
                                                                                     andCode:code];
        [codeQuery setExternal:external];
        [queries addObject:codeQuery];
    } else if ([WebserviceUnlockIdentifierRestore isEqualToString:webservice.type]) {
        BAWebserviceQueryRestore *restoreQuery =
            [[BAWebserviceQueryRestore alloc] initWithIdentifier:[BARandom generateUUID]];
        [queries addObject:restoreQuery];
    }

    return queries;
}

+ (BAWebserviceResponse *)responseForQuery:(BAWebserviceQuery *)query content:(NSDictionary *)content {
    // Build the webservice response.
    switch ([query type]) {
        case BAWebserviceQueryTypeUnlockAutomatic:
            return [[BAWebserviceResponseUnlockAutomatic alloc] initWithResponse:content];

        case BAWebserviceQueryTypeConditional:
            return [[BAWebserviceResponseConditional alloc] initWithResponse:content];

        case BAWebserviceQueryTypeCode:
            return [[BAWebserviceResponseCode alloc] initWithResponse:content];

        case BAWebserviceQueryTypeConditionalCode:
            return [[BAWebserviceResponseConditionalCode alloc] initWithResponse:content];

        case BAWebserviceQueryTypeRestore:
            return [[BAWebserviceResponseRestore alloc] initWithResponse:content];

        case BAWebserviceQueryTypeValidation:
            return [[BAWebserviceResponseValidation alloc] initWithResponse:content];

        default:
            return nil;
    }
}

+ (void)webservice:(BAStandardWebservice *)webservice didFailWithError:(BatchError *)error {
    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:webservice.type]) {
        [BALogger errorForDomain:ERROR_DOMAIN message:@"Automatic unlock failure: %@", [error localizedDescription]];
    } else if ([WebserviceUnlockIdentifierCallback isEqualToString:webservice.type]) {
        [BALogger errorForDomain:ERROR_DOMAIN message:@"Automatic unlock failure: %@", [error localizedDescription]];
    } else if ([WebserviceUnlockIdentifierCodeCallback isEqualToString:webservice.type]) {
        [BAUnlockWebservice codeFail:error forWebservice:webservice];
    } else if ([WebserviceUnlockIdentifierCode isEqualToString:webservice.type]) {
        [BAUnlockWebservice codeFail:error forWebservice:webservice];
    } else if ([WebserviceUnlockIdentifierRestore isEqualToString:webservice.type]) {
        BatchFail fail = [webservice.userInfo objectForKey:@"failBlock"];
        fail(error);
    }
}

+ (void)webservice:(BAStandardWebservice *)webservice didSuccedWithResponses:(NSArray *)responses {
    if ([WebserviceUnlockIdentifierUnlockAuto isEqualToString:webservice.type]) {
        for (BAWebserviceResponse *response in responses) {
            // Start query response.
            if ([response isMemberOfClass:[BAWebserviceResponseUnlockAutomatic class]] == YES) {
                // Retrieve new offers.
                NSArray *offers = [(BAWebserviceResponseUnlockAutomatic *)response offers];

                // Call the delegate only if at least one offer has been found.
                if ([BANullHelper isArrayEmpty:offers] == NO) {
                    // Callback offer.
                    for (BAOffer *offer in offers) {
                        [[BAUnlockCenter instance].unlockDelegate automaticOfferRedeemed:offer];
                    }
                }

                // Retrieve new conditions.
                NSArray *conditions = [(BAWebserviceResponseUnlockAutomatic *)response conditions];

                if ([BANullHelper isArrayEmpty:conditions] == NO) {
                    // Send conditions.
                    __block BAStandardWebservice *conditionWebservice =
                        [[BAStandardWebservice alloc] initWithType:@"callback"
                                                        identifier:nil
                                                          userInfo:@{@"conditions" : conditions}];

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                      [BAWebservicePool addWebservice:conditionWebservice];
                    });
                }
            }
            // Validation query response.
            else if ([response isMemberOfClass:[BAWebserviceResponseValidation class]] == YES) {
                // Treat validated tokens.
                NSArray *validTokens = [(BAWebserviceResponseValidation *)response validTokens];

                if ([BANullHelper isArrayEmpty:validTokens] == NO) {
                    for (BAOffer *offer in [(BAWebserviceResponseValidation *)response offers]) {
                        [[BAUnlockCenter instance].unlockDelegate automaticOfferRedeemed:offer];
                    }
                }

                // Treat invalidated tokens.
                NSArray *invalidTokens = [(BAWebserviceResponseValidation *)response invalidTokens];

                if ([BANullHelper isArrayEmpty:invalidTokens] == NO) {
                    // Remove invalid features in saved features.
                    [[BAUnlockCenter instance].unusedOffers removeTokens:invalidTokens];
                }
            }
        }
    } else if ([WebserviceUnlockIdentifierCallback isEqualToString:webservice.type]) {
        for (BAWebserviceResponse *response in responses) {
            if ([response isMemberOfClass:[BAWebserviceResponseConditional class]] == YES) {
                // Retrieve new offers.
                NSArray *offers = [(BAWebserviceResponseConditional *)response offers];

                if ([BANullHelper isArrayEmpty:offers] == NO) {
                    // Callback offer.
                    for (BAOffer *offer in offers) {
                        [[BAUnlockCenter instance].unlockDelegate automaticOfferRedeemed:offer];
                    }
                }
            }
        }
    } else if ([WebserviceUnlockIdentifierCodeCallback isEqualToString:webservice.type]) {
        for (BAWebserviceResponse *response in responses) {
            if ([response isMemberOfClass:[BAWebserviceResponseConditionalCode class]] == YES) {
                BAOfferCodeResponse status = [(BAWebserviceResponseConditionalCode *)response status];
                if (status == BAOfferCodeResponseNone) {
                    [BAUnlockWebservice codeFail:[BAErrorHelper serverError] forWebservice:webservice];
                    return;
                }

                // Valid status.
                if (status == BAOfferCodeResponseSuccess) {
                    // Retrieve new offer.
                    BAOffer *offer = [(BAWebserviceResponseConditionalCode *)response offer];

                    if ([BANullHelper isNull:offer] == NO) {
                        // Callback offer.
                        [BAUnlockWebservice codeSucced:offer forWebservice:webservice];
                    } else {
                        BatchError *error = [(BAWebserviceResponse *)response error];

                        if ([BANullHelper isNull:error] == YES) {
                            error = [BAErrorHelper serverError];
                        }

                        [BAUnlockWebservice codeFail:error forWebservice:webservice];
                        return;
                    }
                }
                // Other failure reasons.
                else {
                    BatchError *error = [(BAWebserviceResponse *)response error];

                    if ([BANullHelper isNull:error] == YES) {
                        error = [BAErrorHelper serverError];
                    }

                    // Callback offer.
                    [BAUnlockWebservice codeFail:error forWebservice:webservice];
                    return;
                }
            }
        }
    } else if ([WebserviceUnlockIdentifierCode isEqualToString:webservice.type]) {
        for (BAWebserviceResponse *response in responses) {
            if ([response isMemberOfClass:[BAWebserviceResponseCode class]] == YES) {
                BAOfferCodeResponse status = [(BAWebserviceResponseCode *)response status];
                if (status == BAOfferCodeResponseNone) {
                    [BAUnlockWebservice codeFail:[BAErrorHelper serverError] forWebservice:webservice];
                    return;
                }

                // Conditions needed.
                if (status == BAOfferCodeNeedConditions) {
                    // Retrieve new conditions.
                    NSArray *conditions = [(BAWebserviceResponseCode *)response conditions];

                    if ([BANullHelper isArrayEmpty:conditions] == NO) {
                        // Send conditions.
                        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:webservice.userInfo];
                        [info setValue:conditions forKeyPath:@"conditions"];
                        __block BAStandardWebservice *callbackWebservice =
                            [[BAStandardWebservice alloc] initWithType:@"codecallback" identifier:nil userInfo:info];

                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          [BAWebservicePool addWebservice:callbackWebservice];
                        });
                    } else {
                        [BAUnlockWebservice codeFail:[BAErrorHelper serverError] forWebservice:webservice];
                        return;
                    }
                }
                // On fail to retreive a valid state.
                else if (status == BAOfferCodeResponseSuccess) {
                    // Retrieve new offer.
                    BAOffer *offer = [(BAWebserviceResponseCode *)response offer];

                    if ([BANullHelper isNull:offer] == NO) {
                        // Callback offer.
                        [BAUnlockWebservice codeSucced:offer forWebservice:webservice];
                    } else {
                        [BAUnlockWebservice codeFail:[BAErrorHelper serverError] forWebservice:webservice];
                        return;
                    }
                }
                // Other failure reasons.
                else {
                    BatchError *error = [(BAWebserviceResponse *)response error];

                    if ([BANullHelper isNull:error] == YES) {
                        error = [BAErrorHelper serverError];
                    }

                    // Callback offer.
                    [BAUnlockWebservice codeFail:error forWebservice:webservice];
                    return;
                }
            }
        }
    } else if ([WebserviceUnlockIdentifierRestore isEqualToString:webservice.type]) {
        BatchRestoreSuccess sucess = [webservice.userInfo objectForKey:@"successBlock"];
        BatchFail fail = [webservice.userInfo objectForKey:@"failBlock"];

        if (sucess == nil || fail == nil) {
            [BALogger errorForDomain:@"UnlockWebservice" message:@"Missing restore block."];
        } else {
            for (BAWebserviceResponse *response in responses) {
                if ([response isMemberOfClass:[BAWebserviceResponseRestore class]] == YES) {
                    // Retrieve new offers.
                    BAItems *items = [(BAWebserviceResponseRestore *)response items];

                    if ([BANullHelper isNull:items] == NO) {
                        // Callback offer.
                        sucess(items.features);
                    } else {
                        // Send an empty result.
                        sucess(@[]);
                    }
                } else {
                    fail([BAErrorHelper serverError]);
                }
            }
        }
    }
}

+ (void)codeFail:(BatchError *)error forWebservice:(BAStandardWebservice *)webservice {
    BOOL external = [[webservice.userInfo objectForKey:@"external"] boolValue];
    if (external) {
        [[BAUnlockCenter instance].unlockDelegate URLWithCodeFailed:error];
    } else {
        BatchFail fail = [webservice.userInfo objectForKey:@"failBlock"];
        fail(error);
    }
}

+ (void)codeSucced:(BAOffer *)offer forWebservice:(BAStandardWebservice *)webservice {
    BOOL external = [[webservice.userInfo objectForKey:@"external"] boolValue];
    if (external) {
        [[BAUnlockCenter instance].unlockDelegate URLWithCodeRedeemed:offer];
    } else {
        BatchSuccess sucess = [webservice.userInfo objectForKey:@"successBlock"];
        sucess(offer);
    }
}

@end
