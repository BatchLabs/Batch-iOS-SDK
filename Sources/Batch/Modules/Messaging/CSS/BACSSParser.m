//
//  BACSSParser.m
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSSParser.h>
#import <Batch/BACSSToken.h>
#import <Batch/BACSS.h>

#define DEBUG_CSS 0

#define CSS_COMMENT_REGEXP @"\\/\\*.*?\\*\\/"
#define CSS_IMPORT_REGEXP @"@import sdk\\(\"([^\"]*)\"\\);"
#define BACSS_PARSER_ERROR_DOMAIN @"BACSSParsingErrorDomain"

typedef NS_ENUM(NSUInteger, BACSSParserState) {
    BACSSParserStateRoot, // Document root
    BACSSParserStateMediaQuery, // Media query
};

typedef NS_ENUM(NSUInteger, BACSSParserSubstate) {
    BACSSParserSubstateSelector, // We're parsing a selector
    BACSSParserSubstateRuleset, // We're parsing a ruleset block (in the {})
    BACSSParserSubstatePropertyName, // We're parsing a property name "background-color"
    BACSSParserSubstatePropertyValue // We're parsing a property value "white"
};

@interface BACSSParser()
{
    id<BACSSImportProvider> importProvider;
    
    BACSSParserState state;
    BACSSParserSubstate substate;
    
    BACSSMediaQuery *currentMediaQuery;
    BACSSRuleset *currentRuleset;
    BACSSDeclaration *currentDeclaration;
    
    BACSSDocument *currentDocument;
    
    NSString *currentToken;
    
    NSRegularExpression *commentRegexp;
    
    bool shouldMergePreviousToken;
}

/**
 * The stylesheet we're trying to parse
 */
@property NSString *rawStylesheet;

@end

@implementation BACSSParser

+ (instancetype)parserWithString:(NSString*)cssString andImportProvider:(id<BACSSImportProvider>)importProvider
{
    return [[BACSSParser alloc] initWithString:cssString andImportProvider:importProvider];
}

- (instancetype)initWithString:(NSString*)cssString andImportProvider:(id<BACSSImportProvider>)importProviderImpl
{
    self = [super init];
    if (self)
    {
        importProvider = importProviderImpl;
        self.rawStylesheet = cssString;
        [self replaceImports];
        
        NSError *error;
        commentRegexp = [NSRegularExpression regularExpressionWithPattern:CSS_COMMENT_REGEXP
                                                                  options:NSRegularExpressionDotMatchesLineSeparators
                                                                    error:&error];
        
        if (error)
        {
            return nil;
        }
    }
    return self;
}

- (void)replaceImports
{
    NSError *error;
    NSRegularExpression *importRegexp = [NSRegularExpression regularExpressionWithPattern:CSS_IMPORT_REGEXP
                                                                                  options:NSRegularExpressionDotMatchesLineSeparators
                                                                                    error:&error];
    if (error || importRegexp == nil)
    {
        [BALogger debugForDomain:BACSS_PARSER_ERROR_DOMAIN message:@"Error while creating import regexp pattern, %@", [error localizedDescription]];
        return;
    }
    
    NSMutableString* mutableString = [self.rawStylesheet mutableCopy];
    
    NSArray<NSTextCheckingResult*>* matches = [importRegexp matchesInString:mutableString
                                                                    options:0
                                                                      range:NSMakeRange(0, [mutableString length])];
    
    // Reverse the result list so that replacing the string elements doesn't break the other ranges
    // This only works if we assume that results are sorted correctly
    for (NSTextCheckingResult* result in [matches reverseObjectEnumerator])
    {
        NSString *importName = [mutableString substringWithRange:[result rangeAtIndex:1]];
        NSString *importContent = [importProvider contentForImportNamed:importName];
        if (importContent == nil)
        {
            importContent = @"";
        }
        [mutableString replaceCharactersInRange:[result rangeAtIndex:0] withString:importContent];
    }
    
    self.rawStylesheet = [mutableString copy];
}

- (BACSSDocument*)parseWithError:(NSError**)error
{
    [self reset];
    
    NSError *err = nil;
    
    @try
    {
        err = [self scan];
    }
    @catch (NSException *exception)
    {
        err = [NSError errorWithDomain:BACSS_PARSER_ERROR_DOMAIN
                                  code:-3
                              userInfo:@{NSLocalizedDescriptionKey: @"Internal state error. Check the validity of your file.",
                                         NSLocalizedFailureReasonErrorKey: exception.reason != nil ? exception.reason : @""}];
    }
    
    if (err)
    {
        if (error != nil)
        {
            *error = err;
        }
        
        return nil;
    }
    
    BACSSDocument *retVal = currentDocument;
    [self reset];
    return retVal;
}

#pragma mark Private methods

- (void)reset
{
    state = BACSSParserStateRoot;
    substate = BACSSParserSubstateSelector;
    currentDocument = [BACSSDocument new];
    currentRuleset = nil;
    currentMediaQuery = nil;
    currentToken = nil;
    currentDeclaration = nil;
    shouldMergePreviousToken = NO;
}

- (NSError*)scan
{
    NSString *commentlessStylesheet = [commentRegexp stringByReplacingMatchesInString:_rawStylesheet
                                                                              options:0
                                                                                range:NSMakeRange(0, [_rawStylesheet length]) withTemplate:@""];
    NSScanner *scanner = [NSScanner scannerWithString:commentlessStylesheet];
    scanner.charactersToBeSkipped = nil;
    
    NSMutableCharacterSet *speicalTokensSet = [NSMutableCharacterSet newlineCharacterSet];
    [speicalTokensSet addCharactersInString:@":;{}\n"];
    
    NSString *token = @"";
    NSString *specialTokenString = @"";
    
    NSError *err;
    
    while(![scanner isAtEnd])
    {
        [scanner scanUpToCharactersFromSet:speicalTokensSet intoString:&token];
        [self consumeToken:[token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        
        
        if (![scanner scanCharactersFromSet:speicalTokensSet intoString:&specialTokenString])
        {
            return [NSError errorWithDomain:BACSS_PARSER_ERROR_DOMAIN
                                       code:-1
                                   userInfo:@{NSLocalizedDescriptionKey: @"Internal error. Check the validity of your file."}];
        }
        
        for (int i = 0; i < [specialTokenString length]; i++)
        {
            err = [self consumeSpecialToken:[specialTokenString characterAtIndex:i]];
            if (err)
            {
                return err;
            }
        }
    }
    
    return nil;
}

- (void)consumeToken:(NSString*)token
{
#if DEBUG_CSS
    NSLog(@"|%@|", token);
#endif
    
    if (shouldMergePreviousToken)
    {
        currentToken = [currentToken stringByAppendingString:token];
    }
    else
    {
        currentToken = token;
    }
    shouldMergePreviousToken = NO;
}

- (NSError*)consumeSpecialToken:(char)c
{
#if DEBUG_CSS
    NSLog(@"Special: %c", c);
#endif
    
    BACSSSpecialToken *specialToken = [BACSSSpecialToken specialTokenWithChar:c];
    
    switch (specialToken.kind)
    {
        case BACSSSpecialTokenKindUnknown:
            break;
        case BACSSSpecialTokenKindBlockStart:
            #if DEBUG_CSS
            NSLog(@"Block start { switchToRulesetState");
            #endif
            return [self switchToRulesetState];
        case BACSSSpecialTokenKindBlockEnd:
            #if DEBUG_CSS
            NSLog(@"Block end } switchOutOfRulesetState");
            #endif
            return [self switchOutOfRulesetState];
        case BACSSSpecialTokenKindPropertySeparator:
            #if DEBUG_CSS
            NSLog(@"Property separator : switchOutOfPropertyNameState");
            #endif
            return [self switchOutOfPropertyNameState];
        case BACSSSpecialTokenKindPropertyEnd:
            #if DEBUG_CSS
            NSLog(@"Property end ; switchOutOfPropertyValueState");
            #endif
            return [self switchOutOfPropertyValueState];
        case BACSSSpecialTokenKindNewline:
            #if DEBUG_CSS
            NSLog(@"New line ; recoverLineEndingIfPossible");
            #endif
            return [self recoverLineEndingIfPossible];
    }
    
    return nil;
}

- (NSError*)switchToRulesetState
{
    if (substate != BACSSParserSubstateSelector ||
        currentRuleset ||
        [currentToken length] == 0)
    {
        return [self genericError];
    }
    
    if ([currentToken hasPrefix:@"@"])
    {
        // It's a media query!
        
        // No nested media queries
        if (state != BACSSParserStateRoot)
        {
            return [self genericError];
        }
        
        state = BACSSParserStateMediaQuery;
        
        if (currentMediaQuery)
        {
            // We shouldn't even be here
            return [self genericError];
        }
        
        currentMediaQuery = [BACSSMediaQuery new];
        currentMediaQuery.rule = currentToken;
    }
    else
    {
        currentRuleset = [BACSSRuleset new];
        currentRuleset.selector = currentToken; // TODO parse this later
        
        substate = BACSSParserSubstatePropertyName;
    }
    
    return nil;
}

- (NSError*)switchOutOfRulesetState
{
    if (substate == BACSSParserSubstatePropertyValue)
    {
        // Kindly add a ";" if we detect a } while reading a property
        NSError *err = [self switchOutOfPropertyValueState];
        if (err)
        {
            return err;
        }
    }
    
    if (substate != BACSSParserSubstatePropertyName &&
        (state == BACSSParserStateMediaQuery && substate != BACSSParserSubstateSelector))
    {
        return [self genericError];
    }
    
    if (state == BACSSParserStateMediaQuery)
    {
        if (currentRuleset)
        {
            [currentMediaQuery.rulesets addObject:currentRuleset];
            currentRuleset = nil;
        }
        else
        {
            [currentDocument.mediaQueries addObject:currentMediaQuery];
            currentMediaQuery = nil;
            state = BACSSParserStateRoot;
        }
    }
    else if (currentRuleset)
    {
        [currentDocument.rulesets addObject:currentRuleset];
        currentRuleset = nil;
    }
    else
    {
        return [self genericError];
    }
    
    substate = BACSSParserSubstateSelector;
    
    return nil;
}

- (NSError*)switchOutOfPropertyNameState
{
    if (state == BACSSParserStateRoot && substate == BACSSParserSubstateSelector)
    {
        // We're encountering a ":" in a selector, which is entirely legal for media queries.
        // Override the state, add back the ":" and tell the token consumer to keep the old value
        currentToken = [currentToken stringByAppendingString:@":"];
        shouldMergePreviousToken = YES;
        return nil;
    }
    
    if (substate != BACSSParserSubstatePropertyName ||
        !currentRuleset ||
        currentDeclaration ||
        [currentToken length] == 0)
    {
        return [self genericError];
    }
    
    if ([currentToken hasPrefix:@"--"])
    {
        // It's a variable!
        currentDeclaration = [BACSSVariable new];
    }
    else
    {
        currentDeclaration = [BACSSDeclaration new];
    }
    
    currentDeclaration.name = [currentToken lowercaseString];
    
    substate = BACSSParserSubstatePropertyValue;
    
    return nil;
}

- (NSError*)switchOutOfPropertyValueState
{
    if (substate != BACSSParserSubstatePropertyValue ||
        [currentToken length] == 0 ||
        !currentDeclaration ||
        !currentRuleset)
    {
        return [self genericError];
    }
    
    currentDeclaration.value = [currentToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [currentRuleset.declarations addObject:currentDeclaration];
    currentDeclaration = nil;
    
    substate = BACSSParserSubstatePropertyName;
    
    return nil;
}

- (NSError*)recoverLineEndingIfPossible
{
    if (substate == BACSSParserSubstatePropertyValue)
    {
        return [self switchOutOfPropertyValueState];
    }
    
    return nil;
}

- (NSError*)genericError
{
    return [NSError errorWithDomain:BACSS_PARSER_ERROR_DOMAIN
                               code:-2
                           userInfo:@{NSLocalizedDescriptionKey: @"Internal state error. Check the validity of your file."}];
}

@end
