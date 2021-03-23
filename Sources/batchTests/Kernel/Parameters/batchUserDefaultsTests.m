//
//  BatchUserDefaultsTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAUserDefaults.h"
#import "BAAESB64Cryptor.h"

@interface BatchUserDefaultsTests : XCTestCase

@end

@implementation BatchUserDefaultsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreation
{
    BAUserDefaults *ud;
    
    // Test without cryptor case.
    ud = [[BAUserDefaults alloc] initWithCryptor:nil];
    XCTAssertNotNil(ud, @"Failed to instanciate a BAUserDefault without cryptor.");
    
    // Test with a cryptor case.
    ud = [[BAUserDefaults alloc] initWithCryptor:[[BAAESB64Cryptor alloc] initWithKey:@"MYSUPERKEY"]];
    XCTAssertNotNil(ud, @"Failed to instanciate a BAUserDefault with a cryptor.");
}

@end
