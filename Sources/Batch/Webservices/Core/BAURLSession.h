//
//  BAURLSession.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAURLSessionProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAURLSession : NSObject

+ (id<BAURLSessionProtocol>)sharedSession;

@end

NS_ASSUME_NONNULL_END
