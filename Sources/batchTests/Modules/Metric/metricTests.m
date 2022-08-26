//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface metricTests : XCTestCase

@end

@implementation metricTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPack {
    NSError *error = nil;

    BACounter *counter = [[BACounter alloc] initWithName:@"counter_test_metric" andLabelNames:@"label", nil];
    [counter increment];

    const unsigned char expectedBytes[] = {0x83, 0xA4, 0x6E, 0x61, 0x6D, 0x65, 0xB3, 0x63, 0x6F, 0x75, 0x6E, 0x74,
                                           0x65, 0x72, 0x5F, 0x74, 0x65, 0x73, 0x74, 0x5F, 0x6D, 0x65, 0x74, 0x72,
                                           0x69, 0x63, 0xA4, 0x74, 0x79, 0x70, 0x65, 0xA7, 0x63, 0x6F, 0x75, 0x6E,
                                           0x74, 0x65, 0x72, 0xA6, 0x76, 0x61, 0x6C, 0x75, 0x65, 0x73, 0x91, 0xCB,
                                           0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};

    NSData *expected = [NSData dataWithBytes:expectedBytes length:sizeof(expectedBytes)];
    NSData *current = [counter pack:&error];

    XCTAssertNil(error);
    XCTAssert([expected isEqual:current]);
}

- (void)testHasChildren {
    BACounter *counter = [[BACounter alloc] initWithName:@"counter_test_metric"];
    XCTAssertFalse([counter hasChanged]);
    [counter increment];
    XCTAssertTrue([counter hasChanged]);
}

- (void)testHasChanged {
    BACounter *counter = [[BACounter alloc] initWithName:@"counter_test_metric" andLabelNames:@"label", nil];
    XCTAssertFalse([counter hasChildren]);
    [[counter labels:@"label", nil] increment];
    XCTAssertTrue([counter hasChildren]);
}

- (void)testCopy {
    // Non regression test for sc-45635, where copyWithZone was not implemented correctly and
    // returned BAMetric instances when copying one of its subclasses
    BAMetric *metric = [[BAMetric alloc] initWithName:@"counter_test_metric" andLabelNames:@"label", nil];
    BACounter *counter = [[BACounter alloc] initWithName:@"counter_test_metric" andLabelNames:@"label", nil];
    BAObservation *observation = [[BAObservation alloc] initWithName:@"counter_test_metric"
                                                       andLabelNames:@"label", nil];

    XCTAssertEqual([[metric copy] class], BAMetric.class);
    XCTAssertEqual([[counter copy] class], BACounter.class);
    XCTAssertEqual([[observation copy] class], BAObservation.class);
}

@end
