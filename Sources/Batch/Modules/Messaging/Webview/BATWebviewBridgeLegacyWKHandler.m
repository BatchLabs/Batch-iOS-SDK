//
//  BATWebviewBridgeLegacyWKHandler.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATWebviewBridgeLegacyWKHandler.h"

#import <Batch/BAJson.h>
#import <Batch/BATJsonDictionary.h>

#define LOGGER_DOMAIN @"WebviewBridge"

@implementation BATWebviewBridgeLegacyWKHandler {
    __weak id<BATWebviewBridgeLegacyWKHandlerWebViewSource> _webViewProvider;
}

- (instancetype)initWithBridge:(nonnull BATWebviewJavascriptBridge *)bridge
               webViewProvider:(nonnull id<BATWebviewBridgeLegacyWKHandlerWebViewSource>)webViewProvider {
    self = [super initWithBridge:bridge];
    if (self) {
        _webViewProvider = webViewProvider;
    }
    return self;
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    id body = message.body;
    if (![body isKindOfClass:NSDictionary.class]) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Cannot decode taskID (missing body): webview cannot be called back"];
        return;
    }

    BATJsonDictionary *jsonDict = [[BATJsonDictionary alloc] initWithDictionary:body errorDomain:BRIDGE_ERROR_DOMAIN];
    NSInteger taskID = [[jsonDict objectForKey:@"taskID" kindOfClass:NSNumber.class fallback:@(-1)] integerValue];

    if (taskID < 0) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Cannot decode taskID (invalid task id): webview cannot be called back"];
        return;
    }

    [self userContentController:userContentController
        didReceiveScriptMessage:message
                   replyHandler:^(id _Nullable reply, NSString *_Nullable errorMessage) {
                     if (errorMessage == nil && reply != nil && ![reply isKindOfClass:NSString.class]) {
                         // Success, but not a string reply
                         // We can't process that
                         errorMessage = @"Unknown error (reply serialization)";
                         reply = nil;
                     }
                     NSString *callbackEval = [self javascriptCallbackForTaskID:taskID error:errorMessage result:reply];
                     [self eval:callbackEval];
                   }];
}

- (void)eval:(nonnull NSString *)javascript {
    WKWebView *webView = [_webViewProvider backingWebViewForLegacyHandler:self];
    [webView evaluateJavaScript:javascript
              completionHandler:^(id _Nullable result, NSError *_Nullable error){
              }];
}

- (NSString *)javascriptCallbackForTaskID:(NSInteger)taskID
                                    error:(nullable NSString *)error
                                   result:(nullable NSString *)result {
    if (error == (id)[NSNull null]) {
        error = nil;
    }
    if (result == (id)[NSNull null]) {
        result = nil;
    }

    NSMutableDictionary *response = [NSMutableDictionary new];

    if (error != nil) {
        response[@"error"] = error;
    }

    if (result != nil) {
        response[@"result"] = result;
    }

    NSError *outErr = nil;
    NSString *jsonResponse = [BAJson serialize:response error:&outErr];
    if (outErr != nil) {
        [BALogger errorForDomain:@"WebviewBridge"
                         message:@"Could not serialize bridge json response object: %@", outErr.localizedDescription];
    }
    if (jsonResponse == nil) {
        jsonResponse = @"{'error': 'Unknown error (json)'}";
    }

    return [NSString stringWithFormat:@"window.batchInAppSDK.__onWebkitCallback(%ld, %@);", taskID, jsonResponse];
}

@end
