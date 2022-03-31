//
//  BANullHelper.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BANullHelper.h>

@implementation BANullHelper

+ (BOOL)isArrayEmpty:(id)object {
    return object == NULL || [object isKindOfClass:[NSArray class]] == NO || [object count] == 0;
}

+ (BOOL)isDataEmpty:(id)object {
    return object == NULL || [object isKindOfClass:[NSData class]] == NO || [object length] == 0;
}

+ (BOOL)isDictionaryEmpty:(id)object {
    return object == NULL || [object isKindOfClass:[NSDictionary class]] == NO || [object count] == 0;
}

+ (BOOL)isStringEmpty:(id)object {
    return object == NULL || [object isKindOfClass:[NSString class]] == NO || [object length] == 0;
}

+ (BOOL)isNumberEmpty:(id)object {
    if ([BANullHelper isNull:object]) {
        return YES;
    }

    if (![object isKindOfClass:[NSNumber class]] && ![object isKindOfClass:[NSString class]]) {
        return YES;
    }

    if ([object isKindOfClass:[NSString class]]) {
        if ([BANullHelper isStringEmpty:object]) {
            return YES;
        }
    }

    return NO;
}

+ (BOOL)isNull:(id)object {
    return object == NULL || [object isKindOfClass:[NSNull class]] == YES;
}

@end
