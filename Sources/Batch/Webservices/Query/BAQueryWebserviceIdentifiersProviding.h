//
// Copyright (c) 2019 Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Provides common identifiers to add in the query WS
 */
@protocol BAQueryWebserviceIdentifiersProviding <NSObject>

- (NSDictionary<NSString*, NSString*>*)identifiers;

@end
