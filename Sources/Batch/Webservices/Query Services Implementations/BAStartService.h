//
//  BAStartService.h
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
@interface BAStartServiceDatasource : NSObject <BAQueryWebserviceClientDatasource>

@property BOOL isSilent;

@end

NS_ASSUME_NONNULL_END
