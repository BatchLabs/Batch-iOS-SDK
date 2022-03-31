//
//  BALNativeAttributeContext.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BALNativeAttributeContext.h>

#import <Batch/BAPropertiesCenter.h>

@implementation BALNativeAttributeContext

- (nullable BALValue *)resolveVariableNamed:(nonnull NSString *)name {
    if ([name hasPrefix:@"b."] && [name length] > 2) {
        NSString *parameter = [BAPropertiesCenter valueForShortName:[name substringFromIndex:2]];

        if (parameter != nil && [parameter length] > 0) {
            return [BALPrimitiveValue valueWithString:parameter];
        } else {
            return [BALPrimitiveValue nilValue];
        }
    }
    return nil;
}

@end
