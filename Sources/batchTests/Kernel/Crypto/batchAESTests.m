//
//  BatchAESTests.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAAESB64Cryptor.h"

@interface BatchAESTests : XCTestCase

@end

@implementation BatchAESTests

- (void)setUp {
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown {
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testCreation {
    BAAESB64Cryptor *aes;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

    // Test NULL key case.
    aes = [[BAAESB64Cryptor alloc] initWithKey:nil];
    XCTAssertNil(aes, @"An AES cryptor must not generage an object from a NULL key.");

#pragma clang diagnostic pop

    // Test empty key case.
    aes = [[BAAESB64Cryptor alloc] initWithKey:@""];
    XCTAssertNil(aes, @"An AES cryptor must not generage an object from an empty key.");

    // Test invalid size key case.
    aes = [[BAAESB64Cryptor alloc] initWithKey:@"12345678901234567"];
    XCTAssertNil(aes, @"An AES cryptor must not generage an object from a too long key.");

    // Test with a valid key.
    aes = [[BAAESB64Cryptor alloc] initWithKey:@"1234567890123456"];
    XCTAssertNotNil(aes, @"Fail to creat an AES cryptor using a valid key.");

    // Test with a strange valid key.
    aes = [[BAAESB64Cryptor alloc] initWithKey:@"@&'(§è!çà)"];
    XCTAssertNotNil(aes, @"Fail to creat an AES cryptor using a valid key.");
}

- (void)testDataCryption {
    NSData *uncrypted;
    NSData *crypted;
    NSData *decrypted;

    // Build a valid cryptor.
    BAAESB64Cryptor *aes = [[BAAESB64Cryptor alloc] initWithKey:@"1234567890123456"];
    XCTAssertNotNil(aes, @"Fail to creat an AES cryptor using a valid key.");

    // Test with a simple short data.
    uncrypted = [@"A" dataUsingEncoding:NSUTF8StringEncoding];
    crypted = [aes encryptData:uncrypted];
    XCTAssert([uncrypted isEqualToData:crypted] == NO, @"Failed to crypt data from string 'A'.");
    XCTAssertEqualObjects([[NSString alloc] initWithData:crypted encoding:NSUTF8StringEncoding],
                          @"WLTZqPgfNVg0kKu4lmwVuQ==");

    decrypted = [aes decryptData:crypted];
    XCTAssert([uncrypted isEqualToData:decrypted] == YES, @"Failed to uncrypt data from string 'A'.");

    // Test with a long and complex data.
    NSString *start = @"!&é\"'(§è!çà)-12567890°_%^$mù`=*/"
                      @".,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+"
                      @"∫√¢‰∆∑Ω¥∏ªŸ["
                      @"]"
                      @"å”„ック金型илджفيحةحديد";
    uncrypted = [start dataUsingEncoding:NSUTF8StringEncoding];
    crypted = [aes encryptData:uncrypted];
    XCTAssert([uncrypted isEqualToData:crypted] == NO, @"Failed to crypt data from complex string.");
    XCTAssertEqualObjects(
        [[NSString alloc] initWithData:crypted encoding:NSUTF8StringEncoding],
        @"fwtelQDEu/EZXVw/24whGos6hLzk6Pa+vqaE/8uPzuB3tWWP5wcOcY+A2G3Rdy2fvZCTrVKMq1pxdzYIqk+OapTdLfqlLCn9Fx2TO68r/"
        @"eYzmaebuX8C13vWp9pFQSma3qp+DkWQ8NmROoXea57bgIOa+RXFFovwijqhaaAvqj0h17pTczvYf4WZ1Pkrzhd7ak0pV7ezHfj+"
        @"0kkdzLG7Oh+CfWH8bdt3h3kbYHl31jlmgXuV+A9D+3HodpKJWND8eFcp4jEKOf5eP7t+"
        @"9NoHWtAFcWoZnFHvnYwOW5T0GQMqyg4R6zlDjQYRuTP+X0ae");

    decrypted = [aes decryptData:crypted];
    XCTAssert([uncrypted isEqualToData:decrypted] == YES, @"Failed to uncrypt data from complex string.");
}

- (void)testStringCryption {
    NSString *uncrypted;
    NSString *crypted;
    NSString *decrypted;

    // Build a valid cryptor.
    BAAESB64Cryptor *aes = [[BAAESB64Cryptor alloc] initWithKey:@"1234567890123456"];
    XCTAssertNotNil(aes, @"Fail to creat an AES cryptor using a valid key.");

    // Test with a simple short data.
    uncrypted = @"A";
    crypted = [aes encrypt:uncrypted];
    XCTAssert([uncrypted isEqualToString:crypted] == NO, @"Failed to crypt string from string 'A'.");
    XCTAssertEqualObjects(crypted, @"WLTZqPgfNVg0kKu4lmwVuQ==");

    decrypted = [aes decrypt:crypted];
    XCTAssert([uncrypted isEqualToString:decrypted] == YES, @"Failed to uncrypt string from string 'A'.");

    // Test with a long and complex data.
    uncrypted = @"!&é\"'(§è!çà)-12567890°_%^$mù`=*/"
                @".,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+"
                @"∫√¢‰∆∑Ω¥∏ªŸ["
                @"]"
                @"å”„ック金型илджفيحةحديد";
    crypted = [aes encrypt:uncrypted];
    XCTAssert([uncrypted isEqualToString:crypted] == NO, @"Failed to crypt string from complex string.");
    XCTAssertEqualObjects(
        crypted,
        @"fwtelQDEu/EZXVw/24whGos6hLzk6Pa+vqaE/8uPzuB3tWWP5wcOcY+A2G3Rdy2fvZCTrVKMq1pxdzYIqk+OapTdLfqlLCn9Fx2TO68r/"
        @"eYzmaebuX8C13vWp9pFQSma3qp+DkWQ8NmROoXea57bgIOa+RXFFovwijqhaaAvqj0h17pTczvYf4WZ1Pkrzhd7ak0pV7ezHfj+"
        @"0kkdzLG7Oh+CfWH8bdt3h3kbYHl31jlmgXuV+A9D+3HodpKJWND8eFcp4jEKOf5eP7t+"
        @"9NoHWtAFcWoZnFHvnYwOW5T0GQMqyg4R6zlDjQYRuTP+X0ae");

    decrypted = [aes decrypt:crypted];
    XCTAssert([uncrypted isEqualToString:decrypted] == YES, @"Failed to uncrypt string from complex string: %@",
              decrypted);
}

@end
