//
//  batchUserDataSQLTests.m
//  Batch
//
//  Copyright © 2015 Batch. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BatchUser.h"
#import "BAUserSQLiteDatasource.h"
#import "BAUserDatasourceProtocol.h"

@interface batchUserDataSQLTests : XCTestCase
{
    id<BAUserDatasourceProtocol> _datasource;
    BatchUserDataEditor *_userEditor;
}
@end

@implementation batchUserDataSQLTests

- (void)setUp {
    [super setUp];
    _datasource = [BAUserSQLiteDatasource new];
    
    XCTAssertNotNil(_datasource);
    
    [_datasource clear];
    
    XCTAssertTrue([_datasource acquireTransactionLockWithChangeset:1]);
}

- (void)tearDown {
    XCTAssertTrue([_datasource rollbackTransaction]);
    [_datasource clear];
    [super tearDown];
}

- (void)testPutAttribute {
    XCTAssertTrue([_datasource setStringAttribute:@"String" forKey:@"string"]);
    XCTAssertTrue([_datasource setLongLongAttribute:LONG_LONG_MAX forKey:@"longlong"]);
    XCTAssertTrue([_datasource setDoubleAttribute:2.5234f forKey:@"double"]);
    XCTAssertTrue([_datasource setDateAttribute:[NSDate date] forKey:@"date"]);
    XCTAssertTrue([_datasource setBoolAttribute:YES forKey:@"bool"]);
    XCTAssertTrue([_datasource setURLAttribute:[NSURL URLWithString:@"https://batch.com"] forKey:@"url"]);
}

- (void)testAttributeUpdate {
    XCTAssertTrue([_datasource setStringAttribute:@"String" forKey:@"string"]);
    XCTAssertTrue([_datasource setStringAttribute:@"String2" forKey:@"string"]);
}

- (void)testClear {
    XCTAssertTrue([_datasource clearTags]);
    XCTAssertTrue([_datasource clearTagsFromCollection:@"collection"]);
    XCTAssertTrue([_datasource clearAttributes]);
}

- (void)testTransaction {
    XCTAssertTrue([_datasource rollbackTransaction]);
    XCTAssertTrue([_datasource acquireTransactionLockWithChangeset:1]);
    XCTAssertTrue([_datasource commitTransaction]);
    
    XCTAssertFalse([_datasource setStringAttribute:@"String" forKey:@"string"]);
    XCTAssertFalse([_datasource removeAttributeNamed:@"string"]);
    XCTAssertFalse([_datasource addTag:@"tag" toCollection:@"collection"]);
    XCTAssertFalse([_datasource removeTag:@"tag" fromCollection:@"collection"]);
    XCTAssertFalse([_datasource clearTags]);
    XCTAssertFalse([_datasource clearTagsFromCollection:@"collection"]);
    XCTAssertFalse([_datasource clearAttributes]);
    
    XCTAssertTrue([_datasource acquireTransactionLockWithChangeset:1]);
}

@end
