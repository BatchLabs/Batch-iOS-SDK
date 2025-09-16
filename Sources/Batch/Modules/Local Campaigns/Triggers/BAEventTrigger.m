//
//  BAEventTrigger.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BADictionaryHelper.h>
#import <Batch/BAEventTrigger.h>

@implementation BAEventTrigger

- (instancetype)initWithName:(NSString *)name label:(NSString *)label attributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        self.name = name;
        self.label = label;
        self.attributes = attributes;
    }

    return self;
}

+ (instancetype)triggerWithName:(NSString *)name label:(NSString *)label attributes:(NSDictionary *)attributes {
    return [[self alloc] initWithName:name label:label attributes:attributes];
}

- (BOOL)isSatisfiedForName:(nonnull NSString *)name label:(nullable NSString *)label {
    if ([name caseInsensitiveCompare:self.name] != NSOrderedSame) {
        return false;
    }

    if (self.label != nil && [self.label caseInsensitiveCompare:label] != NSOrderedSame) {
        return false;
    }

    return true;
}

- (BOOL)isSatisfiedForAttributes:(nullable NSDictionary *)attributes {
    if (self.attributes != nil) {
        return [BADictionaryHelper dictionary:attributes containsValuesFromDictionary:self.attributes];
    }

    return true;
}

@end
