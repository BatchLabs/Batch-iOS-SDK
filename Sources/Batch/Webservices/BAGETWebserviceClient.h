//
//  BAGETWebserviceClient.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceJsonClient.h>

@interface BAGETWebserviceClient : BAWebserviceJsonClient

- (nullable instancetype)initWithURL:(nonnull NSURL *)url
                          identifier:(nonnull NSString *)identifier
                            delegate:(nullable id<BAConnectionDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@end
