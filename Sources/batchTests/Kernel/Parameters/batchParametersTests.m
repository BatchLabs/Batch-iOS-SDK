//
//  BatchParametersTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAParameter.h"

@interface BatchParametersTests : XCTestCase

@end

@implementation BatchParametersTests

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

- (void)testBasics
{
    // Test a non existing value.
    XCTAssertEqualObjects([BAParameter objectForKey:@"not-exist-key" fallback:@"not-exist-value"], @"not-exist-value", @"No value must be found for key 'not-exist-key'.");
    
    NSError *e = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    
    // Test empty fields.
    e = [BAParameter setValue:nil forKey:nil saved:NO];
    XCTAssertNotNil(e, @"An error must be found when all fields are NULL.");
    
    // Tests empty key.
    e = [BAParameter setValue:@"valid-value" forKey:nil saved:NO];
    XCTAssertNotNil(e, @"An error must be found when 'key' is NULL.");
    
    // Tests empty value.
    e = [BAParameter setValue:nil forKey:@"valid-key" saved:NO];
    XCTAssertNotNil(e, @"An error must be found when 'value' is NULL.");
    
    // Test storing a specific value.
    e = [BAParameter setValue:@"specific-value" forKey:@"specific-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a value key-value: %@",e);
    
#pragma clang diagnostic pop
    
}

- (void)testOthers
{
    NSError *e = nil;
    
    // Test storing a boolean.
    e = [BAParameter setValue:@YES forKey:@"fake-bool-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a boolean key-value: %@",e);

    // Test storing a number.
    e = [BAParameter setValue:@42 forKey:@"fake-number-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a number key-value: %@",e);
    
    // Test storing a float number.
    e = [BAParameter setValue:@3.141692664 forKey:@"fake-float-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a float key-value: %@",e);

    // Test storing an array.
    e = [BAParameter setValue:@[@"val1",@"val2"] forKey:@"fake-array-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a array key-value: %@",e);

    // Test storing a dictionary.
    e = [BAParameter setValue:@{@"key1": @"value1"} forKey:@"fake-dic-key" saved:NO];
    XCTAssertNil(e, @"An error has been found storing a dictionary key-value: %@",e);

    // Check results.
    XCTAssertNotEqual([BAParameter objectForKey:@"fake-bool-key" fallback:@"-"], @"-", @"No value found for the boolean value.");
    XCTAssertNotEqual([BAParameter objectForKey:@"fake-number-key" fallback:@"-"], @"-", @"No value found for the number value.");
    XCTAssertNotEqual([BAParameter objectForKey:@"fake-float-key" fallback:@"-"], @"-", @"No value found for the float value.");
    XCTAssertNotEqual([BAParameter objectForKey:@"fake-array-key" fallback:@"-"], @"-", @"No value found for the array value.");
    XCTAssertNotEqual([BAParameter objectForKey:@"fake-dic-key" fallback:@"-"], @"-", @"No value found for the dictionary value.");
}

- (void)testStorage
{
    // Test storing a boolean.
    NSError *e = [BAParameter setValue:@"super-value" forKey:@"fake-super-key" saved:YES];
    XCTAssertNil(e, @"An error has been found storing a regular key-value: %@",e);

    XCTAssertNotEqual([BAParameter objectForKey:@"fake-super-key" fallback:@"-"], @"-", @"No value found for the stored value.");
}

@end
