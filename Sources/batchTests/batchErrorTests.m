//
//  BatchErrorTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAErrorHelper.h"
#import "Defined.h"

@interface BatchErrorTests : XCTestCase

@end

@implementation BatchErrorTests

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBasics {
    NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:nil];
    XCTAssertNotNil(error, @"Failed to build a BatchError.");

    // Look for description.
    NSString *description = [error localizedDescription];
    XCTAssertNotNil(description, @"In this case description must be nil.");

    // Ensure errors types can be enumerates.
    switch (error.code) {
        case BAInternalFailReasonNetworkError:
            break;

        case BAInternalFailReasonInvalidAPIKey:
            break;

        case BAInternalFailReasonDeactivatedAPIKey:
            break;

        case BAInternalFailReasonUnexpectedError:
            break;

        default:
            break;
    }
}

@end
