//
//  BAEventTrigger.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAEventTrigger.h>

@implementation BAEventTrigger

- (instancetype)initWithName:(NSString *)name label:(NSString *)label {
    self = [super init];
    if (self) {
        self.name = name;
        self.label = label;
    }

    return self;
}

+ (instancetype)triggerWithName:(NSString *)name label:(NSString *)label {
    return [[self alloc] initWithName:name label:label];
}

- (BOOL)isSatisfiedForName:(nonnull NSString *)name label:(nullable NSString *)label {
    if ([name caseInsensitiveCompare:self.name] != NSOrderedSame) {
        return false;
    }

    if (self.label != nil && [label caseInsensitiveCompare:self.label] != NSOrderedSame) {
        return false;
    }

    return true;
}

@end
