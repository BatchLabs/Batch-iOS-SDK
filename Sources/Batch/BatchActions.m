//
//  BatchActions.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BatchActions.h>

#import <Batch/BAActionsCenter.h>

@implementation BatchManualUserActionSource

@end

@implementation BatchUserAction

+ (nonnull instancetype)userActionWithIdentifier:(nonnull NSString *)identifier
                                     actionBlock:(nonnull BatchUserActionBlock)actionBlock {
    return [[BatchUserAction alloc] initWithUserActionWithIdentifier:identifier actionBlock:actionBlock];
}

- (nonnull instancetype)initWithUserActionWithIdentifier:(nonnull NSString *)identifier
                                             actionBlock:(nonnull BatchUserActionBlock)actionBlock {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _actionBlock = actionBlock;
    }
    return self;
}

@end

@implementation BatchActions

+ (NSError *)registerAction:(nonnull BatchUserAction *)action {
    return [[BAActionsCenter instance] registerAction:action];
}

+ (void)unregisterActionIdentifier:(NSString *)actionIdentifier {
    [[BAActionsCenter instance] unregisterActionIdentifier:actionIdentifier];
}

+ (BOOL)performActionIdentifiedBy:(nonnull NSString *)identifier
                    withArguments:(nonnull NSDictionary<NSString *, NSObject *> *)args {
    return [[BAActionsCenter instance] publicPerformAction:identifier withArguments:args];
}

@end
