//
//  webserviceAESGCMCryptorTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "BAWebserviceAESGCMCryptor.h"
#import "BAWebserviceAESGCMGzipCryptor.h"

/** Expose the key from the cryptor factory */
@interface BAWebserviceCryptorFactory ()

+ (NSString *)_baDebugDescription;
+ (NSString *)_baDebugDescriptionV2;

@end

/*
 A BAWebserviceAESGCMCryptor that has a predictable random key
 */
@interface PredictableBAWebserviceAESGCMCryptor : BAWebserviceAESGCMCryptor
@end

/*
 A BAWebserviceAESGCMGzipCryptor that has a predictable random key
 */
@interface PredictableBAWebserviceAESGCMGzipCryptor : BAWebserviceAESGCMGzipCryptor
@end

@interface webserviceAESGCMCryptorTests : XCTestCase

@end

@implementation webserviceAESGCMCryptorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

/*
 Simple test that encrypts some data, decrypts it, and expects it to be the same
 */
- (void)testEncryptDecryptV1 {
    BAWebserviceAESGCMCryptor *cryptor = [[BAWebserviceAESGCMCryptor alloc] initWithKey:[self key] version:@"1"];
    XCTAssertNotNil(cryptor);

    NSData *expectedData = [@"!&é\"'(§è!çà)-12567890°_%^$mù`=*/"
                            @".,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>"
                            @"≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+"
                            @"∫√¢‰∆∑Ω¥∏ªŸ["
                            @"]"
                            @"å”„ック金型илджفيحةحديد" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(expectedData);

    XCTAssertEqualObjects(expectedData, [cryptor decrypt:[cryptor encrypt:expectedData]]);
}

/*
 Simple test that encrypts some data, decrypts it, and expects it to be the same
 */
- (void)testEncryptDecryptV2 {
    BAWebserviceAESGCMGzipCryptor *cryptor = [[BAWebserviceAESGCMGzipCryptor alloc] initWithKey:[self keyV2]
                                                                                        version:@"2"];
    XCTAssertNotNil(cryptor);

    NSData *expectedData = [@"!&é\"'(§è!çà)-12567890°_%^$mù`=*/"
                            @".,?,;:=‘{«ÇøÇø}—ë‘¶Ç¡@#|¿¡ïŒ€£µ~©®†™≈<>"
                            @"≤≥êÊ•π‡∂ƒÌ¬◊ß∞÷≠+"
                            @"∫√¢‰∆∑Ω¥∏ªŸ["
                            @"]"
                            @"å”„ック金型илджفيحةحديد" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(expectedData);

    XCTAssertEqualObjects(expectedData, [cryptor decrypt:[cryptor encrypt:expectedData]]);
}

/*
 Test that the key is indeed random
 */
- (void)testKeyRandomness {
    BAWebserviceAESGCMCryptor *cryptor = [[BAWebserviceAESGCMCryptor alloc] initWithKey:[self key] version:@"1"];
    XCTAssertNotNil(cryptor);

    NSData *sampleData = [@"lorem ipsum dolor" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(sampleData);

    NSData *cryptedData = [cryptor encrypt:sampleData];
    NSData *cryptedData2 = [cryptor encrypt:sampleData];
    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(cryptedData2);

    XCTAssertNotEqualObjects(sampleData, cryptedData);
    XCTAssertNotEqualObjects(sampleData, cryptedData2);
    XCTAssertNotEqualObjects(cryptedData, cryptedData2);
}

/*
 Test that the key is indeed random
 */
- (void)testKeyRandomnessV2 {
    BAWebserviceAESGCMGzipCryptor *cryptor = [[BAWebserviceAESGCMGzipCryptor alloc] initWithKey:[self keyV2]
                                                                                        version:@"2"];
    XCTAssertNotNil(cryptor);

    NSData *sampleData = [@"lorem ipsum dolor" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(sampleData);

    NSData *cryptedData = [cryptor encrypt:sampleData];
    NSData *cryptedData2 = [cryptor encrypt:sampleData];
    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(cryptedData2);

    XCTAssertNotEqualObjects(sampleData, cryptedData);
    XCTAssertNotEqualObjects(sampleData, cryptedData2);
    XCTAssertNotEqualObjects(cryptedData, cryptedData2);
}

/*
 Test that the data is encrypted as we expect it to be
 */
- (void)testEncrypt {
    BAWebserviceAESGCMCryptor *cryptor = [[PredictableBAWebserviceAESGCMCryptor alloc] initWithKey:[self key]
                                                                                           version:@"1"];
    XCTAssertNotNil(cryptor);

    NSData *sampleData = [@"{\"foo\":\"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cryptedData = [cryptor encrypt:sampleData];

    NSData *expectedCryptedData = [@"1ABCDEF8FJr66NgwOT/HT/8E+meFOw==" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNotNil(sampleData);
    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(expectedCryptedData);
    XCTAssertEqualObjects(expectedCryptedData, cryptedData);
}

/*
 Test that the data is encrypted as we expect it to be
 */
- (void)testEncryptV2 {
    BAWebserviceAESGCMGzipCryptor *cryptor = [[PredictableBAWebserviceAESGCMGzipCryptor alloc] initWithKey:[self keyV2]
                                                                                                   version:@"2"];
    XCTAssertNotNil(cryptor);

    NSData *sampleData = [@"{\"foo\":\"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cryptedData = [cryptor encrypt:sampleData];

    NSData *expectedCryptedData = [@"2ABCDEF8A9OOIu/IJJBMDJxfNp89YR9vKBwRtIRKyHYBQPr+Z1lWD0AHdD+Jo//e2scP4Ul2"
        dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNotNil(sampleData);
    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(expectedCryptedData);
    XCTAssertEqualObjects(expectedCryptedData, cryptedData);
}

/*
 Test that a well known payload can be decrypted
 */
- (void)testDecrypt {
    BAWebserviceAESGCMCryptor *cryptor = [[PredictableBAWebserviceAESGCMCryptor alloc] initWithKey:[self key]
                                                                                           version:@"1"];
    XCTAssertNotNil(cryptor);

    NSData *cryptedData = [@"1ABCDEF8GnRX86RD660jcnOyS/q9kg==" dataUsingEncoding:NSUTF8StringEncoding];

    NSData *decryptedData = [cryptor decrypt:cryptedData];

    NSData *expectedDecryptedData = [@"{\"foo\":\"baz\"}" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(decryptedData);
    XCTAssertNotNil(expectedDecryptedData);
    XCTAssertEqualObjects(expectedDecryptedData, decryptedData);
}

/*
 Test that a well known payload can be decrypted
 */
- (void)testDecryptV2 {
    BAWebserviceAESGCMGzipCryptor *cryptor = [[PredictableBAWebserviceAESGCMGzipCryptor alloc] initWithKey:[self keyV2]
                                                                                                   version:@"2"];
    XCTAssertNotNil(cryptor);

    NSData *cryptedData = [@"2ABCDEF8A9OOIu/IJJBMDJxfNp89YR9vKBwRtIRKyHYBQPr+Z1lWD0AHdD+Jo//e2scP4Ul2"
        dataUsingEncoding:NSUTF8StringEncoding];

    NSData *decryptedData = [cryptor decrypt:cryptedData];

    NSData *expectedDecryptedData = [@"{\"foo\":\"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNotNil(cryptedData);
    XCTAssertNotNil(decryptedData);
    XCTAssertNotNil(expectedDecryptedData);
    XCTAssertEqualObjects(expectedDecryptedData, decryptedData);
}

- (NSString *)key {
    return [BAWebserviceCryptorFactory _baDebugDescription];
}

- (NSString *)keyV2 {
    return [BAWebserviceCryptorFactory _baDebugDescriptionV2];
}

@end

@implementation PredictableBAWebserviceAESGCMCryptor

- (NSString *)randomPart {
    return @"1ABCDEF8";
}

@end

@implementation PredictableBAWebserviceAESGCMGzipCryptor

- (NSString *)randomPart {
    return @"2ABCDEF8";
}

@end
