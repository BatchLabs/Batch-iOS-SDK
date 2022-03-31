//
//  htmlParserTests.m
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BACoreCenter.h"
#import "BATHtmlParser.h"
#import "BatchCore.h"

@interface htmlParserTests : XCTestCase

@end

@implementation htmlParserTests

- (void)testParsingValidString {
    NSString *string = @"01234567890<u>fsdkj</u>dsqsdljk";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 1);
    XCTAssertTrue([parser.text isEqualToString:@"01234567890fsdkjdsqsdljk"]);
}

- (void)testParsingInvalidString {
    NSString *string = @"01234567890<u>fsdkjdsqsd</k>ljk";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNotNil(error);
    XCTAssertEqual(parser.transforms.count, 0);
}

- (void)testParsingEmptyString {
    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:@""];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 0);
}

- (void)testParsingNoFormatString {
    NSString *string = @"01234567890 sdq,f: ,sdqlkmjfkfsdkjdsqsdljk";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 0);
}

- (void)testParsingUnknownTagString {
    NSString *string = @"01234567890 s<khl>dq,f: ,sdqlkmjfkfsdk</khl>jdsqsdljk";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 0);
}

- (void)testParsingNbsp {
    NSString *string = @"  &nbsp;&nbsp;   &nbsp;";

    unichar nbsp = 0x00a0;
    NSString *nbspString = [NSString stringWithCharacters:&nbsp length:1];

    NSString *expectedResult = [NSString stringWithFormat:@" %@%@ %@", nbspString, nbspString, nbspString];
    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 0);
    XCTAssertEqualObjects(parser.text, expectedResult);
}

- (void)testParsingNestedTagsString {
    NSString *string = @"<u>R<i>Vera</i></u>";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 2);

    XCTAssertEqual([[parser.transforms firstObject] range].location, 1);
    XCTAssertEqual([[parser.transforms firstObject] range].length, 4);
    XCTAssertEqual([[parser.transforms lastObject] range].location, 0);
    XCTAssertEqual([[parser.transforms lastObject] range].length, 5);
}

- (void)testStyles {
    NSString *string = @"<span style=\"color:#AABBCC\">aa</span><span "
                       @"style=\"background-color:#DDEEFF\">aa</span><big>aa</big><small>aa</small><b>aa</b><i>aa</"
                       @"i><u>aa</u><s>aa</s>";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 8);

    XCTAssertEqual(parser.transforms[0].modifiers, BATTextModifierSpan);
    XCTAssertEqualObjects(parser.transforms[0].attributes[@"color"], @"#AABBCC");
    XCTAssertEqual(parser.transforms[1].modifiers, BATTextModifierSpan);
    XCTAssertEqualObjects(parser.transforms[1].attributes[@"background-color"], @"#DDEEFF");
    XCTAssertEqual(parser.transforms[2].modifiers, BATTextModifierBiggerFont);
    XCTAssertEqual(parser.transforms[3].modifiers, BATTextModifierSmallerFont);
    XCTAssertEqual(parser.transforms[4].modifiers, BATTextModifierBold);
    XCTAssertEqual(parser.transforms[5].modifiers, BATTextModifierItalic);
    XCTAssertEqual(parser.transforms[6].modifiers, BATTextModifierUnderline);
    XCTAssertEqual(parser.transforms[7].modifiers, BATTextModifierStrikethrough);
}

- (void)testStripping {
    NSString *string = @"\n\n<b>A\nb c  d  \n e\n fg</b>";

    BATHtmlParser *parser = [[BATHtmlParser alloc] initWithString:string];
    NSError *error = [parser parse];

    XCTAssertNil(error);
    XCTAssertEqual(parser.transforms.count, 1);
    XCTAssertEqualObjects(parser.text, @" A b c d e fg");
}

@end
