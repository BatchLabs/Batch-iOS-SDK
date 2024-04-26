//
//  BATWebviewJavascriptBridge.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGMessage.h>
#import <Batch/BAPromise.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BATWebviewJavascriptBridgeErrorCode) {

    /**
     Internal bridge error. Should not be exposed to the JS SDK, but should be logged.
     NSLocalizedFailureReasonErrorKey will contain the internal error, while NSLocalizedDescriptionKey will be
     the error code
     */
    BATWebviewJavascriptBridgeErrorCodeInternalError,

    /**
     Public bridge error. Can be an unavailable value (advertising id), or malformed parameters
     Not exactly a cause, as it has a real underlying one, but good enough for our use.
     NSLocalizedDescriptionKey's value should be forwarded to the bridge in the "error" parameter, as is.
     */
    BATWebviewJavascriptBridgeErrorCodePublicError,

    /**
     The requested method does not exist
     */
    BATWebviewJavascriptBridgeErrorCodeUnkownMethod,
};

@class BATWebviewJavascriptBridge;

@protocol BATWebviewJavascriptBridgeDelegate

@required

- (void)bridge:(BATWebviewJavascriptBridge *)bridge
    shouldDismissMessageWithAnalyticsID:(nullable NSString *)analyticsIdentifier;

- (void)bridge:(BATWebviewJavascriptBridge *)bridge
    shouldOpenDeeplink:(nonnull NSString *)url
     openInAppOverride:(nullable NSNumber *)openInAppOverride
           analyticsID:(nullable NSString *)analyticsIdentifier;

- (void)bridge:(BATWebviewJavascriptBridge *)bridge
    shouldPerformAction:(NSString *)action
              arguments:(NSDictionary<NSString *, id> *)arguments
            analyticsID:(nullable NSString *)analyticsIdentifier;

@end

@interface BATWebviewJavascriptBridge : NSObject

- (instancetype)initWithMessage:(nonnull BAMSGMessageWebView *)message
                       delegate:(nullable id<BATWebviewJavascriptBridgeDelegate>)delegate;

- (nonnull BAPromise<NSString *> *)executeBridgeMethod:(nullable NSString *)method
                                             arguments:(nullable NSDictionary *)rawJSONArguments;

#pragma mark Methods visible for testing

- (BAPromise<NSString *> *)installationID;

- (BAPromise<NSString *> *)customRegion;

- (BAPromise<NSString *> *)customLanguage;

- (BAPromise<NSString *> *)customUserID;

- (BAPromise<NSString *> *)customPayload;

- (BAPromise<NSString *> *)trackingID;

@end

NS_ASSUME_NONNULL_END
