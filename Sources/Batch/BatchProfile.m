//  Copyright (c) Batch SDK. All rights reserved.

#import <Batch/BAInjection.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchEventAttributes.h>
#import <Batch/BatchProfile.h>

NSErrorDomain const BatchProfileErrorDomain = @"com.batch.ios.profile";

@interface BatchProfileEditor ()

+ (void)_editWithBlock:(nonnull void (^)(BatchProfileEditor *_Nonnull __strong))editorClosure;
- (instancetype)_initInternal;

@end

@implementation BatchProfile

+ (void)identify:(nullable NSString *)customID {
    [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)] identify:customID];
}

+ (void)trackEventWithName:(nonnull NSString *)eventName {
    [self trackEventWithName:eventName attributes:nil];
}

+ (void)trackEventWithName:(nonnull NSString *)name attributes:(nullable BatchEventAttributes *)attributes {
    if (attributes && ![attributes isKindOfClass:[BatchEventAttributes class]]) {
        [BALogger warningForDomain:@"Profile"
                           message:@"Event attributes must be an instance of BatchEventAttributes. Aborting."];
        return;
    }
    NSError *error = nil;
    [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)] trackPublicEventWithName:name
                                                                                   attributes:attributes
                                                                                        error:&error];
    if (error) {
        [BALogger publicForDomain:@"Profile" message:@"trackEvent failed: %@", error.localizedDescription];
    }
}

+ (void)trackLocation:(nonnull CLLocation *)location {
    [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)] trackLocation:location];
}

+ (nonnull BatchProfileEditor *)editor {
    return [[BatchProfileEditor alloc] _initInternal];
}

+ (void)editWithBlock:(nonnull void (^)(BatchProfileEditor *_Nonnull __strong))editorClosure {
    [BatchProfileEditor _editWithBlock:editorClosure];
}

@end
