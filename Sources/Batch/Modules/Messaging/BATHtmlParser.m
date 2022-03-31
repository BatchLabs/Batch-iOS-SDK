//
//  BATHtmlParser.m
//  TestHTML
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Batch/BATHtmlParser.h>

@implementation BATTextTransform

- (instancetype)initWithLocation:(NSUInteger)location
                       modifiers:(BATTextModifiers)modifiers
                      attributes:(BATTextTransformAttributes *)attributes {
    self = [super init];
    if (self) {
        _range = NSMakeRange(location, 0);
        _modifiers = modifiers;
        _attributes = [attributes copy];
    }
    return self;
}

- (void)setEndLocation:(NSUInteger)endLocation {
    _range = NSMakeRange(_range.location, endLocation - _range.location);
}

- (NSString *)description {
    NSMutableString *desc = [NSMutableString new];
    [desc appendString:@"BATTextTransform: Range "];
    [desc appendString:NSStringFromRange(_range)];
    [desc appendString:@" - Modifiers: "];

    if (_modifiers == BATTextModifierNone) {
        [desc appendString:@"None"];
    } else {
        if (_modifiers & BATTextModifierBold) {
            [desc appendString:@"Bold "];
        }
        if (_modifiers & BATTextModifierItalic) {
            [desc appendString:@"Italic "];
        }
        if (_modifiers & BATTextModifierUnderline) {
            [desc appendString:@"Underline "];
        }
        if (_modifiers & BATTextModifierStrikethrough) {
            [desc appendString:@"Strikethrough "];
        }
        if (_modifiers & BATTextModifierSpan) {
            NSString *color = _attributes[@"color"];
            NSString *backgroundColor = _attributes[@"background-color"];
            [desc appendFormat:@"Span "];
            if (color) {
                [desc appendFormat:@"Color %@ ", color];
            }
            if (backgroundColor) {
                [desc appendFormat:@"Background-Color %@ ", backgroundColor];
            }
        }
        if (_modifiers & BATTextModifierBiggerFont) {
            [desc appendString:@"Big "];
        }
        if (_modifiers & BATTextModifierSmallerFont) {
            [desc appendString:@"Small "];
        }
    }

    return desc;
}

@end

@implementation BATHtmlParser {
    NSData *_htmlData;
    NSMutableString *_taglessString;
    NSMutableArray<BATTextTransform *> *_transforms;
    NSMutableArray<BATTextTransform *> *_pendingTransforms;
}

- (instancetype)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        // We wrap the input string in tags if needed, so that we can parse it as valid XML
        NSString *inputString = [NSString stringWithFormat:@"<html>%@</html>", [self replaceHtmlEntities:string]];
        _htmlData = [inputString dataUsingEncoding:NSUTF8StringEncoding];
        _taglessString = [[NSMutableString alloc] initWithCapacity:inputString.length];
        _pendingTransforms = [NSMutableArray new];
        _transforms = [NSMutableArray new];
    }
    return self;
}

- (NSString *)text {
    return [_taglessString copy];
}

- (NSArray<BATTextTransform *> *)transforms {
    return [_transforms copy];
}

- (NSError *)parse {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_htmlData];
    parser.delegate = self;
    if ([parser parse]) {
        return nil;
    } else {
        return parser.parserError;
    }
    // NSLog(@"finished");
}

- (NSString *)replaceHtmlEntities:(NSString *)origString {
    unichar nbsp = 0x00a0;
    NSString *nbspString = [NSString stringWithCharacters:&nbsp length:1];
    NSMutableString *workString = [NSMutableString stringWithString:origString];

    [workString replaceOccurrencesOfString:@"&nbsp;"
                                withString:nbspString
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0, [workString length])];

    return workString;
}

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary<NSString *, NSString *> *)xmlAttributes {
    // NSLog(@"< %@", elementName);
    //  Opening a new tag created a new transform that inherits all past modifiers
    //  Don't skip unknown modifiers so we can close them correctly, except br and html
    if ([@"html" isEqualToString:elementName] || [@"br" isEqualToString:elementName]) {
        return;
    }

    BATTextModifiers newModifier = [self modifierForTag:elementName];

    // Merge modifiers and attributes
    BATTextTransform *previousTransform = [_pendingTransforms lastObject];
    BATTextModifiers previousModifier = previousTransform.modifiers;

    BATTextTransformAttributes *mergedAttributes = [BATTextTransformAttributes new];

    if ([xmlAttributes count] > 0) {
        mergedAttributes = [self mergeXmlAttributes:xmlAttributes
                                       intoPrevious:previousTransform.attributes
                                        newModifier:newModifier];
    }

    [_pendingTransforms addObject:[[BATTextTransform alloc] initWithLocation:_taglessString.length
                                                                   modifiers:previousModifier | newModifier
                                                                  attributes:mergedAttributes]];

    // NSLog(@"- %@ %@ %@", _taglessString, _pendingTransforms, _transforms);
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName {
    // NSLog(@"/ %@ >", elementName);
    //  XML parser enforces that only the last opened tag can be closed, so we can "pop" it

    if ([@"br" isEqualToString:elementName]) {
        [_taglessString appendString:@"\n"];
        return;
    }

    BATTextTransform *pendingTransform = [_pendingTransforms lastObject];
    [_pendingTransforms removeLastObject];
    if (pendingTransform.modifiers != BATTextModifierNone) {
        [pendingTransform setEndLocation:_taglessString.length];
        [_transforms addObject:pendingTransform];
    }

    // NSLog(@"~ %@ %@ %@", _taglessString, _pendingTransforms, _transforms);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSUInteger len = [string length];
    unichar inputBuffer[len + 1];
    [string getCharacters:inputBuffer range:NSMakeRange(0, len)];

    unichar outputBuffer[len];
    NSUInteger outputPos = 0;
    unichar previousChar = '\0';
    unichar currentChar;
    for (int i = 0; i < len; i++) {
        currentChar = inputBuffer[i];
        // HTML replaces \n with spaces
        if (currentChar == '\n') {
            currentChar = ' ';
        }
        if (previousChar == ' ' && currentChar == ' ') {
            // HTML trims consecutive whitespaces
            continue;
        }
        if (outputPos < len) {
            outputBuffer[outputPos] = currentChar;
            outputPos++;
        }
        previousChar = currentChar;
    }
    [_taglessString appendString:[NSString stringWithCharacters:outputBuffer length:MIN(len, outputPos)]];
}

- (BATTextModifiers)modifierForTag:(NSString *)tag {
    if ([@"big" isEqualToString:tag]) {
        return BATTextModifierBiggerFont;
    } else if ([@"small" isEqualToString:tag]) {
        return BATTextModifierSmallerFont;
    } else if ([@"span" isEqualToString:tag]) {
        return BATTextModifierSpan;
    } else {
        switch ([tag characterAtIndex:0]) {
            case 'b':
                return BATTextModifierBold;
            case 'i':
                return BATTextModifierItalic;
            case 'u':
                return BATTextModifierUnderline;
            case 's':
                return BATTextModifierStrikethrough;
            default:
                return BATTextModifierNone;
        }
    }
}

- (NSDictionary *)mergeXmlAttributes:(NSDictionary<NSString *, NSString *> *)xmlAttributes
                        intoPrevious:(NSDictionary *)previous
                         newModifier:(BATTextModifiers)newModifier {
    if (xmlAttributes == nil) {
        return previous;
    }

    NSMutableDictionary *outDict = previous != nil ? [previous mutableCopy] : [NSMutableDictionary new];

    // Whitelist keys and transform them
    if (newModifier == BATTextModifierSpan) {
        NSString *xmlStyle = xmlAttributes[@"style"];
        if ([xmlStyle hasPrefix:@"background-color:"]) {
            NSString *color = [xmlStyle substringFromIndex:17];
            if ([color length] > 0) {
                outDict[@"background-color"] = color;
            }
        } else if ([xmlStyle hasPrefix:@"color:"]) {
            NSString *color = [xmlStyle substringFromIndex:6];
            if ([color length] > 0) {
                outDict[@"color"] = color;
            }
        }
    }

    return outDict;
}

@end
