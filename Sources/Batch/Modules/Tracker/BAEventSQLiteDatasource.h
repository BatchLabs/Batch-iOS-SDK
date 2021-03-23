//
//  BAEventSQLiteDatasource.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <Batch/BAEventDatasourceProtocol.h>
#import <Batch/BAEventDBHelperProtocol.h>

/*!
 @class BAEventSQLiteDatasource
 @abstract Implementation of BAEventDatasourceProtocol using SQLLite
 */
@interface BAEventSQLiteDatasource : NSObject <BAEventDatasourceProtocol>
{
    sqlite3 *_database;
    
    sqlite3_stmt *_insertStatement;
    
    sqlite3_stmt *_collapseDeleteStatement;
}

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFilename:(NSString *)name forDBHelper:(id<BAEventDBHelperProtocol>)eventDBHelper __attribute__((warn_unused_result));

/*!
 @property lock
 @abstract Read/Write lock.
 */
@property NSObject *lock;

/*!
 @property templateEvent
 @abstract DB Persistance helper for the object to persist.
 */
@property id<BAEventDBHelperProtocol> eventDBHelper;


@end
