//
//  BATWebviewBridgeWKHandler.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATWebviewBridgeWKHandler.h"

#import <Batch/BATJsonDictionary.h>

@implementation BATWebviewBridgeWKHandler {
    BATWebviewJavascriptBridge *_bridge;
}

- (instancetype)initWithBridge:(nonnull BATWebviewJavascriptBridge *)bridge {
    self = [super init];
    if (self) {
        _bridge = bridge;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
                 replyHandler:(void (^)(id, NSString *))replyHandler {
    int errorCode = -100;
    NSError *underlyingError = nil;
    id body = message.body;
    if (_bridge == nil) {
        goto err;
    }
    if (![body isKindOfClass:NSDictionary.class]) {
        errorCode = -101;
        goto err;
    }

    {
        BATJsonDictionary *jsonDict = [[BATJsonDictionary alloc] initWithDictionary:body
                                                                        errorDomain:BRIDGE_ERROR_DOMAIN];

        NSError *outErr;

        NSString *method = nil;
        NSDictionary *args = nil;

        outErr = nil;
        method = [jsonDict objectForKey:@"method" kindOfClass:NSString.class allowNil:NO error:&outErr];
        if (outErr != nil) {
            errorCode = -102;
            underlyingError = outErr;
            goto err;
        }

        outErr = nil;
        args = [jsonDict objectForKey:@"args" kindOfClass:NSDictionary.class allowNil:NO error:&outErr];
        if (outErr != nil) {
            errorCode = -103;
            underlyingError = outErr;
            goto err;
        }

        BAPromise<NSString *> *bridgePromise = [_bridge executeBridgeMethod:method arguments:args];

        [bridgePromise then:^(NSString *_Nullable value) {
          replyHandler(value, nil);
        }];

        [bridgePromise catch:^(NSError *_Nullable err) {
          // The error should be a public error, so just forward the localized description
          NSString *errorMessage = err.localizedDescription;
          if (errorMessage == nil) {
              errorMessage = @"Unknown error (-120)";
          }
          replyHandler(nil, errorMessage);
        }];
    }
    return;
err:
    replyHandler(nil, [NSString stringWithFormat:@"Unknown error (%d)", errorCode]);
    [BALogger errorForDomain:@"WebviewBridge"
                     message:@"Could not forward JS message to bridge: %@", underlyingError.localizedDescription];
    return;
}

@end
