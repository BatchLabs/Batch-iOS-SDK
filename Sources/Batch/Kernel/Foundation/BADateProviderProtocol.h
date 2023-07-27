//
//  BADateProviderProtocol.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Simple protocol for a date provider, allowing it to be mocked for tests
 */
@protocol BADateProviderProtocol <NSObject>

- (NSDate *)currentDate;

@end

NS_ASSUME_NONNULL_END
