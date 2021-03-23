//
//  BALUserAttributeContext.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALEvaluationContext.h>
#import <Batch/BAUserDatasourceProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BALUserAttributeContext : NSObject <BALEvaluationContext>

+ (instancetype)contextWithDatasource:(id<BAUserDatasourceProtocol>)datasource;

@end

NS_ASSUME_NONNULL_END
