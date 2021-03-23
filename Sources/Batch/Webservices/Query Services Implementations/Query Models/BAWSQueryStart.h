//
//  BAWebserviceQueryNewStart.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>

/*!
 @class BAWSQueryStart
 @abstract Query requesting for start
 */
@interface BAWSQueryStart : BAWSQuery <BAWSQuery>

- (instancetype)init;

@property BOOL isSilent;

@end
