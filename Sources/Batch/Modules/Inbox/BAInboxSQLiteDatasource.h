//
//  BAInboxSQLiteDatasource.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <Batch/BAInboxDatasourceProtocol.h>
#import <Batch/BAInboxDBHelperProtocol.h>

/*!
 @class BAInboxSQLiteDatasource
 @abstract Implementation of BAInboxDatasourceProtocol using SQLLite
 */
@interface BAInboxSQLiteDatasource : NSObject <BAInboxDatasourceProtocol>
{
    sqlite3 *_database;
    
    sqlite3_stmt *_insertNotificationStatement;
    
    sqlite3_stmt *_insertFetcherStatement;
}

- (nonnull instancetype)init NS_UNAVAILABLE;

- (instancetype _Nullable)initWithFilename:(nonnull NSString *)name forDBHelper:(nonnull id<BAInboxDBHelperProtocol>)inboxDBHelper __attribute__((warn_unused_result));

- (long long)notificationTime:(nonnull NSString *)notificationId;

/*!
 @property templateEvent
 @abstract DB Persistance helper for the object to persist.
 */
@property (nonnull) id<BAInboxDBHelperProtocol> inboxDBHelper;


@end
