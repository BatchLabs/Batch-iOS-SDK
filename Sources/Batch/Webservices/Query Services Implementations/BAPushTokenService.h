//
//  BAPushTokenService.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAQueryWebserviceClientDatasource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This service has no associated delegate, because it does not care about success nor failure
 */
@interface BAPushTokenServiceDatasource : NSObject <BAQueryWebserviceClientDatasource>

- (instancetype)initWithToken:(NSString *)token usesProductionEnvironment:(BOOL)usesProductionEnvironment;

@end

NS_ASSUME_NONNULL_END
