//
//  BAStandardQueryWebserviceIdentifiersProvider.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAQueryWebserviceIdentifiersProviding.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Class that handles collecting all the required Query WS Identifiers (di, da, etc...)
 */
@interface BAStandardQueryWebserviceIdentifiersProvider : NSObject <BAQueryWebserviceIdentifiersProviding>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
