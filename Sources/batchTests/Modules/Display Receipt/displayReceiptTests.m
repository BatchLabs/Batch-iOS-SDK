//
//  displayReceiptTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BADisplayReceipt.h"

@interface displayReceiptTests : XCTestCase

@end

@implementation displayReceiptTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSData *)dataFromHexString:(NSString *)string {
    string = [string lowercaseString];
    NSMutableData *data = [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0', '\0', '\0'};
    int i = 0;
    unsigned long length = string.length;
    while (i < length - 1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

- (NSString *)hexStringFromData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return [NSString string];
    }

    NSUInteger dataLength = [data length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}

- (void)testPackUnpack {
    NSArray *nestedList = @[ @false, @"testList", @25.69745, @654, [NSNull null] ];

    NSDictionary *nestedOd =
        @{@"bool" : @false, @"int" : @654, @"float" : @64.285, @"list" : nestedList, @"null" : [NSNull null]};

    NSDictionary *od = @{
        @"n" : @"je-suis-un-notification-id",
        @"t" : @"je-suis-un-campaign-token",
        @"ak" : @"je-suis-une-apikey",
        @"di" : @"je-suis-un-install-id",
        @"null" : [NSNull null],
        @"map" : nestedOd,
        @"list" : nestedList,
        @"bool_true" : @true,
        @"bool_false" : @false
    };

    NSDictionary *ed =
        @{@"i" : @"je-suis-un-send-id", @"e" : @"je-suis-un-experiment-id", @"v" : @"je-suis-un-varient-id"};

    BADisplayReceipt *receipt = [[BADisplayReceipt alloc] initWithTimestamp:123456
                                                                     replay:false
                                                                sendAttempt:19
                                                                   openData:od
                                                                  eventData:ed];
    XCTAssertNotNil(receipt);
    NSError *error;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);

    BADisplayReceipt *unpackReceipt = [BADisplayReceipt unpack:packedData error:&error];
    XCTAssertNotNil(unpackReceipt);
    XCTAssertNil(error);

    XCTAssertEqual([unpackReceipt timestamp], 123456);
    XCTAssertEqual([unpackReceipt replay], false);
    XCTAssertEqual([unpackReceipt sendAttempt], 19);
    XCTAssert([od isEqualToDictionary:[unpackReceipt od]]);
    XCTAssert([ed isEqualToDictionary:[unpackReceipt ed]]);
}

- (void)testPackEmptyMap {
    BADisplayReceipt *receipt = [[BADisplayReceipt alloc] initWithTimestamp:65481651581
                                                                     replay:true
                                                                sendAttempt:6585
                                                                   openData:@{}
                                                                  eventData:@{}];
    XCTAssertNotNil(receipt);
    NSError *error;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);

    XCTAssert([@"cf0000000f3f02b57dc3cd19b9c0c0" isEqualToString:[self hexStringFromData:packedData]]);
}

- (void)testPackNil {
    BADisplayReceipt *receipt = [[BADisplayReceipt alloc] initWithTimestamp:65481651581
                                                                     replay:true
                                                                sendAttempt:6585
                                                                   openData:nil
                                                                  eventData:nil];
    XCTAssertNotNil(receipt);
    NSError *error;
    NSData *packedData = [receipt pack:&error];
    XCTAssertNotNil(packedData);
    XCTAssertNil(error);

    XCTAssert([@"cf0000000f3f02b57dc3cd19b9c0c0" isEqualToString:[self hexStringFromData:packedData]]);
}

- (void)testUnpackNil {
    NSData *packedData = [self dataFromHexString:@"cf0000000f3f02b57dc3cd19b9c0c0"];
    NSError *error;
    BADisplayReceipt *unpackReceipt = [BADisplayReceipt unpack:packedData error:&error];
    XCTAssertNotNil(unpackReceipt);
    XCTAssertNil(error);

    XCTAssertNil([unpackReceipt od]);
    XCTAssertNil([unpackReceipt ed]);
}

@end
