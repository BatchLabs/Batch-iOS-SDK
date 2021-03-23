//
//  webserviceCryptorFactoryTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCMock.h"

#import "BAWebserviceCryptorFactory.h"
#import "BAWebserviceCryptor.h"
#import "BAWebserviceStubCryptor.h"
#import "BAWebserviceAESGCMCryptor.h"
#import "BAWebserviceAESGCMGzipCryptor.h"
#import "BAConnection.h"

@interface webserviceCryptorFactoryTests : XCTestCase

@end

@implementation webserviceCryptorFactoryTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testOutbound {
    BAConnection *connection = OCMClassMock([BAConnection class]);
    OCMStub([connection isDowngradedCipher]).andReturn(YES);
    OCMStub([connection contentType]).andReturn(BAConnectionContentTypeJSON);
    XCTAssertTrue([[BAWebserviceCryptorFactory outboundCryptorForConnection:connection] isKindOfClass:[BAWebserviceAESGCMCryptor class]]);

    connection = OCMClassMock([BAConnection class]);
    OCMStub([connection isDowngradedCipher]).andReturn(NO);
    OCMStub([connection contentType]).andReturn(BAConnectionContentTypeJSON);
    XCTAssertTrue([[BAWebserviceCryptorFactory outboundCryptorForConnection:connection] isKindOfClass:[BAWebserviceAESGCMGzipCryptor class]]);
    
    connection = OCMClassMock([BAConnection class]);
    OCMStub([connection contentType]).andReturn(BAConnectionContentTypeMessagePack);
    XCTAssertTrue([[BAWebserviceCryptorFactory outboundCryptorForConnection:connection] isKindOfClass:[BAWebserviceStubCryptor class]]);
}

- (void)testInbound {
    NSData *ciphedInboundPayload = [@"1ABCDEF8GnRX86RD660jcnOyS/q9kg==" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(ciphedInboundPayload);
    
    id<BAWebserviceCryptor> cryptor;
    NSHTTPURLResponse *response = OCMClassMock([NSHTTPURLResponse class]);

    BAConnection *connection = OCMClassMock([BAConnection class]);
    OCMStub([connection isDowngradedCipher]).andReturn(YES);
    OCMStub([connection contentType]).andReturn(BAConnectionContentTypeJSON);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceAESGCMCryptor class]]);

    connection = OCMClassMock([BAConnection class]);
    OCMStub([connection isDowngradedCipher]).andReturn(NO);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceAESGCMCryptor class]]);

    NSMutableDictionary *headers = [NSMutableDictionary new];
    [headers setObject:@"1" forKey:@"X-Batch-Content-Cipher"];

    OCMStub([response allHeaderFields]).andReturn(headers);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceAESGCMCryptor class]]);

    [headers setObject:@"2" forKey:@"X-Batch-Content-Cipher"];

    response = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([response allHeaderFields]).andReturn(headers);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceAESGCMGzipCryptor class]]);

    [headers setObject:@"3" forKey:@"X-Batch-Content-Cipher"];

    response = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([response allHeaderFields]).andReturn(headers);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceAESGCMCryptor class]]);
    
    connection = OCMClassMock([BAConnection class]);
    OCMStub([connection contentType]).andReturn(BAConnectionContentTypeMessagePack);
    cryptor = [BAWebserviceCryptorFactory inboundCryptorForData:ciphedInboundPayload connection:connection response:response];
    XCTAssertTrue([cryptor isKindOfClass:[BAWebserviceStubCryptor class]]);
}

@end
