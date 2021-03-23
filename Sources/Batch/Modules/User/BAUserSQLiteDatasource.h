//
//  BAUserSQLiteDatasource.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/BAInjection.h>

@interface BAUserSQLiteDatasource : NSObject<BAUserDatasourceProtocol>

+ (BAUserSQLiteDatasource *)instance BATCH_USE_INJECTION_OUTSIDE_TESTS;

- (instancetype)initWithDatabaseName:(NSString *)dbName;

@end

/**
 * TABLE SCHEMAS
 *
 * attributes
 * +----+----+-----+-----+-----------+---------+-------+
 * |name|type|value|score|last_update|changeset|deleted|
 * +----+----+-----+-----+-----------+---------+-------+
 *
 * tags
 * +----------+-----+-----------+---------+-------+
 * |collection|value|last_update|changeset|deleted|
 * +----------+-----+-----------+---------+-------+
 *
 * logs
 * +----+------+-----+---------+----+
 * |name|action|value|changeset|date|
 * +----+------+-----+---------+----+
 *
 */
