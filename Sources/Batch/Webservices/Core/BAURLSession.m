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
      sessionConfig.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;

      session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    });
    return session;
}

@end
