//
//  batchUserTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BAInjection.h"
#import "BAParameter.h"
#import "BAUserDataEditor.h"
#import "BAUserDatasourceProtocol.h"
#import "BAUserSQLiteDatasource.h"
#import "Batch.h"

#import "OCMock.h"

@interface batchUserTests : XCTestCase

@property (nonatomic) BAUserDataEditor *editor;
@property BAOverlayedInjectable *datasourceOverlay;

@end

@interface BAParameter ()
- (instancetype)initWithSuiteName:(NSString *_Nullable)suiteName;
@end

@implementation batchUserTests {
    id trackerCenterMock;
}

- (void)setUp {
    [super setUp];

    // Mock tracker center
    trackerCenterMock = OCMClassMock([BATrackerCenter class]);
    OCMStub([trackerCenterMock instance]).andReturn(trackerCenterMock);

    // Mock data source to set a test specific database
    BAUserSQLiteDatasource *dataSourceToUse =
        [[BAUserSQLiteDatasource alloc] initWithDatabaseName:@"test-attribute-read"];

    self.datasourceOverlay = [BAInjection overlayProtocol:@protocol(BAUserDatasourceProtocol)
                                                 callback:^id(id originalObject) {
                                                   return dataSourceToUse;
                                                 }];

    _editor = [BAUserDataEditor new];

    // Mock editor to allow saving
    BAUserDataEditor *partialMock = OCMPartialMock(_editor);
    OCMStub([partialMock canSave])._andReturn([NSNumber numberWithBool:YES]);

    // Clear all saved parameters before each test
    [BAParameter removeAllObjects];
}

- (void)tearDown {
    [super tearDown];
    [trackerCenterMock stopMocking];
    self.datasourceOverlay = nil;
}

- (void)testAttributesRead {
    // Set attributes
    [_editor setAttribute:[NSDate new] forKey:@"today"];
    [_editor setAttribute:@3.2 forKey:@"float_value"];
    [_editor setAttribute:@5 forKey:@"int_value"];

    XCTestExpectation *exp = [self expectationWithDescription:@"testing attributes read"];
    [_editor save:^{
      [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    XCTestExpectation *exp1 = [self expectationWithDescription:@"testing attributes read"];

    __block NSDictionary<NSString *, BatchUserAttribute *> *fetchedAttributes = nil;

    [BatchUser fetchAttributes:^(NSDictionary<NSString *, BatchUserAttribute *> *_Nullable attributes) {
      fetchedAttributes = attributes;
      [exp1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:1
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    XCTAssertNotNil(fetchedAttributes);
    XCTAssertEqual([fetchedAttributes count], 3); // 3 attributes were set
    BatchUserAttribute *dateValue = fetchedAttributes[@"today"];
    XCTAssertNotNil(dateValue);
    XCTAssertNil([dateValue stringValue]);
    XCTAssertNil([dateValue numberValue]);
    XCTAssertNotNil([dateValue dateValue]);
}

- (void)testTagsRead {
    // Set tags
    [_editor addTag:@"tag_1" inCollection:@"collection_1"];
    [_editor addTag:@"tag_2" inCollection:@"collection_1"];
    [_editor addTag:@"tag_3" inCollection:@"collection_2"];
    [_editor addTag:@"TAG_4" inCollection:@"collection_3"];

    XCTestExpectation *exp = [self expectationWithDescription:@"testing tag read"];
    [_editor save:^{
      [exp fulfill];
    }];

    [self waitForExpectationsWithTimeout:2
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    XCTestExpectation *exp1 = [self expectationWithDescription:@"testing tag read"];

    __block NSDictionary<NSString *, NSSet<NSString *> *> *fetchedTags = nil;

    [BatchUser fetchTagCollections:^(NSDictionary<NSString *, NSSet<NSString *> *> *_Nullable tags) {
      fetchedTags = tags;
      [exp1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:1
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    XCTAssertNotNil(fetchedTags);
    XCTAssertEqual([fetchedTags count], 3); // 3 collections were set
    NSSet<NSString *> *collection1 = fetchedTags[@"collection_1"];
    XCTAssertTrue([collection1 containsObject:@"tag_2"]);
    XCTAssertFalse([collection1 containsObject:@"tag_3"]);
    NSSet<NSString *> *collection3 = fetchedTags[@"collection_3"];
    XCTAssertTrue([collection3 containsObject:@"tag_4"]); // tags are lowercased when saved
}

- (void)testCustomDataRead {
    // Initial state
    NSString *initialRegion = [BatchUser region];
    NSString *initialLanguage = [BatchUser language];
    NSString *initialIdentifier = [BatchUser identifier];

    XCTAssertNil(initialRegion);
    XCTAssertNil(initialLanguage);
    XCTAssertNil(initialIdentifier); // Custom identifier is nil by default

    // Set values
    [_editor setRegion:@"azerty"];
    [_editor setLanguage:@"bambam"];
    [_editor setIdentifier:@"pifpaf"];

    XCTestExpectation *exp1 = [self expectationWithDescription:@"testing custom data read"];

    // Save values. Saving happens asynchronously.
    [_editor save:^{
      [exp1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    // Test reading
    XCTAssertTrue([[BatchUser region] isEqualToString:@"azerty"]);
    XCTAssertTrue([[BatchUser language] isEqualToString:@"bambam"]);
    XCTAssertTrue([[BatchUser identifier] isEqualToString:@"pifpaf"]);

    // Clear custom data
    [_editor setRegion:nil];
    [_editor setLanguage:nil];
    [_editor setIdentifier:nil];

    XCTestExpectation *exp2 = [self expectationWithDescription:@"testing custom data read"];

    // Save values. Saving happens asynchronously.
    [_editor save:^{
      [exp2 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    // Test if clearing succeeded and that we're back to initial state
    XCTAssertNil([BatchUser region]);
    XCTAssertNil([BatchUser language]);
    XCTAssertNil([BatchUser identifier]);
    XCTAssertTrue([BatchUser region] == initialRegion);
    XCTAssertTrue([BatchUser language] == initialLanguage);
}

- (void)testCustomDataLimits {
    // Initial state
    NSString *initialRegion = [BatchUser region];
    NSString *initialLanguage = [BatchUser language];
    NSString *initialIdentifier = [BatchUser identifier];

    XCTAssertNil(initialRegion);
    XCTAssertNil(initialLanguage);
    XCTAssertNil(initialIdentifier); // Custom identifier is nil by default

    // Set values
    [_editor setRegion:@"a"];
    [_editor setRegion:@"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123"
                       @"4567890123456789012345678901234567890123456789"];
    [_editor setLanguage:@"a"];
    [_editor setLanguage:@"01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901"
                         @"234567890123456789012345678901234567890123456789"];
    [_editor setIdentifier:
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"
                 @"01234567890123456789012345678901234567890123456789012345678901234567890123456789"];

    XCTestExpectation *exp1 = [self expectationWithDescription:@"testing custom data read"];

    // Save values. Saving happens asynchronously.
    [_editor save:^{
      [exp1 fulfill];
    }];

    [self waitForExpectationsWithTimeout:2
                                 handler:^(NSError *_Nullable error) {
                                   if (error != nil) {
                                       XCTFail("Expectation Failed with error: %@", error);
                                   }
                                 }];

    // Test reading
    XCTAssertNil([BatchUser region]);
    XCTAssertNil([BatchUser language]);
    XCTAssertNil([BatchUser identifier]);
}

- (void)testAttributionIDChangedEvent {
    // Ensure event is not sent when attribution id is not a valid UUID
    XCTestExpectation *exp1 = [self expectationWithDescription:@"Wait for editor stacking operations"];
    [_editor setAttributionIdentifier:@"WRONG-UUID"];
    OCMReject([trackerCenterMock trackPrivateEvent:@"_ATTRIBUTION_ID_CHANGED"
                                        parameters:@{@"attribution_id" : @"WRONG-UUID"}]);
    [_editor save:^{
      [exp1 fulfill];
    }];
    [self waitForExpectations:@[ exp1 ] timeout:3.0];

    // Ensure event is sent when attribution id is a valid UUID
    XCTestExpectation *exp2 = [self expectationWithDescription:@"Wait for editor stacking operations"];
    [_editor setAttributionIdentifier:@"EA7583CD-A667-48BC-B806-42ECB2B48606"];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_ATTRIBUTION_ID_CHANGED"
                                        parameters:@{@"attribution_id" : @"EA7583CD-A667-48BC-B806-42ECB2B48606"}]);
    [_editor save:^{
      [exp2 fulfill];
    }];
    [self waitForExpectations:@[ exp2 ] timeout:3.0];

    // Ensure event is not sent when attribution id did not changed
    [_editor setAttributionIdentifier:@"EA7583CD-A667-48BC-B806-42ECB2B48606"];
    OCMReject([trackerCenterMock trackPrivateEvent:@"_ATTRIBUTION_ID_CHANGED"
                                        parameters:@{@"attribution_id" : @"EA7583CD-A667-48BC-B806-42ECB2B48606"}]);
    XCTestExpectation *exp3 = [self expectationWithDescription:@"Wait for editor stacking operations"];
    [_editor save:^{
      [exp3 fulfill];
    }];
    [self waitForExpectations:@[ exp3 ] timeout:3.0];

    // Ensure event is sent when attribution id is nil (reset)
    XCTestExpectation *exp4 = [self expectationWithDescription:@"Wait for editor stacking operations"];
    [_editor setAttributionIdentifier:nil];
    OCMExpect([trackerCenterMock trackPrivateEvent:@"_ATTRIBUTION_ID_CHANGED"
                                        parameters:@{@"attribution_id" : [NSNull null]}]);
    [_editor save:^{
      [exp4 fulfill];
    }];
    [self waitForExpectations:@[ exp4 ] timeout:3.0];
    OCMVerifyAll(trackerCenterMock);
}

@end
