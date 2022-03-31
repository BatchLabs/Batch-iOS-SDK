//
//  BatchNSURLREquest+BAHeadersTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAHTTPHeaders.h"

@interface BAHTTPHeaders ()

// Expose makeuseragent as useragent has cache
+ (NSString *)makeUserAgent;

@end

@interface BatchNSURLREquest_BAHeadersTests : XCTestCase

@end

@implementation BatchNSURLREquest_BAHeadersTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPluginsEnv {
    NSString *userAgent = [BAHTTPHeaders userAgent];
    XCTAssertNotNil(userAgent, @"User-Agent must not be nil.");

    // Setup plugin version.
    NSString *pluginInfos = [NSString stringWithFormat:@"Unity/0.1"];
    setenv("BATCH_PLUGIN_VERSION", [pluginInfos cStringUsingEncoding:NSUTF8StringEncoding], 1);

    userAgent = [BAHTTPHeaders makeUserAgent];
    XCTAssertTrue([userAgent rangeOfString:pluginInfos].location != NSNotFound, @"Plugin infos not found.");

    // Setup bridge version.
    NSString *bridgeInfos = [NSString stringWithFormat:@"Bridge/0.1"];
    setenv("BATCH_BRIDGE_VERSION", [bridgeInfos cStringUsingEncoding:NSUTF8StringEncoding], 1);

    userAgent = [BAHTTPHeaders makeUserAgent];
    XCTAssertTrue([userAgent rangeOfString:pluginInfos].location != NSNotFound, @"Plugin infos not found.");
    XCTAssertTrue([userAgent rangeOfString:bridgeInfos].location != NSNotFound, @"Bridge infos not found.");

    unsetenv("BATCH_PLUGIN_VERSION");
    unsetenv("BATCH_BRIDGE_VERSION");

    userAgent = [BAHTTPHeaders makeUserAgent];
    XCTAssertTrue([userAgent rangeOfString:pluginInfos].location == NSNotFound, @"Plugin infos keept in env.");
    XCTAssertTrue([userAgent rangeOfString:bridgeInfos].location == NSNotFound, @"Bridge infos keept in env.");
}

@end
