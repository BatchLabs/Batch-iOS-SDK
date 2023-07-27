//
//  BACSSSpecialToken.h
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BACSSSpecialTokenKind) {
    BACSSSpecialTokenKindUnknown = 0,
    BACSSSpecialTokenKindBlockStart = 1,        // {
    BACSSSpecialTokenKindBlockEnd = 2,          // }
    BACSSSpecialTokenKindPropertyEnd = 3,       // ;
    BACSSSpecialTokenKindPropertySeparator = 4, // :
    BACSSSpecialTokenKindNewline = 5            // \n
};

@interface BACSSSpecialToken : NSObject

+ (instancetype)specialTokenWithChar:(char)specialToken;

- (instancetype)initWithChar:(char)specialToken;

@property char value;

@property BACSSSpecialTokenKind kind;

@end
