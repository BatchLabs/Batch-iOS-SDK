//
//  BAURLSession.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAURLSession.h>

@interface NSURLSession () <BAURLSessionProtocol>

@end

@implementation BAURLSession

+ (id<BAURLSessionProtocol>)sharedSession {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
      // Enforce TLS 1.2
      if (@available(iOS 13, tvOS 13, watchOS 6, macOS 10.15, *)) {
          sessionConfig.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;
      } else {
          sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol12;
      }

      session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    });
    return session;
}

@end
