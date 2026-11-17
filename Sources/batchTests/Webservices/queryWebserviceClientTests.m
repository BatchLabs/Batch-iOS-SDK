//  Copyright © Batch.com. All rights reserved.

#import <XCTest/XCTest.h>

#import "BAQueryWebserviceClient.h"
#import "BAWSQuery.h"
#import "BAWSResponse.h"
#import "BAWSResponseAttributesCheck.h"

#pragma mark - Fixtures

@interface BATFixtureQueryDatasource : NSObject <BAQueryWebserviceClientDatasource>

@property (nonatomic) NSArray<id<BAWSQuery>> *queries;

@property (nonatomic) BOOL rejectsContent;

@end

@implementation BATFixtureQueryDatasource

- (NSURL *)requestURL {
    return [NSURL URLWithString:@"https://ws.batch.invalid/atc/fixture"];
}

- (NSString *)requestIdentifier {
    return @"attributesCheck";
}

- (NSString *)requestShortIdentifier {
    return @"atc";
}

- (NSArray<id<BAWSQuery>> *)queriesToSend {
    return self.queries;
}

- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query content:(NSDictionary *)content {
    if (self.rejectsContent) {
        return nil;
    }
    return [[BAWSResponseAttributesCheck alloc] initWithResponse:content];
}

@end

@interface BATFixtureQueryDelegate : NSObject <BAQueryWebserviceClientDelegate>

@property (nonatomic, nullable) NSArray<id<BAWSResponse>> *responses;
@property (nonatomic, nullable) NSError *error;

@end

@implementation BATFixtureQueryDelegate

- (void)webserviceClient:(BAQueryWebserviceClient *)client didFailWithError:(NSError *)error {
    self.error = error;
}

- (void)webserviceClient:(BAQueryWebserviceClient *)client
    didSucceedWithResponses:(NSArray<id<BAWSResponse>> *)responses {
    self.responses = responses;
}

@end

@interface BATFixtureIdentifiersProvider : NSObject <BAQueryWebserviceIdentifiersProviding>
@end

@implementation BATFixtureIdentifiersProvider

- (NSDictionary<NSString *, NSString *> *)identifiers {
    return @{};
}

@end

#pragma mark - Tests

// Query answers are matched by request identifier, and any unmatched response fails the batch.
@interface queryWebserviceClientTests : XCTestCase

@property (nonatomic) BATFixtureQueryDatasource *queryDatasource;
@property (nonatomic) BATFixtureQueryDelegate *queryDelegate;

@end

@implementation queryWebserviceClientTests

- (void)setUp {
    [super setUp];
    self.queryDatasource = [BATFixtureQueryDatasource new];
    self.queryDelegate = [BATFixtureQueryDelegate new];
}

- (void)testResponsesArePairedWithTheirQueryByIdentifier {
    BAWSQuery *first = [[BAWSQuery alloc] initWithType:@"atc"];
    BAWSQuery *second = [[BAWSQuery alloc] initWithType:@"atc"];
    BAQueryWebserviceClient *client = [self clientForQueries:@[ first, second ]];

    [client connectionDidFinishLoadingWithData:[self serverBodyWithQueries:@[
                @{@"id" : second.identifier, @"action" : @"BUMP", @"ver" : @12},
                @{@"id" : first.identifier, @"action" : @"OK"},
            ]]];

    XCTAssertNil(self.queryDelegate.error);
    XCTAssertEqual(self.queryDelegate.responses.count, 2);

    BAWSResponseAttributesCheck *firstResponse = self.queryDelegate.responses[0];
    XCTAssertEqualObjects(firstResponse.reference, first.identifier);
    XCTAssertEqual(firstResponse.action, BAWSResponseAttrCheckActionOk);

    BAWSResponseAttributesCheck *secondResponse = self.queryDelegate.responses[1];
    XCTAssertEqualObjects(secondResponse.reference, second.identifier);
    XCTAssertEqual(secondResponse.action, BAWSResponseAttrCheckActionBump);
    XCTAssertEqualObjects(secondResponse.version, @12);
}

- (void)testAnUnansweredQueryFailsTheWholeRequest {
    BAWSQuery *first = [[BAWSQuery alloc] initWithType:@"atc"];
    BAWSQuery *second = [[BAWSQuery alloc] initWithType:@"atc"];
    BAQueryWebserviceClient *client = [self clientForQueries:@[ first, second ]];

    [client connectionDidFinishLoadingWithData:[self serverBodyWithQueries:@[
                @{@"id" : first.identifier, @"action" : @"OK"},
                @{@"id" : @"7F2B1A64-0000-0000-0000-000000000000", @"action" : @"OK"},
            ]]];

    XCTAssertNil(self.queryDelegate.responses);
    XCTAssertNotNil(self.queryDelegate.error);
}

- (void)testAContentTheDatasourceRefusesFailsTheWholeRequest {
    BAWSQuery *query = [[BAWSQuery alloc] initWithType:@"atc"];
    self.queryDatasource.rejectsContent = YES;
    BAQueryWebserviceClient *client = [self clientForQueries:@[ query ]];

    [client connectionDidFinishLoadingWithData:[self serverBodyWithQueries:@[
                @{@"id" : query.identifier, @"action" : @"OK"},
            ]]];

    XCTAssertNil(self.queryDelegate.responses);
    XCTAssertNotNil(self.queryDelegate.error);
}

- (void)testAnErroredHeaderIsNotParsedAsQueries {
    BAWSQuery *query = [[BAWSQuery alloc] initWithType:@"atc"];
    BAQueryWebserviceClient *client = [self clientForQueries:@[ query ]];

    NSDictionary *payload = @{
        @"header" : @{@"status" : @"INVALID_APIKEY"},
        @"body" : @{@"queries" : @[ @{@"id" : query.identifier, @"action" : @"OK"} ]}
    };
    [client connectionDidFinishLoadingWithData:[NSJSONSerialization dataWithJSONObject:payload options:0 error:nil]];

    XCTAssertNil(self.queryDelegate.responses);
    XCTAssertNotNil(self.queryDelegate.error);
}

#pragma mark - Helpers

- (BAQueryWebserviceClient *)clientForQueries:(NSArray<id<BAWSQuery>> *)queries {
    self.queryDatasource.queries = queries;
    BAQueryWebserviceClient *client =
        [[BAQueryWebserviceClient alloc] initWithDatasource:self.queryDatasource
                                                   delegate:self.queryDelegate
                                        identifiersProvider:[BATFixtureIdentifiersProvider new]];

    NSDictionary *body = [client requestBodyDictionary];
    XCTAssertEqual([body[@"queries"] count], queries.count);

    return client;
}

- (NSData *)serverBodyWithQueries:(NSArray<NSDictionary *> *)queries {
    NSDictionary *payload = @{@"header" : @{@"status" : @"OK"}, @"body" : @{@"queries" : queries}};
    return [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
}

@end
