//
//  BATWebviewBridgeWKHandler.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import <Batch/BATWebviewJavascriptBridge.h>

NS_ASSUME_NONNULL_BEGIN

@interface BATWebviewBridgeWKHandler : NSObject <WKScriptMessageHandlerWithReply>

- (instancetype)initWithBridge:(nonnull BATWebviewJavascriptBridge*)bridge;

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
                 replyHandler:(void (^)(id _Nullable, NSString * _Nullable))replyHandler;

@end

NS_ASSUME_NONNULL_END
