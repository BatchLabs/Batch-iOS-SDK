//
//  batchUserProfileTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"

#import "BatchCore.h"
#import "BAUserProfile.h"
#import "BatchUserProfile.h"
#import "BAParameter.h"

@interface MockedBAParameter : NSObject
@end

@implementation MockedBAParameter
{
    NSMutableDictionary *_backingDict;
}

- (instancetype)init
{
    self = [super self];
    if (self) {
        _backingDict = [NSMutableDictionary new];
    }
    return self;
}

- (id)objectForKey:(NSString *)key fallback:(id)fallback
{
    id val = _backingDict[key];
    return val != nil ? val : fallback;
}

- (NSError *)setValue:(id)value forKey:(NSString *)key saved:(BOOL)save
{
    if (key == nil) {
        return [NSError errorWithDomain:@"tests" code:0 userInfo:nil];
    }
    
    if (value == nil) {
        return [NSError errorWithDomain:@"tests" code:1 userInfo:nil];
    }
    
    [_backingDict setObject:value forKey:key];
    
    return nil;
}

- (NSError *)removeObjectForKey:(NSString *)key
{
    [_backingDict removeObjectForKey:key];
    return nil;
}

@end

@interface batchUserProfileTests : XCTestCase

@end

@implementation batchUserProfileTests
{
    MockedBAParameter *mockedBaParameterImpl;
    id baParameterMock;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // Mock the BAParameter class, because NSUserDefaults is a broken pile of shit on the simulator
    
    mockedBaParameterImpl = [MockedBAParameter new];
    baParameterMock = OCMClassMock([BAParameter class]);
    
    OCMStub(ClassMethod([baParameterMock objectForKey:[OCMArg any] fallback:[OCMArg any]])).andCall(mockedBaParameterImpl, @selector(objectForKey:fallback:));
    OCMStub(ClassMethod([baParameterMock setValue:[OCMArg any] forKey:[OCMArg any] saved:YES])).andCall(mockedBaParameterImpl, @selector(setValue:forKey:saved:));
    OCMStub(ClassMethod([baParameterMock setValue:[OCMArg any] forKey:[OCMArg any] saved:NO])).andCall(mockedBaParameterImpl, @selector(setValue:forKey:saved:));
    OCMStub(ClassMethod([(Class)baParameterMock removeObjectForKey:[OCMArg any]])).andCall(mockedBaParameterImpl, @selector(removeObjectForKey:));
    
    BatchUserProfile *profile = [Batch defaultUserProfile];
    [profile setRegion:nil];
    [profile setLanguage:nil];
    [profile setCustomIdentifier:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [baParameterMock stopMocking];
}

- (void)testBasics
{
    BAUserProfile *profile = [BAUserProfile defaultUserProfile];
    XCTAssertNotNil(profile, @"Failed to get the default profile.");
    
    NSString *customIdentifier = [profile customIdentifier];
    XCTAssertNil(customIdentifier, @"Custom identifier not nil: %@.",customIdentifier);
    
    [profile setCustomIdentifier:@"batch.unit.tests"];
    customIdentifier = [profile customIdentifier];
    XCTAssertNotNil(customIdentifier, @"Failed to get the custom identifier.");
    XCTAssertTrue([@"batch.unit.tests" isEqualToString:customIdentifier], @"Custom identifier not stored.");
    
    [profile setCustomIdentifier:nil];
    customIdentifier = [profile customIdentifier];
    XCTAssertNil(customIdentifier, @"Custom identifier not nil.");
    
    NSString *language = [profile language];
    XCTAssertNil(language, @"Default custom language value should be nil.");
    
    [profile setLanguage:@"batch.language"];
    language = [profile language];
    XCTAssertNotNil(language, @"Failed to get the language.");
    XCTAssertTrue([@"batch.language" isEqualToString:language], @"Language not stored: %@.",language);
    
    [profile setLanguage:nil];
    language = [profile language];
    XCTAssertNil(language, @"Language not nil.");
    
    NSString *region = [profile language];
    XCTAssertNil(region, @"Default custom region value should be nil.");
    
    [profile setRegion:@"batch.region"];
    region = [profile region];
    XCTAssertNotNil(region, @"Failed to get the region.");
    XCTAssertTrue([@"batch.region" isEqualToString:region], @"Region not stored: %@.",region);
    
    [profile setRegion:nil];
    region = [profile region];
    XCTAssertNil(region, @"Region not nil.");
}

- (void)testVersion
{
    BatchUserProfile *profile = [Batch defaultUserProfile];
    XCTAssertNotNil(profile, @"Failed to get the default profile.");
    
    BAUserProfile *internalProfile = [BAUserProfile defaultUserProfile];
    XCTAssertNotNil(profile, @"Failed to get the internal profile.");
    
    NSNumber *firstVersion = [internalProfile version];
    NSNumber *version = [internalProfile version];
    XCTAssertNotNil(version, @"Profile version should not be nil.");
    
    // Test both change and lack of change for a value, and for nil, for every user profile parameter
    
    // Region
    version = [internalProfile version];
    [profile setRegion:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setRegion:@"en"];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    version = [internalProfile version];
    [profile setRegion:nil];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setRegion:nil];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    version = [internalProfile version];
    [profile setRegion:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    // Language
    version = [internalProfile version];
    [profile setLanguage:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setLanguage:@"en"];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    version = [internalProfile version];
    [profile setLanguage:nil];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setLanguage:nil];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    [profile setLanguage:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    // Custom ID
    version = [internalProfile version];
    [profile setCustomIdentifier:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setCustomIdentifier:@"en"];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    version = [internalProfile version];
    [profile setCustomIdentifier:nil];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    version = [internalProfile version];
    [profile setCustomIdentifier:nil];
    XCTAssertEqualObjects(version, [internalProfile version], @"Profile version should not have changed");
    
    [profile setCustomIdentifier:@"en"];
    [internalProfile incrementVersion];
    XCTAssertNotEqualObjects(version, [internalProfile version], @"Profile version should have changed");
    
    XCTAssertGreaterThan([[internalProfile version] longLongValue], [firstVersion longLongValue], @"Profile version should be greater than when we started");
}

#pragma clang diagnostic pop

@end
