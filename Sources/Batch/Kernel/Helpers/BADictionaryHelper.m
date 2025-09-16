//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BADictionaryHelper.h>
#import <Foundation/Foundation.h>

@implementation BADictionaryHelper

+ (BOOL)dictionary:(NSDictionary *)actual containsValuesFromDictionary:(NSDictionary *)expected {
    if (expected == nil) {
        return actual == nil;
    }

    if (actual == expected) {
        return YES;
    }

    if (actual == nil) {
        return NO;
    }

    for (NSString *key in expected.allKeys) {
        if (!actual[key]) {
            return NO;
        }

        id expectedValue = expected[key];
        id actualValue = actual[key];

        if ([expectedValue isKindOfClass:[NSDictionary class]] && [actualValue isKindOfClass:[NSDictionary class]]) {
            if (![self dictionary:actualValue containsValuesFromDictionary:expectedValue]) {
                return NO;
            }
        } else if ([expectedValue isKindOfClass:[NSArray class]] && [actualValue isKindOfClass:[NSArray class]]) {
            if (![self array:actualValue containsValuesFromArray:expectedValue]) {
                return NO;
            }
        } else if (![expectedValue isEqual:actualValue]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)array:(NSArray *)actual containsValuesFromArray:(NSArray *)expected {
    if (expected == nil) {
        return actual == nil;
    }

    if (actual == nil) {
        return NO;
    }

    if (expected.count > actual.count) {
        return NO;
    }

    NSMutableArray *actualList = [actual mutableCopy];

    for (id expectedValue in expected) {
        BOOL found = NO;
        for (int j = 0; j < actualList.count; j++) {
            id actualValue = actualList[j];
            if ([expectedValue isKindOfClass:[NSDictionary class]] &&
                [actualValue isKindOfClass:[NSDictionary class]]) {
                if ([self dictionary:actualValue containsValuesFromDictionary:expectedValue]) {
                    [actualList removeObjectAtIndex:j];
                    found = YES;
                    break;
                }
            } else if ([expectedValue isKindOfClass:[NSArray class]] && [actualValue isKindOfClass:[NSArray class]]) {
                if ([self array:actualValue containsValuesFromArray:expectedValue]) {
                    [actualList removeObjectAtIndex:j];
                    found = YES;
                    break;
                }
            } else if ([expectedValue isEqual:actualValue]) {
                [actualList removeObjectAtIndex:j];
                found = YES;
                break;
            }
        }
        if (!found) {
            return NO;
        }
    }
    return YES;
}

@end
