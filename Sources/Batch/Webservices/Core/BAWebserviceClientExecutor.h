//
//  BAWebserviceClientExecutor.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAWebserviceClientExecutor : NSObject

+ (instancetype)sharedInstance;

- (void)addClient:(BAWebserviceClient *)client;

@end

NS_ASSUME_NONNULL_END
