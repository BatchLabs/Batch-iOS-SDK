//
//  BATHtmlParser.h
//  TestHTML
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString *, NSString *> BATTextTransformAttributes;
typedef NSMutableDictionary<NSString *, NSString *> BATMutableTextTransformAttributes;

typedef NS_OPTIONS(NSUInteger, BATTextModifiers) {
    BATTextModifierNone = 0,
    BATTextModifierBold = 1 << 0,
    BATTextModifierItalic = 1 << 1,
    BATTextModifierUnderline = 1 << 2,
    BATTextModifierStrikethrough = 1 << 3,
    BATTextModifierSpan = 1 << 4,
    BATTextModifierBiggerFont = 1 << 5,
    BATTextModifierSmallerFont = 1 << 6
};

@interface BATTextTransform : NSObject

- (instancetype)initWithLocation:(NSUInteger)location
                       modifiers:(BATTextModifiers)modifiers
                      attributes:(BATTextTransformAttributes *)attributes;

- (void)setEndLocation:(NSUInteger)endLocation;

@property NSRange range;

@property BATTextModifiers modifiers;

@property (nullable) BATTextTransformAttributes *attributes;

@end

@interface BATHtmlParser : NSObject <NSXMLParserDelegate>

/**
 Unstyled text
 */
@property (readonly) NSString *text;

/**
 Transformation list
 */
@property (readonly) NSArray<BATTextTransform *> *transforms;

- (instancetype)initWithString:(NSString *)string;

- (nullable NSError *)parse;

@end

NS_ASSUME_NONNULL_END
