//
//  BACSSSpecialToken.m
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSSToken.h>

static const char kBACSSTokenChar_rulesetStart = '{';
static const char kBACSSTokenChar_rulesetEnd = '}';
static const char kBACSSTokenChar_propertySeparator = ':';
static const char kBACSSTokenChar_propertyEnd = ';';
static const char kBACSSTokenChar_newLine = '\n';

/*static const NSString *kBACSSTokenChar_selectorId = '#';
static const NSString *kBACSSTokenChar_selectorClass = '.';*/

@implementation BACSSSpecialToken

+ (instancetype)specialTokenWithChar:(char)specialToken {
    return [[BACSSSpecialToken alloc] initWithChar:specialToken];
}

- (instancetype)initWithChar:(char)specialToken {
    self = [super init];
    if (self) {
        self.value = specialToken;

        switch (specialToken) {
            case kBACSSTokenChar_rulesetStart:
                self.kind = BACSSSpecialTokenKindBlockStart;
                break;

            case kBACSSTokenChar_rulesetEnd:
                self.kind = BACSSSpecialTokenKindBlockEnd;
                break;

            case kBACSSTokenChar_propertyEnd:
                self.kind = BACSSSpecialTokenKindPropertyEnd;
                break;

            case kBACSSTokenChar_propertySeparator:
                self.kind = BACSSSpecialTokenKindPropertySeparator;
                break;

            case kBACSSTokenChar_newLine:
                self.kind = BACSSSpecialTokenKindNewline;
                break;

            default:
                self.kind = BACSSSpecialTokenKindUnknown;
                break;
        }
    }
    return self;
}

@end
