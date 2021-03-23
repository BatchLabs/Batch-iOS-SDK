//
//  jsonTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAJson.h"

@interface jsonTests : XCTestCase {
    NSDictionary* dictionary;
    NSArray* array;
}
@end

@implementation jsonTests

- (instancetype)init
{
    self = [super init];
    if (self) {
        dictionary = @{@"array":@[@1,@2,@3],@"array2":@[@{@"number":@1,@"string":@"JetLag"},@{@"number":@2,@"string":@"Foo"}]};
        array = @[@1, @{@"array":@[@1,@2,@3],@"array2":@[@{@"number":@1,@"string":@"JetLag"},@{@"number":@2,@"string":@"Foo"}]}];
    }
    return self;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDeserialization {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSError *err;
    XCTAssertNil([BAJson deserialize:nil error:&err]);
    XCTAssertNotNil(err);
    
    err = nil;
    XCTAssertNil([BAJson deserializeData:nil error:&err]);
    XCTAssertNotNil(err);
#pragma clang diagnostic pop
    
    err = nil;
    XCTAssertNil([BAJson deserialize:@"\"foo\"" error:&err]);
    XCTAssertNotNil(err);
    err = nil;
    XCTAssertNil([BAJson deserialize:@"2" error:&err]);
    XCTAssertNotNil(err);
    err = nil;
    XCTAssertNil([BAJson deserialize:@"true" error:&err]);
    XCTAssertNotNil(err);
    err = nil;
    XCTAssertNil([BAJson deserialize:@"😬" error:&err]);
    XCTAssertNotNil(err);
    
    err = nil;
    XCTAssertNotNil([BAJson deserialize:@"[]" error:&err]);
    XCTAssertNil(err);
    
    err = nil;
    XCTAssertNotNil([BAJson deserializeAsArray:@"[]" error:&err]);
    XCTAssertNil(err);
    err = nil;
    XCTAssertNil([BAJson deserializeAsDictionary:@"[]" error:&err]);
    XCTAssertNotNil(err);
    
    err = nil;
    XCTAssertNil([BAJson deserializeAsArray:@"{}" error:&err]);
    XCTAssertNotNil(err);
    err = nil;
    XCTAssertNotNil([BAJson deserializeAsDictionary:@"{}" error:&err]);
    XCTAssertNil(err);
}

- (void)testSerialization {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSError *err;
    XCTAssertNil([BAJson serialize:nil error:&err]);
    XCTAssertNotNil(err);
    
    err = nil;
    XCTAssertNil([BAJson serializeData:nil error:&err]);
    XCTAssertNotNil(err);
#pragma clang diagnostic pop
    
    NSDictionary *emptyDict = @{};
    id result = nil;
    
    err = nil;
    result = [BAJson serialize:emptyDict error:&err];
    XCTAssertTrue([result isKindOfClass:NSString.class]);
    XCTAssertNil(err);
    
    err = nil;
    result = [BAJson serializeData:emptyDict error:&err];
    XCTAssertTrue([result isKindOfClass:NSData.class]);
    XCTAssertNil(err);
    
    NSArray *emptyArray = @[];
    
    err = nil;
    result = [BAJson serialize:emptyArray error:&err];
    XCTAssertTrue([result isKindOfClass:NSString.class]);
    XCTAssertNil(err);
    
    err = nil;
    result = [BAJson serializeData:emptyArray error:&err];
    XCTAssertTrue([result isKindOfClass:NSData.class]);
    XCTAssertNil(err);
    
    NSNumber *number = @2;
    NSString *str = @"foo";
    err = nil;
    XCTAssertNil([BAJson serializeData:number error:&err]);
    XCTAssertNotNil(err);
    err = nil;
    XCTAssertNil([BAJson serializeData:str error:&err]);
    XCTAssertNotNil(err);
}

- (void)testBoth {
    XCTAssertEqual(dictionary, [BAJson deserializeAsDictionary:[BAJson serialize:dictionary error:nil] error:nil]);
    XCTAssertEqual(array, [BAJson deserializeAsArray:[BAJson serialize:array error:nil] error:nil]);
    XCTAssertNil([BAJson deserializeAsArray:[BAJson serialize:dictionary error:nil] error:nil]);
    XCTAssertNil([BAJson deserializeAsDictionary:[BAJson serialize:array error:nil] error:nil]);
}

@end
