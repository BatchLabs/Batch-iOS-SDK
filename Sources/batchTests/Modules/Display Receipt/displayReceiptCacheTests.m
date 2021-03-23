//
//  displayReceiptCacheTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BADisplayReceiptCache.h"
#import "BABundleInfo.h"

#import "OCMock.h"

@interface BADisplayReceiptCache (Private)

+ (nullable NSUserDefaults *)sharedDefaults;

@end

@interface displayReceiptCacheTests : XCTestCase

@property (nonatomic) id sharedGroupMock;

@end

@implementation displayReceiptCacheTests

- (void)setUp
{
    [super setUp];
    
    _sharedGroupMock = OCMClassMock([BABundleInfo class]);
    OCMStub([_sharedGroupMock sharedGroupId]).andReturn(@"test-shared-app-group");
}

- (void)tearDown
{
    [super tearDown];
    
    [_sharedGroupMock stopMocking];
    _sharedGroupMock = nil;
}

- (void)testSharedDefaults
{
    [BADisplayReceiptCache saveApiKey:@"bim"];
    XCTAssertEqual(BADisplayReceiptCache.apiKey, @"bim");
    
    [BADisplayReceiptCache saveLastInstallId:@"zbam"];
    XCTAssertEqual(BADisplayReceiptCache.lastInstallId, @"zbam");
    
    XCTAssertFalse(BADisplayReceiptCache.isOptOut);
    [BADisplayReceiptCache saveIsOptOut:true];
    XCTAssertTrue(BADisplayReceiptCache.isOptOut);
    
    [self resetDefaults:BABundleInfo.sharedDefaults];
}

- (void)resetDefaults:(NSUserDefaults *)defaults
{
    NSDictionary *dict = [defaults dictionaryRepresentation];
    for (id key in dict) {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}

@end
