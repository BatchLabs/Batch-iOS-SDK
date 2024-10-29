//
//  BatchUser.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAInjection.h>
#import <Batch/BAInstallDataEditor.h>
#import <Batch/Batch-Swift.h>
#import <Batch/BatchProfileEditor.h>

#define PUBLIC_DOMAIN @"BatchProfile - Editor"

/// Those macros are required to properly catch a type cast error before Swift does it
/// as we can't catch a Swift bridging error

#define ENSURE_KEY_STRING(attrKey)                                                                       \
    if (![attrKey isKindOfClass:NSString.class]) {                                                       \
        *error = [self _logAndMakeSaveErrorWithCode:BatchProfileErrorEditorInvalidKey                    \
                                             reason:@"The attribute's key must be a nonnull NSString."]; \
        return false;                                                                                    \
    }

#define ENSURE_ATTRIBUTE_VALUE_CLASS(attrValue, expectedClass)                                                   \
    if (attrValue == nil) {                                                                                      \
        *error = [self _logAndMakeSaveErrorWithCode:BatchProfileErrorEditorInvalidValue                          \
                                             reason:@"The attribute's value cannot be nil. Did you mean to use " \
                                                    @"'removeAttributeForKey'?"];                                \
        return false;                                                                                            \
    }                                                                                                            \
    if (![attrValue isKindOfClass:expectedClass]) {                                                              \
        *error = [self _logAndMakeSaveErrorWithCode:BatchProfileErrorEditorInvalidValue                          \
                                             reason:@"The attribute's value isn't of the expected class (%@)",   \
                                                    NSStringFromClass(expectedClass)];                           \
        return false;                                                                                            \
    }

#define ENSURE_ATTRIBUTE_VALUE_CLASS_NILABLE(attrValue, expectedClass)                                         \
    if (attrValue != nil && ![attrValue isKindOfClass:expectedClass]) {                                        \
        *error = [self _logAndMakeSaveErrorWithCode:BatchProfileErrorEditorInvalidValue                        \
                                             reason:@"The attribute's value isn't of the expected class (%@)", \
                                                    NSStringFromClass(expectedClass)];                         \
        return false;                                                                                          \
    }

@implementation BatchProfileEditor {
    BATProfileEditor *_backingImpl;
}

+ (void)_editWithBlock:(nonnull void (^)(BatchProfileEditor *_Nonnull __strong))editorClosure {
    [[[BatchProfileEditor alloc] _initInternal] _editWithBlock:editorClosure];
}

- (instancetype)_initInternal {
    self = [super init];
    if (self) {
        _backingImpl = [BAInjection injectClass:BATProfileEditor.class];
        // Enable install data compatibility
        [_backingImpl enableInstallCompatibility];
    }
    return self;
}

- (BOOL)setLanguage:(nullable NSString *)language error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_ATTRIBUTE_VALUE_CLASS_NILABLE(language, NSString.class)
    return [_backingImpl setLanguage:language error:error];
}

- (BOOL)setRegion:(nullable NSString *)region error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_ATTRIBUTE_VALUE_CLASS_NILABLE(region, NSString.class)
    return [_backingImpl setRegion:region error:error];
}

- (BOOL)setEmailAddress:(nullable NSString *)email error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_ATTRIBUTE_VALUE_CLASS_NILABLE(email, NSString.class)
    return [_backingImpl setEmail:email error:error];
}

- (void)setEmailMarketingSubscriptionState:(BatchEmailSubscriptionState)state {
    BATProfileEditorEmailSubscriptionState swiftState;
    switch (state) {
        case BatchEmailSubscriptionStateSubscribed:
            swiftState = BATProfileEditorEmailSubscriptionStateSubscribed;
            break;
        case BatchEmailSubscriptionStateUnsubscribed:
            swiftState = BATProfileEditorEmailSubscriptionStateUnsubscribed;
    }
    [_backingImpl setEmailMarketingSubscriptionState:swiftState];
}

- (BOOL)setPhoneNumber:(nullable NSString *)phoneNumber error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_ATTRIBUTE_VALUE_CLASS_NILABLE(phoneNumber, NSString.class)
    return [_backingImpl setPhoneNumber:phoneNumber error:error];
}

- (void)setSMSMarketingSubscriptionState:(BatchSMSSubscriptionState)state {
    BATProfileEditorSMSSubscriptionState swiftState;
    switch (state) {
        case BatchSMSSubscriptionStateSubscribed:
            swiftState = BATProfileEditorSMSSubscriptionStateSubscribed;
            break;
        case BatchSMSSubscriptionStateUnsubscribed:
            swiftState = BATProfileEditorSMSSubscriptionStateUnsubscribed;
    }
    [_backingImpl setSMSMarketingSubscriptionState:swiftState];
}

- (BOOL)addItemToStringArrayAttribute:(NSString *)element forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl addWithValue:element toArray:key error:error];
}

- (BOOL)removeItemFromStringArrayAttribute:(NSString *)element forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl removeWithValue:element fromArray:key error:error];
}

- (BOOL)setBooleanAttribute:(BOOL)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl setCustomBoolAttribute:attribute forKey:key error:error];
}

- (BOOL)setDateAttribute:(nonnull NSDate *)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, NSDate.class)
    return [_backingImpl setCustomDateAttribute:attribute forKey:key error:error];
}

- (BOOL)setStringAttribute:(NSString *)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, NSString.class)
    return [_backingImpl setCustomStringAttribute:attribute forKey:key error:error];
}

- (BOOL)setStringArrayAttribute:(NSArray<NSString *> *)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, NSArray.class)

    if (![self _areArrayElements:attribute ofType:NSString.class]) {
        *error = [self
            _logAndMakeSaveErrorWithCode:BatchProfileErrorEditorInvalidValue
                                  reason:@"String array attributes must only contain instances of String/NSString"];
        return false;
    }

    return [_backingImpl setCustomStringArrayAttribute:attribute forKey:key error:error];
}

- (BOOL)setIntegerAttribute:(NSInteger)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl setCustomInt64Attribute:(int64_t)attribute forKey:key error:error];
}

- (BOOL)setLongLongAttribute:(long long)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl setCustomInt64Attribute:attribute forKey:key error:error];
}

- (BOOL)setFloatAttribute:(float)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl setCustomDoubleAttribute:(double)attribute forKey:key error:error];
}

- (BOOL)setDoubleAttribute:(double)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl setCustomDoubleAttribute:attribute forKey:key error:error];
}

- (BOOL)setURLAttribute:(nonnull NSURL *)attribute forKey:(NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, NSURL.class)
    return [_backingImpl setCustomURLAttribute:attribute forKey:key error:error];
}

- (BOOL)removeAttributeForKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    ENSURE_KEY_STRING(key)
    return [_backingImpl deleteCustomAttributeForKey:key error:error];
}

- (void)save {
    @synchronized(self) {
        if (_backingImpl.consumed) {
            [BALogger publicForDomain:PUBLIC_DOMAIN message:@"Cannot save editor: save has already been called once"];
            return;
        }
        [_backingImpl consume];
        // Copy the editor to make sure that it's not modified while we work with it
        BATProfileEditor *editorCopy = [_backingImpl copy];

        [[BAInjection injectProtocol:@protocol(BAProfileCenterProtocol)] applyEditor:editorCopy];
    }
}

- (void)_editWithBlock:(nonnull void (^)(BatchProfileEditor *_Nonnull __strong))editorClosure {
    editorClosure(self);
    [self save];
}

- (NSError *)_logAndMakeSaveErrorWithCode:(BatchProfileError)code reason:(NSString *)reasonFormatString, ... {
    va_list arglist;
    va_start(arglist, reasonFormatString);
    NSString *reason = [[NSString alloc] initWithFormat:reasonFormatString arguments:arglist];
    va_end(arglist);
    [BALogger publicForDomain:PUBLIC_DOMAIN message:@"%@", reason];
    return [NSError errorWithDomain:BatchProfileErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : reason}];
}

- (BOOL)_areArrayElements:(nonnull NSArray *)array ofType:(Class)clazz {
    for (id element in array) {
        if (![element isKindOfClass:clazz]) {
            return false;
        }
    }
    return true;
}

@end
