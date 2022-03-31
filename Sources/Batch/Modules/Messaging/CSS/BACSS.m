//
//  BACSS.m
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSS.h>
#import <Batch/BALogger.h>

#define SCREEN_MEDIA_QUERY_REGEXP @"@media (ios|android|\\*) and \\((max|min)-(width|height):\\s*(\\d*)\\)"

@implementation BACSSDOMNode

- (instancetype)init {
    self = [super init];
    if (self) {
        self.classes = [NSArray new];
    }
    return self;
}

- (BOOL)matchesSelector:(NSString *)selector {
    NSArray *selectors = [selector componentsSeparatedByString:@","];
    for (__strong NSString *selector in selectors) {
        selector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([selector length] < 2) {
            continue;
        }

        NSString *selectorValue = [[selector substringFromIndex:1] lowercaseString];
        if ([selector characterAtIndex:0] == '#') {
            if ([selectorValue isEqualToString:[self.identifier lowercaseString]]) {
                return true;
            }
        } else if ([selector characterAtIndex:0] == '.') {
            if (!self.classes) {
                continue;
            }

            for (NSString *class in self.classes) {
                if ([[class lowercaseString] isEqualToString:selectorValue]) {
                    return true;
                }
            }
        }
    }

    return false;
}

@end

@implementation BACSSMediaQuery

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rulesets = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CSS Media Query: %@ { %@ }", self.rule, self.rulesets];
}

/*- (NSString*)debugDescription
{
    return [NSString stringWithFormat:@"%lu elements. Rule: %@", (unsigned long)[self.rulesets count], self.rule];
}*/

@end

@implementation BACSSDeclaration

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@", self.name, self.value];
}

/*- (NSString*)debugDescription
{
    return [self description];
}*/

@end

@implementation BACSSVariable

- (NSString *)description {
    return [NSString stringWithFormat:@"Var %@ = %@", self.name, self.value];
}

@end

@implementation BACSSRuleset

- (instancetype)init {
    self = [super init];
    if (self) {
        self.declarations = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Ruleset: %@ { %@ }", self.selector, self.declarations];
}

- (NSString *)debugDescription {
    return [[NSString stringWithFormat:@"Ruleset: %@ { %@ }", self.selector, self.declarations]
        stringByReplacingOccurrencesOfString:@"\\n"
                                  withString:@"\r"];
}

@end

@implementation BACSSDocument

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rulesets = [NSMutableArray new];
        self.mediaQueries = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString
        stringWithFormat:@"CSSDocument: Media queries:\r%@\r\rRulesets:\r%@", self.mediaQueries, self.rulesets];
}

- (NSString *)debugDescription {
    return [[NSString stringWithFormat:@"CSSDocument: Media queries:\r%@\r\rRulesets:\r%@", self.mediaQueries,
                                       self.rulesets] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\r"];
}

- (BACSSRules *)flatRulesForNode:(BACSSDOMNode *)node withEnvironment:(BACSSEnvironment *)environment {
    return [self flatRulesFromCSSDeclarations:[self rulesForNode:node withEnvironment:environment]];
}

- (NSArray<BACSSDeclaration *> *)rulesForNode:(BACSSDOMNode *)node withEnvironment:(BACSSEnvironment *)environment {
    NSMutableArray<BACSSDeclaration *> *declarations = [NSMutableArray new];

    [declarations addObjectsFromArray:[self rulesForNode:node inRuleSets:self.rulesets]];

    for (BACSSMediaQuery *query in self.mediaQueries) {
        NSString *rule = [[query rule] lowercaseString];
        if ([environment environmentMatchesQuery:rule]) {
            [declarations addObjectsFromArray:[self rulesForNode:node inRuleSets:[query rulesets]]];
        }
    }

    return declarations;
}

- (NSArray<BACSSDeclaration *> *)rulesForNode:(BACSSDOMNode *)node inRuleSets:(NSArray<BACSSRuleset *> *)rulesets {
    NSMutableArray<BACSSDeclaration *> *declarations = [NSMutableArray new];

    for (BACSSRuleset *ruleset in rulesets) {
        // Only extract the variables from *
        // Everybody will get them though
        // Basically it means that the * block is merged with
        // every other in the scope (where the scope is whether we're in a media query or not)
        if ([ruleset.selector isEqualToString:@"*"]) {
            for (BACSSDeclaration *declaration in ruleset.declarations) {
                if ([declaration isKindOfClass:[BACSSVariable class]]) {
                    [declarations addObject:declaration];
                }
            }
            continue;
        }

        if (![node matchesSelector:ruleset.selector]) {
            continue;
        }

        [declarations addObjectsFromArray:ruleset.declarations];
    }

    return declarations;
}

- (BACSSRules *)flatRulesFromCSSDeclarations:(NSArray<BACSSDeclaration *> *)declarations {
    NSMutableDictionary<NSString *, NSString *> *rules = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSString *> *variables = [NSMutableDictionary new];

    // Split the rules and declarations, overriding will happen automatically based on the order

    for (BACSSDeclaration *declaration in declarations) {
        if ([declaration isKindOfClass:[BACSSVariable class]]) {
            if ([declaration.name length] > 2) {
                variables[declaration.name] = declaration.value;
            }
        } else {
            rules[declaration.name] = declaration.value;
        }
    }

    // Merge the variables

    for (NSString *ruleKey in [rules allKeys]) {
        NSString *ruleValue = rules[ruleKey];
        if ([ruleValue hasPrefix:@"var("]) {
            NSString *varName = [ruleValue substringWithRange:NSMakeRange(4, [ruleValue length] - 5)];
            NSString *varValue = [variables objectForKey:[varName lowercaseString]];

            if (!varValue) {
                [rules removeObjectForKey:ruleKey];
            } else {
                rules[ruleKey] = varValue;
            }
        }
    }

    // Split "margin" and "padding"

    NSString *padding = rules[@"padding"];
    if (padding) {
        NSArray<NSString *> *paddingValues = [padding componentsSeparatedByString:@" "];

        if ([paddingValues count] == 1) {
            paddingValues = @[ paddingValues[0], paddingValues[0], paddingValues[0], paddingValues[0] ];
        }

        if ([paddingValues count] == 4) {
            // Explicit rules win
            if (!rules[@"padding-top"]) {
                rules[@"padding-top"] = paddingValues[0];
            }
            if (!rules[@"padding-right"]) {
                rules[@"padding-right"] = paddingValues[1];
            }
            if (!rules[@"padding-bottom"]) {
                rules[@"padding-bottom"] = paddingValues[2];
            }
            if (!rules[@"padding-left"]) {
                rules[@"padding-left"] = paddingValues[3];
            }
        }

        [rules removeObjectForKey:@"padding"];
    }

    NSString *margin = rules[@"margin"];
    if (margin) {
        NSArray<NSString *> *marginValues = [margin componentsSeparatedByString:@" "];

        if ([marginValues count] == 1) {
            marginValues = @[ marginValues[0], marginValues[0], marginValues[0], marginValues[0] ];
        }

        if ([marginValues count] == 4) {
            // Explicit rules win
            if (!rules[@"margin-top"]) {
                rules[@"margin-top"] = marginValues[0];
            }
            if (!rules[@"margin-right"]) {
                rules[@"margin-right"] = marginValues[1];
            }
            if (!rules[@"margin-bottom"]) {
                rules[@"margin-bottom"] = marginValues[2];
            }
            if (!rules[@"margin-left"]) {
                rules[@"margin-left"] = marginValues[3];
            }
        }

        [rules removeObjectForKey:@"margin"];
    }

    return rules;
}

@end

@implementation BACSSEnvironment : NSObject

+ (NSRegularExpression *)screenMediaQueryMatcher {
    static NSRegularExpression *screenMediaQueryRegexp = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSError *err = nil;
      screenMediaQueryRegexp = [NSRegularExpression regularExpressionWithPattern:SCREEN_MEDIA_QUERY_REGEXP
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&err];

      if (err) {
          [BALogger
              debugForDomain:@"BACSS"
                     message:@"Error while creating SCREEN_MEDIA_QUERY_REGEXP, @media queries will not work. Error: %@",
                             [err localizedDescription]];
      }
    });

    return screenMediaQueryRegexp;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewSize = CGSizeZero;
        _darkMode = false;
    }
    return self;
}

- (BOOL)environmentMatchesQuery:(NSString *)query {
    // Fast paths:
    //  - @ios
    //  - @dark
    //  - @white
    // Anything else is probably a size media query

    if ([query isEqualToString:@"@ios"]) {
        return true;
    }

    if ([query isEqualToString:@"@dark"] || [query isEqualToString:@"@ios and dark"]) {
        return self.darkMode;
    }

    if ([query isEqualToString:@"@light"] || [query isEqualToString:@"@ios and light"]) {
        return !self.darkMode;
    }

    if (!CGSizeEqualToSize(_viewSize, CGSizeZero)) {
        NSRegularExpression *screenRegexp = [BACSSEnvironment screenMediaQueryMatcher];
        if (screenRegexp) {
            NSTextCheckingResult *result = [screenRegexp firstMatchInString:query
                                                                    options:0
                                                                      range:NSMakeRange(0, [query length])];
            if (result.numberOfRanges == 5) {
                NSString *platform = [query substringWithRange:[result rangeAtIndex:1]];   // ios|android|*
                NSString *minMax = [query substringWithRange:[result rangeAtIndex:2]];     // min|max
                NSString *dimension = [query substringWithRange:[result rangeAtIndex:3]];  // width|height
                NSString *sizeString = [query substringWithRange:[result rangeAtIndex:4]]; // 300

                return [self environmentMatchesRequiredSize:sizeString
                                                   platform:platform
                                                     minMax:minMax
                                                  dimension:dimension];
            }
        }
    }

    return false;
}

- (BOOL)environmentMatchesRequiredSize:(NSString *)sizeString
                              platform:(NSString *)platform
                                minMax:(NSString *)minMax
                             dimension:(NSString *)dimension {
    if (![@"ios" isEqualToString:platform]) {
        return NO;
    }

    float size = [sizeString intValue]; // Android does not support float dimensions, so parse as int on purpose

    CGFloat comparedSize;

    if ([@"height" isEqualToString:dimension]) {
        comparedSize = _viewSize.height;
    } else {
        comparedSize = _viewSize.width;
    }

    // max-(width|height) is <
    // min-(width|height) is >=
    if ([@"max" isEqualToString:minMax]) {
        return comparedSize <= size;
    } else {
        return comparedSize >= size;
    }
}

@end
