//
//  BAInboxDBHelperProtocol.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInbox.h>
#import <Foundation/Foundation.h>
#import <sqlite3.h>

/*!
 @protocol BAInboxDBHelperProtocol
 @abstract Event protocol for sqlite binding.
 */
@protocol BAInboxDBHelperProtocol <NSObject>

@required

/*!
 @method insertStatementDescriptions
 @abstract Table insertion properties list.
 @return NSArray of NSString.
 */
+ (NSArray *)insertNotificationStatementDescriptions __attribute__((warn_unused_result));

/*!
 @method bindNotification:withStatement
 @abstract Insertion statement binding for sqlite.
 @param statement precompiled statement to bind the notification
 @return YES if insertion has been populated, NO otherwise.
 */
- (BOOL)bindNotification:(BAInboxNotificationContent *)notification
           withStatement:(sqlite3_stmt **)statement __attribute__((warn_unused_result));

/*!
@method insertFetchersStatementDescriptions
@abstract Table insertion properties list.
@return NSArray of NSString.
*/
+ (NSArray *)insertFetcherStatementDescriptions __attribute__((warn_unused_result));

/*!
 @method bindFetcherNotification:withFetcherId:statement
 @abstract Insertion statement binding for sqlite.
 @param statement precompiled statement to bind the notification
 @return YES if insertion has been populated, NO otherwise.
 */
- (BOOL)bindFetcherNotification:(BAInboxNotificationContent *)notification
                  withFetcherId:(long long)fetcherId
                      statement:(sqlite3_stmt **)statement __attribute__((warn_unused_result));

@end
