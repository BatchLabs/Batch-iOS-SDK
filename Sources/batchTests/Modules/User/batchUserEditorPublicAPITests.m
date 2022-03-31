#import <XCTest/XCTest.h>
@import Batch;
@import Batch.Batch_Private;
#import "OCMock.h"

@interface batchUserEditorPublicAPITests : XCTestCase

@end

/// Tests BatchUserDataEditor's public API
@implementation batchUserEditorPublicAPITests

- (void)testPublicMethods {
    id mockBackingEditor = OCMClassMock(BAUserDataEditor.class);
    __unused id overlay = [BAInjection overlayClass:BAUserDataEditor.class returnedInstance:mockBackingEditor];

    NSError *fakeErr = nil;
    NSDate *date = [NSDate date];
    NSURL *url = [NSURL URLWithString:@"https://batch.com"];
    // OCMock doesn't deal with NSError** well
    // Unfortunately this doesn't test that the error is not nil, but
    // I coudldn't manage to fix it.
    NSError *__autoreleasing *anyError = [OCMArg anyObjectRef];

    BatchUserDataEditor *editor = [BatchUser editor];
    [editor setLanguage:@"fr"];
    [editor setRegion:@"fr"];
    [editor setIdentifier:@"foo"];
    [editor setAttribute:@"foo" forKey:@"bar"];
    [editor setAttribute:nil forKey:@"bar"];
    [editor setBooleanAttribute:true forKey:@"bar" error:&fakeErr];
    [editor setDateAttribute:date forKey:@"bar" error:&fakeErr];
    [editor setStringAttribute:@"foo" forKey:@"bar" error:&fakeErr];
    [editor setNumberAttribute:@2 forKey:@"bar" error:&fakeErr];
    [editor setIntegerAttribute:2 forKey:@"bar" error:&fakeErr];
    [editor setLongLongAttribute:2 forKey:@"bar" error:&fakeErr];
    [editor setFloatAttribute:1.234F forKey:@"bar" error:&fakeErr];
    [editor setDoubleAttribute:1.234L forKey:@"bar" error:&fakeErr];
    [editor setURLAttribute:url forKey:@"bar" error:&fakeErr];
    [editor removeAttributeForKey:@"bar"];
    [editor clearAttributes];
    [editor addTag:@"foo" inCollection:@"bar"];
    [editor removeTag:@"foo" fromCollection:@"bar"];
    [editor clearTags];
    [editor clearTagCollection:@"bar"];
    [editor save];
    OCMVerify([mockBackingEditor setLanguage:@"fr"]);
    OCMVerify([mockBackingEditor setRegion:@"fr"]);
    OCMVerify([mockBackingEditor setIdentifier:@"foo"]);
    OCMVerify([mockBackingEditor setAttribute:@"foo" forKey:@"bar"]);
    OCMVerify([mockBackingEditor setAttribute:nil forKey:@"bar"]);
    OCMVerify([mockBackingEditor setBooleanAttribute:true forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setDateAttribute:date forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setStringAttribute:@"foo" forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setNumberAttribute:@2 forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setIntegerAttribute:2 forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setLongLongAttribute:2 forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setFloatAttribute:1.234F forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setDoubleAttribute:1.234L forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor setURLAttribute:url forKey:@"bar" error:anyError]);
    OCMVerify([mockBackingEditor removeAttributeForKey:@"bar"]);
    OCMVerify([(BAUserDataEditor *)mockBackingEditor clearAttributes]);
    OCMVerify([mockBackingEditor addTag:@"foo" inCollection:@"bar"]);
    OCMVerify([(BAUserDataEditor *)mockBackingEditor removeTag:@"foo" fromCollection:@"bar"]);
    OCMVerify([(BAUserDataEditor *)mockBackingEditor clearTags]);
    OCMVerify([mockBackingEditor clearTagCollection:@"bar"]);
    OCMVerify([mockBackingEditor save]);
}

/// Test that a new instance is injected each time
- (void)testNewInstance {
    BAUserDataEditor *injectedEditor1 = [BAInjection injectClass:BAUserDataEditor.class];
    BAUserDataEditor *injectedEditor2 = [BAInjection injectClass:BAUserDataEditor.class];

    XCTAssertNotEqual(injectedEditor1, injectedEditor2);

    BatchUserDataEditor *editor1 = [BatchUser editor];
    BatchUserDataEditor *editor2 = [BatchUser editor];

    XCTAssertNotEqual(editor1, editor2);

    // Unit tests should test functionality and not ivars, but we really
    // want to make sure that the backing editor is unique
    XCTAssertNotEqual([editor1 valueForKey:@"_backingImpl"], [editor2 valueForKey:@"_backingImpl"]);
}

@end
