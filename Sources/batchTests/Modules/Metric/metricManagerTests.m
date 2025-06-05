//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface metricManagerTests : XCTestCase {
    BAMetricManager *_manager;
    BAOverlayedInjectable *_managerOverlay;
}
@end

@interface BAMetricManager (Tests)
- (NSArray *)getMetricsToSend;
@end

@implementation metricManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _manager = [[BAMetricManager alloc] init];
    _managerOverlay = [BAInjection overlayClass:BAMetricManager.class returnedInstance:_manager];
}

- (void)tearDown {
    [BAInjection unregisterOverlay:_managerOverlay];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddMetric {
    XCTAssertTrue([[_manager valueForKey:@"_metrics"] count] == 0);
    [[[BACounter alloc] initWithName:@"counter_test_metric"] registerMetric];
    XCTAssertTrue([[_manager valueForKey:@"_metrics"] count] == 1);
}

- (void)testGetMetricToSend {
    BACounter *counter = [[[BACounter alloc] initWithName:@"counter_test_metric"] registerMetric];
    XCTAssertFalse([[_manager valueForKey:@"_isSending"] boolValue]);

    [counter increment];
    XCTAssertTrue([[_manager valueForKey:@"_isSending"] boolValue]);

    BAObservation *observation = [[[BAObservation alloc] initWithName:@"observation_test_metric"
                                                        andLabelNames:@"label1", @"label2", nil] registerMetric];
    NSArray<NSString *> *labels1 = [[NSArray alloc] initWithObjects:@"value1", @"value2", nil];
    [[observation labels:labels1] startTimer];

    NSArray<NSString *> *labels2 = [[NSArray alloc] initWithObjects:@"value1", @"value2", nil];
    [[observation labels:labels2] observeDuration];

    NSArray<NSString *> *labels3 = [[NSArray alloc] initWithObjects:@"value2"
                                                                    @"value3",
                                                                    nil];
    [[observation labels:labels3] startTimer];

    // Making copy of metrics because the reset method will be called when getMetricsToSend is done
    NSArray<NSString *> *labels1copy = [[NSArray alloc] initWithObjects:@"value1", @"value2", nil];

    NSArray *expected = @[ [counter copy], [[observation labels:labels1copy] copy] ];

    NSArray *actual = [_manager getMetricsToSend];
    XCTAssertEqual([expected count], [actual count]);

    unsigned long i, size = [actual count];
    for (i = 0; i < size; i++) {
        BAMetric *actualMetric = [actual objectAtIndex:i];
        BAMetric *expectedMetric = [expected objectAtIndex:i];
        XCTAssertEqual([actualMetric name], [expectedMetric name]);
        XCTAssertEqual([actualMetric type], [expectedMetric type]);
        XCTAssertEqualObjects([actualMetric labelNames], [expectedMetric labelNames]);
        XCTAssertEqualObjects([actualMetric labelValues], [expectedMetric labelValues]);
        XCTAssertEqualObjects([actualMetric values], [expectedMetric values]);
    }
}

@end
