//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATUserActivity.h"
#import <objc/runtime.h>

@implementation BATUserActivity

+ (void)initialize {
    Method boolGetterMethod = class_getInstanceMethod([self class], @selector(exampleBoolGetter));

    SEL targetSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"is", @"UniversalLink"]);
    IMP implementation = imp_implementationWithBlock(^(id self) {
      return [self hasUniversalLink];
    });
    class_addMethod([self class], targetSelector, implementation, method_getTypeEncoding(boolGetterMethod));
}

// Useless method that is used to get its type encoding
- (BOOL)exampleBoolGetter {
    return true;
}

@end
