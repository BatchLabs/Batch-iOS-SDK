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

- (void)testToDictionary {
    BACounter *counter = [[BACounter alloc] initWithName:@"counter_test_metric" andLabelNames:@"label", nil];
    [counter increment];

    NSDictionary *dict = [counter toDictionary];

    XCTAssertNotNil(dict);
    XCTAssertEqualObjects(dict[@"name"], @"counter_test_metric");
    XCTAssertEqualObjects(dict[@"type"], @"counter");
    XCTAssertNotNil(dict[@"values"]);
    XCTAssertTrue([dict[@"values"] isKindOfClass:[NSArray class]]);
    NSArray *values = dict[@"values"];
    XCTAssertEqual(values.count, 1);
    XCTAssertEqualObjects(values[0], @1.0);
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
    NSArray<NSString *> *labels = [[NSArray alloc] initWithObjects:@"label", nil];
    [[counter labels:labels] increment];
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
