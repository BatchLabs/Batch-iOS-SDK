//
//  BatchUserAttribute.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BatchUserAttribute.h>

@implementation BatchUserAttribute

- (nullable instancetype)initWithValue:(nonnull id)value type:(BatchUserAttributeType)type {
    self = [super init];
    if (self) {
        self.value = value;
        self.type = type;
    }
    return self;
}

- (nullable NSDate *)dateValue {
    if (self.type == BatchUserAttributeTypeDate) {
        return _value;
    }
    return nil;
}

- (NSString *)stringValue {
    if (self.type == BatchUserAttributeTypeString) {
        return _value;
    }
    return nil;
}

- (NSNumber *)numberValue {
    if (self.type == BatchUserAttributeTypeBool || self.type == BatchUserAttributeTypeDouble ||
        self.type == BatchUserAttributeTypeLongLong) {
        return _value;
    }
    return nil;
}

- (NSURL *)urlValue {
    if (self.type == BatchUserAttributeTypeURL) {
        return _value;
    }
    return nil;
}

@end
