//
//  BAMultiDelegatesProxy.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAMultiDelegatesProxy.h>

@interface BAMultiDelegatesProxy ()

@property (nonatomic, strong) NSPointerArray *delegatesPointerArray;

@end

@implementation BAMultiDelegatesProxy

#pragma mark -
#pragma mark Initialization

// Create a new multicast delegate.
+ (id)newProxyWithMainDelegate:(id)mainDelegate other:(NSArray *)delegates {
    return [[BAMultiDelegatesProxy alloc] initWithMainDelegate:mainDelegate other:delegates];
}

- (id)initWithMainDelegate:(id)mainDelegate other:(NSArray *)delegates {
    [self setDelegates:delegates];
    _mainDelegate = mainDelegate;

    return self;
}

- (id)newProxyWithDelegates:(NSArray *)delegates {
    [self setDelegates:delegates];

    return self;
}

#pragma mark -
#pragma mark Message Forwarding

// First we are asked if we respond to a selector
- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([self.mainDelegate respondsToSelector:aSelector]) {
        return YES;
    }

    for (id delegateObj in self.delegatesPointerArray.allObjects) {
        if ([delegateObj respondsToSelector:aSelector]) {
            return YES;
        }
    }

    return NO;
}

// Then we are asked for the method signature for that selector
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    // Check if the main delegate knows this selector before
    if ([self.mainDelegate respondsToSelector:selector]) {
        return [self.mainDelegate methodSignatureForSelector:selector];
    }

    for (id delegateObj in self.delegatesPointerArray.allObjects) {
        if ([delegateObj respondsToSelector:selector]) {
            return [delegateObj methodSignatureForSelector:selector];
        }
    }

    [[NSException exceptionWithName:NSInternalInconsistencyException
                             reason:[NSString stringWithFormat:@"Cannot find method signature for selector %@",
                                                               NSStringFromSelector(selector)]
                           userInfo:nil] raise];

    return nil;
}

// Once we answered, we forward the invocation
- (void)forwardInvocation:(NSInvocation *)invocation {
    // Check if method can return something.
    BOOL methodReturnSomething = (![[NSString stringWithCString:invocation.methodSignature.methodReturnType
                                                       encoding:NSUTF8StringEncoding] isEqualToString:@"v"]);

    // Make another fake invocation with the same method signature and send the same messages to the other delegates
    // (ignoring return values).
    NSInvocation *targetInvocation = invocation;
    if (methodReturnSomething) {
        targetInvocation = [NSInvocation invocationWithMethodSignature:invocation.methodSignature];
        [targetInvocation setSelector:invocation.selector];
    }

    for (id delegateObj in self.delegatesPointerArray.allObjects) {
        if ([delegateObj respondsToSelector:invocation.selector]) {
            [targetInvocation invokeWithTarget:delegateObj];
        }
    }

    // Send invocation to the main delegate and use it's return value.
    if ([self.mainDelegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.mainDelegate];
    }
}

#pragma mark -
#pragma mark Properties

- (void)setDelegates:(NSArray *)newDelegates {
    self.delegatesPointerArray = [NSPointerArray weakObjectsPointerArray];
    [newDelegates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [self.delegatesPointerArray addPointer:(void *)obj];
    }];
}

- (NSArray *)delegates {
    return self.delegatesPointerArray.allObjects;
}

@end
