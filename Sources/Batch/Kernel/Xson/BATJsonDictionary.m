//
//  BATJsonDictionary.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import "BATJsonDictionary.h"

@interface BATJsonDictionary ()
{
    NSDictionary *_backingDictionary;
    NSErrorDomain _errorDomain;
}

@end

@implementation BATJsonDictionary

- (instancetype)initWithDictionary:(NSDictionary*)dict errorDomain:(NSErrorDomain)errorDomain;
{
    self = [super init];
    if (self) {
        _backingDictionary = [dict copy];
        _errorDomain = [errorDomain copy];
    }
    return self;
}

- (id)objectForKey:(NSString*)key kindOfClass:(Class)class allowNil:(BOOL)allowNil error:(NSError**)error {
    id value = [_backingDictionary objectForKey:key];
    
    if (value == [NSNull null]) {
        value = nil;
    }
    
    if (![value isKindOfClass:class]) {
        if (value == nil) {
            return nil;
        }
        
        if (error) {
            *error = [self genericErrorForKey:key value:value expectedClass:class nilAllowed:allowNil];
        }
        return nil;
    }
    
    return value;
}

- (id)objectForKey:(NSString*)key kindOfClass:(Class)class fallback:(id)fallback {
    id result = [self objectForKey:key kindOfClass:class allowNil:YES error:NULL];
    return result != nil ? result : fallback;
}

- (NSError*)genericErrorForKey:(NSString*)key value:(id)value expectedClass:(Class)expectedClass nilAllowed:(BOOL)nilAllowed {
    NSString *nilErrorMessage = nilAllowed ? @" or nil" : @"";
    NSString *localizedError = [NSString stringWithFormat:@"%@'%@' should be an instance of %@%@, but was '%@'",
                                self.errorDescriptionPrefix != nil ? self.errorDescriptionPrefix : @"",
                                key,
                                NSStringFromClass(expectedClass),
                                nilErrorMessage,
                                NSStringFromClass([value class])];
    return [NSError errorWithDomain:_errorDomain
                               code:-10
                           userInfo:@{NSLocalizedDescriptionKey: localizedError}];
}

@end
