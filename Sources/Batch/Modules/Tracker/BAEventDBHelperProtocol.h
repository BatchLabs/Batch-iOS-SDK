//
//  BAEventDBHelperProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BAEvent.h>

/*!
 @protocol BAEventDBHelperProtocol
 @abstract Event protocol for sqlite binding.
 */
@protocol BAEventDBHelperProtocol <NSObject>

@required
/*!
 @method createStatementDescriptions
 @abstract Table creation properties list.
 @return NSArray of NSString.
 */
+ (NSArray *)createStatementDescriptions __attribute__((warn_unused_result));

/*!
 @method insertStatementDescriptions
 @abstract Table insertion properties list.
 @return NSArray of NSString.
 */
+ (NSArray *)insertStatementDescriptions __attribute__((warn_unused_result));

/*!
 @method bindEvent:withStatement:
 @abstract Insertion statement binding for sqlite.
 @param statement precompiled statement to bind the event to
 @return YES if insertion has been populated, NO otherwise.
 */
- (BOOL)bindEvent:(BAEvent*)event withStatement:(sqlite3_stmt **)statement __attribute__((warn_unused_result));

@end
