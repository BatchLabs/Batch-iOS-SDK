//
//  BatchConfigurationTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAConfiguration.h"

@interface BatchConfigurationTests : XCTestCase

@end

@implementation BatchConfigurationTests

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testAssociatedDomains {
    BAConfiguration *config = [[BAConfiguration alloc] init];
    XCTAssertNil([config associatedDomains], @"Associated domains should be nil");

    NSArray *domains = [NSArray arrayWithObjects:@"Batch.com", @"www.batch.com ", nil];
    NSArray *expected = [NSArray arrayWithObjects:@"batch.com", @"www.batch.com", nil];

    [config setAssociatedDomains:domains];
    XCTAssertNotNil([config associatedDomains], @"Associated domains should NOT be nil");
    XCTAssertTrue([expected isEqualToArray:[config associatedDomains]]);
}

@end
