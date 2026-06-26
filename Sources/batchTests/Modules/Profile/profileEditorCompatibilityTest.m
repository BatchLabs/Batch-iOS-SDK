//
//  BatchTests
//
//  Copyright © Batch. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BAInstallDataEditor.h"
#import "BatchProfile.h"

#import "OCMock.h"

@interface profileEditorCompatibilityTest : XCTestCase {
}
@end

@implementation profileEditorCompatibilityTest

- (void)testProfileEditorInstallCompatibility {
    id installDataEditorMock = OCMClassMock([BAInstallDataEditor class]);
    [installDataEditorMock setExpectationOrderMatters:YES];

    BAOverlayedInjectable *overlay =
        [BAInjection overlayClass:BAInstallDataEditor.class returnedInstance:installDataEditorMock];

    NSDate *testDate = [NSDate now];
    NSURL *testURL = [NSURL URLWithString:@"https://batch.com"];

    OCMExpect([installDataEditorMock setLanguage:@"fr"]);
    OCMExpect([installDataEditorMock setRegion:@"US"]);
    OCMExpect([installDataEditorMock removeAttributeForKey:@"remove"]);
    OCMExpect([installDataEditorMock clearTagCollection:@"remove"]);
    OCMExpect([installDataEditorMock setBooleanAttribute:true forKey:@"bool" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setDateAttribute:testDate forKey:@"date" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setStringAttribute:@"foo" forKey:@"str" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setLongLongAttribute:23 forKey:@"int" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setLongLongAttribute:24 forKey:@"intl" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setDoubleAttribute:25 forKey:@"float" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setDoubleAttribute:26 forKey:@"dbl" error:[OCMArg anyObjectRef]]);
    OCMExpect([installDataEditorMock setURLAttribute:testURL forKey:@"url" error:[OCMArg anyObjectRef]]);

    OCMExpect([installDataEditorMock clearTagCollection:@"strarray"]);
    OCMExpect([installDataEditorMock addTag:@"foo" inCollection:@"strarray"]);
    OCMExpect([installDataEditorMock addTag:@"bar" inCollection:@"strarray"]);
    OCMExpect([installDataEditorMock addTag:@"baz" inCollection:@"strarray2"]);
    OCMExpect([(BAInstallDataEditor *)installDataEditorMock removeTag:@"zab" fromCollection:@"strarray3"]);

    OCMExpect([installDataEditorMock save]);

    [BatchProfile editWithBlock:^(BatchProfileEditor *_Nonnull editor) {
      [editor setLanguage:@"fr" error:nil];
      [editor setRegion:@"US" error:nil];
      [editor removeAttributeForKey:@"remove" error:nil];
      [editor setBooleanAttribute:true forKey:@"bool" error:nil];
      [editor setDateAttribute:testDate forKey:@"date" error:nil];
      [editor setStringAttribute:@"foo" forKey:@"str" error:nil];
      [editor setIntegerAttribute:23 forKey:@"int" error:nil];
      [editor setLongLongAttribute:24 forKey:@"intl" error:nil];
      // We can't easily test primitive float values using OCMock, the matching
      // will randomly fail and we can't make a custom matcher
      [editor setFloatAttribute:25 forKey:@"float" error:nil];
      [editor setDoubleAttribute:26 forKey:@"dbl" error:nil];
      [editor setURLAttribute:testURL forKey:@"url" error:nil];

      [editor setStringArrayAttribute:@[ @"foo", @"bar" ] forKey:@"strarray" error:nil];
      [editor addItemToStringArrayAttribute:@"baz" forKey:@"strarray2" error:nil];
      [editor removeItemFromStringArrayAttribute:@"zab" forKey:@"strarray3" error:nil];
    }];

    OCMVerifyAll(installDataEditorMock);
}

- (void)testProfileEditorSaveRejectedWhenPayloadTooLarge {
    id installDataEditorMock = OCMClassMock([BAInstallDataEditor class]);
    BAOverlayedInjectable *overlay =
        [BAInjection overlayClass:BAInstallDataEditor.class returnedInstance:installDataEditorMock];

    // Build a payload that exceeds 25 kB: 20 string-array attributes × 25 distinct strings × 295 chars ≈ 147 kB
    NSString *base = [@"" stringByPaddingToLength:295 withString:@"a" startingAtIndex:0];
    NSMutableArray<NSString *> *largeList = [NSMutableArray arrayWithCapacity:25];
    for (int j = 0; j < 25; j++) {
        [largeList addObject:[base stringByAppendingFormat:@"%05d", j]];
    }

    OCMReject([installDataEditorMock save]);

    [BatchProfile editWithBlock:^(BatchProfileEditor *_Nonnull editor) {
      for (int i = 0; i < 20; i++) {
          NSString *key = [NSString stringWithFormat:@"attr_%d", i];
          [editor setStringArrayAttribute:largeList forKey:key error:nil];
      }
    }];

    OCMVerifyAll(installDataEditorMock);
}

@end
