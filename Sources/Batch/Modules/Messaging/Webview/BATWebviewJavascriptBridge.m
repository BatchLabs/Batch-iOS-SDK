//
//  BATWebviewJavascriptBridge.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATWebviewJavascriptBridge.h"
#import <Batch/BAInstallationID.h>
#import <Batch/BAJson.h>
#import <Batch/BANullHelper.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAUserProfile.h>
#import <Batch/BatchMessagingModels.h>
#import <Batch/BatchMessagingPrivate.h>
#import <Batch/BatchUser.h>

#define LOGGER_DOMAIN @"WebviewBridge"

typedef NS_ENUM(NSInteger, BATWebviewBridgeInternalErrorCode) {
    BATWebviewBridgeInternalErrorCodeCustomPayloadJSONFailure = -10,
    BATWebviewBridgeInternalErrorCodeMethodParsingFailure = -20,
    BATWebviewBridgeInternalErrorCodeArgumentsJSONFailure = -21,
    BATWebviewBridgeInternalErrorCodeOpenDeeplinkJSONFailure = -22,
    BATWebviewBridgeInternalErrorCodePerformActionJSONFailure = -23,
    BATWebviewBridgeInternalErrorCodePerformActionArgsJSONFailure = -24,
};

/**
 Shared implementation for the Webview Javascript Bridge
 Allows for different iOS 13- and iOS 14+ message implementations: iOS 14 supports replying directly from the message
handler without having to eval anything
 */
@implementation BATWebviewJavascriptBridge {
    BAMSGMessage *_message;
    __weak id<BATWebviewJavascriptBridgeDelegate> _delegate;
}

- (instancetype)initWithMessage:(nonnull BAMSGMessage *)message
                       delegate:(nullable id<BATWebviewJavascriptBridgeDelegate>)delegate {
    self = [super init];
    if (self) {
        _message = message;
        _delegate = delegate;
    }
    return self;
}

/**
 Returns a promise that will resolve to, or fail with a public error message
 This method does all of the heavy lifting (argument checking, error handling): just give the bridge the result or error
 of this promise.
 */
- (nonnull BAPromise<NSString *> *)executeBridgeMethod:(nullable NSString *)method
                                             arguments:(nullable NSDictionary *)rawJSONArguments {
    // Our promises don't (yet) implement chaining so we have to do this little forwarding dance
    BAPromise *outerPromise = [BAPromise new];

    BAPromise *internalPromise = [self internalExecuteMethod:method arguments:rawJSONArguments];

    [internalPromise then:^(NSObject *_Nullable value) {
      [outerPromise resolve:value];
    }];

    [internalPromise catch:^(NSError *_Nullable error) {
      NSError *outerError;
      if (error.code == BATWebviewJavascriptBridgeErrorCodePublicError) {
          outerError = error;
      } else if (error.code == BATWebviewJavascriptBridgeErrorCodeInternalError) {
          NSString *internalError = error.userInfo[NSLocalizedFailureReasonErrorKey];
          if (internalError == nil) {
              internalError = @"Unknown";
          }
          NSString *errorCode = error.userInfo[NSLocalizedDescriptionKey];
          if (errorCode == nil) {
              errorCode = @"1";
          }
          [BALogger errorForDomain:LOGGER_DOMAIN message:@"Internal bridge error (%@): %@", internalError, errorCode];
          outerError = [self makePublicError:[NSString stringWithFormat:@"Internal error (%@)", errorCode]];
      } else if (error.code == BATWebviewJavascriptBridgeErrorCodeUnkownMethod) {
          [BALogger errorForDomain:LOGGER_DOMAIN
                           message:@"Bridge couldn't execute unknown method '%@'", error.userInfo[@"methodName"]];
          outerError = [self makePublicError:error.localizedDescription];
      } else {
          [BALogger errorForDomain:LOGGER_DOMAIN
                           message:@"Bridge raised an error, but could not be translated to a public error: %@",
                                   error.localizedDescription];
          outerError = [self makePublicError:[NSString stringWithFormat:@"Internal error (2)"]];
      }
      [outerPromise reject:outerError];
    }];

    return outerPromise;
}

/**
 Returns a promise that will resolve to, or fail with the internal error message
 This allows for the public api boundary to easily rewrite all errors, and for other uses/tests of this method to easily
 get the "real" errors.
 */
- (nonnull BAPromise<NSString *> *)internalExecuteMethod:(nullable NSString *)method
                                               arguments:(nullable NSDictionary *)args {
    if ([BANullHelper isStringEmpty:method]) {
        return [BAPromise
            rejected:[self makeInternalError:BATWebviewBridgeInternalErrorCodeMethodParsingFailure
                                      reason:[NSString stringWithFormat:@"Could not parse method name: '%@", method]
                             underlyingError:nil]];
    }

    if (![args isKindOfClass:NSDictionary.class]) {
        return [BAPromise rejected:[self makeInternalError:BATWebviewBridgeInternalErrorCodeArgumentsJSONFailure
                                                    reason:@"Could not parse nil/wrong type JSON method arguments"
                                           underlyingError:nil]];
    }

    return [self resultProviderForMethod:method
                               arguments:[[BATJsonDictionary alloc] initWithDictionary:args
                                                                           errorDomain:BRIDGE_ERROR_DOMAIN]];
}

// Returns the implementation
// All implementations should return a BAPromise
- (nonnull BAPromise<NSString *> *)resultProviderForMethod:(nonnull NSString *)method
                                                 arguments:(nonnull BATJsonDictionary *)arguments {
    NSString *lowerMethod = [method lowercaseString];
    if ([@"getinstallationid" isEqualToString:lowerMethod]) {
        return [self installationID];
    } else if ([@"getattributionid" isEqualToString:lowerMethod]) {
        return [self attributionID];
    } else if ([@"getcustomregion" isEqualToString:lowerMethod]) {
        return [self customRegion];
    } else if ([@"getcustomlanguage" isEqualToString:lowerMethod]) {
        return [self customLanguage];
    } else if ([@"getcustomuserid" isEqualToString:lowerMethod]) {
        return [self customUserID];
    } else if ([@"getcustompayload" isEqualToString:lowerMethod]) {
        return [self customPayload];
    } else if ([@"gettrackingid" isEqualToString:lowerMethod]) {
        return [self trackingID];
    } else if ([@"opendeeplink" isEqualToString:lowerMethod]) {
        return [self openDeeplink:arguments];
    } else if ([@"performaction" isEqualToString:lowerMethod]) {
        return [self performAction:arguments];
    } else if ([@"dismiss" isEqualToString:lowerMethod]) {
        return [self dismiss:arguments];
    } else {
        return [BAPromise rejected:[self makeUnknownMethodError:method]];
    }
}

#pragma mark Bridge method implementations

- (BAPromise<NSString *> *)installationID {
    return [BAPromise resolved:[BAInstallationID installationID]];
}

- (BAPromise<NSString *> *)attributionID {
    return [BAPromise rejected:[self makePublicError:@"Attribution identifier is not supported anymore"]];
}

- (BAPromise<NSString *> *)customRegion {
    return [BAPromise resolved:[BatchUser region]];
}

- (BAPromise<NSString *> *)customLanguage {
    return [BAPromise resolved:[BatchUser language]];
}

- (BAPromise<NSString *> *)customUserID {
    return [BAPromise resolved:[BAUserProfile defaultUserProfile].customIdentifier];
}

- (BAPromise<NSString *> *)customPayload {
    BAPromise *promise = [BAPromise new];

    NSDictionary *payload;
    BatchMessage *sourceMessage = _message.sourceMessage;
    if ([sourceMessage isKindOfClass:BatchInAppMessage.class]) {
        payload = ((BatchInAppMessage *)sourceMessage).customPayload;
    } else if ([sourceMessage isKindOfClass:BatchPushMessage.class]) {
        payload = ((BatchPushMessage *)sourceMessage).pushPayload;
        NSMutableDictionary *cleanPayload = [payload mutableCopy];
        [cleanPayload removeObjectForKey:kWebserviceKeyPushBatchData];
        payload = cleanPayload;
    }

    if (payload == nil) {
        payload = @{};
    }

    NSError *jsonErr = nil;
    NSString *jsonPayload = [BAJson serialize:payload error:&jsonErr];
    if (jsonErr != nil || jsonPayload == nil) {
        [promise reject:[self makeInternalError:BATWebviewBridgeInternalErrorCodeCustomPayloadJSONFailure
                                         reason:@"Could not serialize custom payload to JSON"
                                underlyingError:jsonErr]];
    } else {
        [promise resolve:jsonPayload];
    }

    return promise;
}

- (BAPromise<NSString *> *)trackingID {
    return [BAPromise resolved:_message.sourceMessage.devTrackingIdentifier];
}

- (BAPromise<NSString *> *)openDeeplink:(nonnull BATJsonDictionary *)arguments {
    NSError *outErr = nil;
    NSString *url = [arguments objectForKey:@"url" kindOfClass:NSString.class allowNil:false error:&outErr];
    if ([BANullHelper isStringEmpty:url]) {
        return [BAPromise rejected:[self makeInternalError:BATWebviewBridgeInternalErrorCodeOpenDeeplinkJSONFailure
                                                    reason:@"Cannot perform action: missing or empty URL"
                                           underlyingError:outErr]];
    }

    NSNumber *openInAppOverride = [arguments objectForKey:@"openInApp" kindOfClass:NSNumber.class fallback:nil];
    NSString *analyticsID = [arguments objectForKey:@"analyticsID" kindOfClass:NSString.class fallback:nil];

    [_delegate bridge:self shouldOpenDeeplink:url openInAppOverride:openInAppOverride analyticsID:analyticsID];

    return [self genericResult];
}

- (BAPromise<NSString *> *)performAction:(nonnull BATJsonDictionary *)arguments {
    NSError *outErr = nil;
    NSString *actionName = [arguments objectForKey:@"name" kindOfClass:NSString.class allowNil:false error:&outErr];
    if ([BANullHelper isStringEmpty:actionName]) {
        return [BAPromise rejected:[self makeInternalError:BATWebviewBridgeInternalErrorCodePerformActionJSONFailure
                                                    reason:@"Cannot perform action: missing or empty name"
                                           underlyingError:outErr]];
    }

    outErr = nil;
    NSDictionary *actionArgs =
        [arguments objectForKey:@"args" kindOfClass:NSDictionary.class allowNil:false error:&outErr];
    if (actionArgs == nil) {
        return [BAPromise rejected:[self makeInternalError:BATWebviewBridgeInternalErrorCodePerformActionArgsJSONFailure
                                                    reason:@"Cannot perform action: missing arguments"
                                           underlyingError:outErr]];
    }
    NSString *analyticsID = [arguments objectForKey:@"analyticsID" kindOfClass:NSString.class fallback:nil];

    [_delegate bridge:self shouldPerformAction:actionName arguments:actionArgs analyticsID:analyticsID];
    return [self genericResult];
}

- (BAPromise<NSString *> *)dismiss:(nonnull BATJsonDictionary *)arguments {
    NSString *analyticsID = [arguments objectForKey:@"analyticsID" kindOfClass:NSString.class fallback:nil];

    [_delegate bridge:self shouldDismissMessageWithAnalyticsID:analyticsID];

    return [self genericResult];
}

- (BAPromise<NSString *> *)genericResult {
    return [BAPromise resolved:@"ok"];
}

#pragma mark Error helpers

- (nonnull NSError *)makeInternalError:(BATWebviewBridgeInternalErrorCode)code
                                reason:(nonnull NSString *)reason
                       underlyingError:(nullable NSError *)underlyingError {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];

    if (underlyingError) {
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    }

    userInfo[NSLocalizedDescriptionKey] = [@(code) stringValue];
    userInfo[NSLocalizedFailureReasonErrorKey] = reason;

    return [NSError errorWithDomain:BRIDGE_ERROR_DOMAIN
                               code:BATWebviewJavascriptBridgeErrorCodeInternalError
                           userInfo:userInfo];
}

- (nonnull NSError *)makePublicError:(nonnull NSString *)reason {
    return [NSError errorWithDomain:BRIDGE_ERROR_DOMAIN
                               code:BATWebviewJavascriptBridgeErrorCodePublicError
                           userInfo:@{NSLocalizedDescriptionKey : reason}];
}

- (nonnull NSError *)makeUnknownMethodError:(nonnull NSString *)methodName {
    return [NSError
        errorWithDomain:BRIDGE_ERROR_DOMAIN
                   code:BATWebviewJavascriptBridgeErrorCodeUnkownMethod
               userInfo:@{
                   @"methodName" : methodName,
                   NSLocalizedDescriptionKey : [NSString
                       stringWithFormat:@"Unimplemented native method '%@'. Is the native SDK too old?", methodName]
               }];
}

@end
