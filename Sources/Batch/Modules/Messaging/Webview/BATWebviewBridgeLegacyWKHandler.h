//
//  BATWebviewBridgeLegacyWKHandler.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import <Batch/BATWebviewBridgeWKHandler.h>
#import <Batch/BATWebviewJavascriptBridge.h>

NS_ASSUME_NONNULL_BEGIN

@class BATWebviewBridgeLegacyWKHandler;

@protocol BATWebviewBridgeLegacyWKHandlerWebViewSource

@required
- (nullable WKWebView *)backingWebViewForLegacyHandler:(BATWebviewBridgeLegacyWKHandler *)handler;

@end

@interface BATWebviewBridgeLegacyWKHandler : BATWebviewBridgeWKHandler <WKScriptMessageHandler>

- (instancetype)initWithBridge:(nonnull BATWebviewJavascriptBridge *)bridge NS_UNAVAILABLE;

- (instancetype)initWithBridge:(nonnull BATWebviewJavascriptBridge *)bridge
               webViewProvider:(nonnull id<BATWebviewBridgeLegacyWKHandlerWebViewSource>)webViewProvider;

@property (weak, nonatomic, readonly) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
