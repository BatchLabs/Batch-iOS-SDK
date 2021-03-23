//
//  BatchPropertiesCenterTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

#import "BAPropertiesCenter.h"
#import "BANotificationAuthorization.h"

@interface BatchPropertiesCenterTests : XCTestCase

@end

@implementation BatchPropertiesCenterTests

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

- (void)testValues
{
    NSString *value;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    // Test NULL selector case.
    value = [BAPropertiesCenter valueForShortName:nil];
#pragma clang diagnostic pop
    XCTAssertNil(value, @"Properties center must return nil from a NULL selector string.");
    
    // Test empty selector case.
    value = [BAPropertiesCenter valueForShortName:@""];
    XCTAssertNil(value, @"Properties center must return nil from an empty selector string.");
    
    // Test not existing selector case.
    value = [BAPropertiesCenter valueForShortName:@"fakeSelector"];
    XCTAssertNil(value, @"Properties center must not return a value from a NULL selector string.");
    
    // Test shorten selector case.
    value = [BAPropertiesCenter valueForShortName:@"dla"];
    XCTAssertNotNil(value, @"Properties center failed to return the device language.");
}

/**
 * Test that the local install ID is somewhat persistent
 */
- (void)testLocalInstall
{
    NSString *di1 = [BAPropertiesCenter valueForShortName:@"di"];
    NSString *di2 = [BAPropertiesCenter valueForShortName:@"di"];
    XCTAssertNotNil(di1, @"Local install ids (di) should never be nil");
    XCTAssertNotNil(di2, @"Local install ids (di) should never be nil");
    XCTAssertEqualObjects(di1, di2, @"Inconsistent local install ids (di)");
}

- (void)testDates
{
    NSString *value;
    
    value = [BAPropertiesCenter valueForShortName:@"da"];
    XCTAssertNotNil(value, @"Properties center failed to return the formated date.");
    
    XCTAssertTrue([value rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@",pam "] options:NSCaseInsensitiveSearch].location == NSNotFound, @"Properties center returned an invalid date.");
    
    NSDateFormatter *formater = [NSDateFormatter new];
    [formater setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [formater setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formater setDateFormat:kParametersDateFormat];
    NSDate *date = [formater dateFromString:value];
    XCTAssertNotNil(date, @"Cannot retrieve the original date.");
    
    NSCalendar *utcCalendar = [NSCalendar currentCalendar];
    [utcCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    NSDateComponents *components = [utcCalendar components:0b11111111 fromDate:date];
    NSDateComponents *currentComponents = [utcCalendar components:0b11111111 fromDate:[NSDate date]];
    
    NSInteger year = [components year];
    NSInteger currentYear = [currentComponents year];
    XCTAssertEqual(year, currentYear, @"Invalid time.");
    
    NSInteger month = [components month];
    NSInteger currentMonth = [currentComponents month];
    XCTAssertEqual(month, currentMonth, @"Invalid time.");
    
    NSInteger day = [components day];
    NSInteger currentDay = [currentComponents day];
    XCTAssertEqual(day, currentDay, @"Invalid time.");
    
    NSInteger hour = [components hour];
    NSInteger currentHour = [currentComponents hour];
    XCTAssertEqual(hour, currentHour, @"Invalid time.");
}

- (void)testNotifType
{
    BANotificationAuthorizationSettings *authSettings = [BANotificationAuthorizationSettings new];
    
    BAPropertiesCenter *properties = OCMPartialMock([BAPropertiesCenter new]);
    OCMStub([properties notifTypeFallback]).andReturn(@"fallback");
    OCMStub([properties notificationAuthorizationSettings]).andReturn(authSettings);
    
    authSettings.status = BANotificationAuthorizationStatusWaitingForValue;
    
    XCTAssertEqualObjects(@"fallback", [properties notifType], @"Expected fallback when BANotificationAuthorization is waiting for a value");
    
    authSettings.status = BANotificationAuthorizationStatusDenied;
    
    XCTAssertEqualObjects(@"0", [properties notifType], @"Expected 0 when BANotificationAuthorization is not requested");
    
    authSettings.status = BANotificationAuthorizationStatusProvisional;
    
    XCTAssertEqualObjects(@"0", [properties notifType], @"Expected 0 when BANotificationAuthorization is not denied");
    
    authSettings.status = BANotificationAuthorizationStatusGranted;
    authSettings.types = BANotificationAuthorizationTypesBadge;
    
    XCTAssertEqualObjects(@"1", [properties notifType], @"Expected 1 when badge only");
    
    authSettings.types = BANotificationAuthorizationTypesSound;
    
    XCTAssertEqualObjects(@"2", [properties notifType], @"Expected 1 when sound only");
    
    NSString *expectedAlert = [@(1 << 2) stringValue];
    
    authSettings.types = BANotificationAuthorizationTypesAlert;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesLockscreen;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesAlert |
                            BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesAlert |
                            BANotificationAuthorizationTypesLockscreen;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesAlert |
                            BANotificationAuthorizationTypesLockscreen |
                            BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesLockscreen |
                            BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(expectedAlert, [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesBadge | BANotificationAuthorizationTypesSound;
    XCTAssertEqualObjects(@"3", [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesBadge |
                    BANotificationAuthorizationTypesSound |
                    BANotificationAuthorizationTypesAlert |
                    BANotificationAuthorizationTypesLockscreen |
                    BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(@"7", [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesBadge |
                    BANotificationAuthorizationTypesSound |
                    BANotificationAuthorizationTypesAlert |
                    BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(@"7", [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesBadge |
                    BANotificationAuthorizationTypesSound |
                    BANotificationAuthorizationTypesNotificationCenter;
    XCTAssertEqualObjects(@"7", [properties notifType]);
    
    authSettings.types = BANotificationAuthorizationTypesBadge |
                    BANotificationAuthorizationTypesSound |
                    BANotificationAuthorizationTypesAlert;
    XCTAssertEqualObjects(@"7", [properties notifType]);
}

@end
