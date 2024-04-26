//
//  BAUserDataEditor.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BACoreCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BAInstallDataEditor.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUserDataDiff.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/BAUserProfile.h>
#import <Batch/BAUserSQLiteDatasource.h>
#import <Batch/Batch-Swift.h>

#define PUBLIC_DOMAIN @"BatchUser - Editor"
#define DEBUG_DOMAIN @"UserDataEditor"

#define LANGUAGE_INDEX 0
#define REGION_INDEX 1
#define IDENTIFIER_INDEX 2

#define ATTRIBUTE_NAME_RULE @"^[a-zA-Z0-9_]{1,30}$"

// #define TAG_VALUE_RULE @"^[a-zA-Z0-9_]{1,255}$"
#define ATTR_STRING_MAX_LENGTH 64
#define ATTR_URL_MAX_LENGTH 2048

/// Waiting time before editor apply the save operation (in ms)
#define DISPATCH_QUEUE_TIMER 500

#define VALIDATE_ATTRIBUTE_KEY_OR_BAIL()                  \
    key = [self validateAndNormalizeKey:key error:error]; \
    if (key == nil) {                                     \
        return false;                                     \
    }

#define ENSURE_ATTRIBUTE_VALUE_CLASS(attrValue, expectedClass)                                                  \
    if (attrValue == nil) {                                                                                     \
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue                         \
                                            reason:@"The attribute's value cannot be nil. Did you mean to use " \
                                                   @"'removeAttributeForKey'?"];                                \
        return false;                                                                                           \
    }                                                                                                           \
    if (![attrValue isKindOfClass:expectedClass]) {                                                             \
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue                         \
                                            reason:@"The attribute's value isn't of the expected class (%@)",   \
                                                   NSStringFromClass(expectedClass)];                           \
        return false;                                                                                           \
    }

NSErrorDomain const BAInstallDataEditorErrorDomain = @"com.batch.ios.installdataeditor";

@interface BAInstallDataEditor ()

@property (readwrite, atomic) volatile BOOL wasApplied;

@end

@implementation BAInstallDataEditor {
    NSMutableArray<BOOL (^)(void)> *_operationQueue;
    id<BAUserDatasourceProtocol> _datasource;

    NSRegularExpression *_attributeNameValidationRegexp;
    BOOL _updatedFields[3];
    NSString *_userFields[3];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self clearUserFieldsStates];
        _operationQueue = [NSMutableArray new];
        _datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];

        static NSRegularExpression *regex;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          NSError *error = nil;
          regex = [NSRegularExpression regularExpressionWithPattern:ATTRIBUTE_NAME_RULE options:0 error:&error];
          if (error) {
              // Something went really wrong, so we'll just throw internal errors
              [BALogger errorForDomain:DEBUG_DOMAIN message:@"Error while creating user editor attribute regexp."];
              regex = nil;
          }
        });

        _attributeNameValidationRegexp = regex;
    }
    return self;
}

- (void)setLanguage:(nullable NSString *)language {
    if (![BANullHelper isNull:language] && [language isKindOfClass:[NSString class]]) {
        if ([language length] < 2) {
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"setLanguage called with invalid language (must be at least 2 chars)"];
            return;
        } else if ([language length] > 128) {
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"setLanguage called with invalid language (must be less than 128 chars)"];
            return;
        }
    }

    _updatedFields[LANGUAGE_INDEX] = YES;
    _userFields[LANGUAGE_INDEX] = language;
}

- (void)setRegion:(nullable NSString *)region {
    if (![BANullHelper isNull:region] && [region isKindOfClass:[NSString class]]) {
        if ([region length] < 2) {
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"setRegion called with invalid region (must be at least 2 chars)"];
            return;
        } else if ([region length] > 128) {
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"setRegion called with invalid region (must be less than 128 chars)"];
            return;
        }
    }

    _updatedFields[REGION_INDEX] = YES;
    _userFields[REGION_INDEX] = region;
}

- (void)setIdentifier:(nullable NSString *)identifier {
    if (![BANullHelper isNull:identifier] && [identifier isKindOfClass:[NSString class]] &&
        [identifier length] > 1024) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"setIdentifier called with invalid identifier (must be less 1024 chars)"];
        return;
    }

    _updatedFields[IDENTIFIER_INDEX] = YES;
    _userFields[IDENTIFIER_INDEX] = identifier;
}

- (BOOL)setBooleanAttribute:(BOOL)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setBoolAttribute:attribute forKey:key];
    }];

    return true;
}

- (BOOL)setDateAttribute:(nonnull NSDate *)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, [NSDate class])

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setDateAttribute:attribute forKey:key];
    }];

    return true;
}

- (BOOL)setStringAttribute:(nonnull NSString *)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, [NSString class])

    if ([((NSString *)attribute) length] > ATTR_STRING_MAX_LENGTH) {
        *error = [self
            logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue
                                 reason:
                                     @"String attributes can't be longer than %d characters. Ignoring attribute '%@'.",
                                     ATTR_STRING_MAX_LENGTH, key];
        return false;
    }

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setStringAttribute:(NSString *)attribute forKey:key];
    }];

    return true;
}

- (BOOL)setURLAttribute:(nonnull NSURL *)attribute
                 forKey:(nonnull NSString *)key
                  error:(NSError *_Nullable *_Nullable)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()
    ENSURE_ATTRIBUTE_VALUE_CLASS(attribute, [NSURL class])

    if ([(attribute.absoluteString) length] > ATTR_URL_MAX_LENGTH) {
        *error = [self
            logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue
                                 reason:@"URL attributes can't be longer than %d characters. Ignoring attribute '%@'.",
                                        ATTR_URL_MAX_LENGTH, key];
        return false;
    }

    if (attribute.scheme == nil || attribute.host == nil) {
        *error = [self
            logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue
                                 reason:@"URL attributes must respect format "
                                        @"'scheme://[authority][path][?query][#fragment]'. Ignoring attribute '%@'.",
                                        key];
        return false;
    }

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setURLAttribute:(NSURL *)attribute forKey:key];
    }];

    return true;
}

- (BOOL)setNumberAttribute:(nonnull NSNumber *)numberAttr forKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()
    ENSURE_ATTRIBUTE_VALUE_CLASS(numberAttr, [NSNumber class])

    BOOL (^operationBlock)(void);

    const char *ctype = [numberAttr objCType];

    // Possible ctypes for NSNumber: “c”, “C”, “s”, “S”, “i”, “I”, “l”, “L”, “q”, “Q”, “f”, and “d”.
    // Supported ones: "c", "s", "i", "l", "q", "f", "d"

    // Non decimal values are read as long long, which is the biggest on both 32 and 64-bit architectures
    [BALogger debugForDomain:DEBUG_DOMAIN message:@"Attribute for key '%@' is a NSNumber: %s", key, ctype];
    if (numberAttr == (id)kCFBooleanTrue || numberAttr == (id)kCFBooleanFalse) {
        operationBlock = ^BOOL() {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource setBoolAttribute:[numberAttr boolValue] forKey:key];
        };
    } else if (strcmp(ctype, @encode(short)) == 0 || strcmp(ctype, @encode(int)) == 0 ||
               strcmp(ctype, @encode(long)) == 0 || strcmp(ctype, @encode(long long)) == 0) {
        operationBlock = ^BOOL() {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource setLongLongAttribute:[numberAttr longLongValue] forKey:key];
        };
    } else if (strcmp(ctype, @encode(char)) == 0) {
        // Usually chars are booleans, even shorts are stored as ints.
        char val = [numberAttr charValue];
        if (val == 0 || val == 1) {
            operationBlock = ^BOOL() {
              id<BAUserDatasourceProtocol> datasource =
                  [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
              return [datasource setBoolAttribute:[numberAttr boolValue] forKey:key];
            };
        } else {
            operationBlock = ^BOOL() {
              id<BAUserDatasourceProtocol> datasource =
                  [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
              return [datasource setLongLongAttribute:[numberAttr charValue] forKey:key];
            };
        }
    }
    // Decimal values
    else if (strcmp(ctype, @encode(float)) == 0 || strcmp(ctype, @encode(double)) == 0) {
        operationBlock = ^BOOL() {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource setDoubleAttribute:[numberAttr doubleValue] forKey:key];
        };
    }
    // According to the documentation that's not supported, but give it a shot
    else if (strcmp(ctype, @encode(BOOL)) == 0) {
        operationBlock = ^BOOL() {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource setBoolAttribute:[numberAttr boolValue] forKey:key];
        };
    } else {
        // Try to make it work in a long long
        long long val = [numberAttr longLongValue];
        if ([numberAttr isEqualToNumber:[NSNumber numberWithLongLong:val]]) {
            // Yay it worked, allow it. You're lucky we're in a good mood ;)
            operationBlock = ^BOOL() {
              id<BAUserDatasourceProtocol> datasource =
                  [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
              return [datasource setLongLongAttribute:val forKey:key];
            };
        }
    }

    if (operationBlock) {
        [self addToQueueSynchronized:operationBlock];
        return true;
    }

    *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidValue
                                        reason:@"Unsupported NSNumber type. Ignoring attribute '%@' for value '%@'.",
                                               key, numberAttr];
    return false;
}

- (BOOL)setIntegerAttribute:(NSInteger)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    return [self setLongLongAttribute:attribute forKey:key error:error];
}

- (BOOL)setLongLongAttribute:(long long)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setLongLongAttribute:attribute forKey:key];
    }];

    return true;
}

- (BOOL)setFloatAttribute:(float)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    return [self setDoubleAttribute:attribute forKey:key error:error];
}

- (BOOL)setDoubleAttribute:(double)attribute forKey:(nonnull NSString *)key error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)
    VALIDATE_ATTRIBUTE_KEY_OR_BAIL()

    [self addToQueueSynchronized:^BOOL() {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource setDoubleAttribute:attribute forKey:key];
    }];

    return true;
}

- (void)removeAttributeForKey:(nonnull NSString *)key {
    NSError *err = nil; // Unused for now
    key = [self validateAndNormalizeKey:key error:&err];

    if (key == nil) {
        return;
    }

    [BALogger debugForDomain:DEBUG_DOMAIN message:@"Removing attribute for key '%@'", key];

    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource removeAttributeNamed:key];
    }];
}

- (void)clearAttributes {
    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource clearAttributes];
    }];
}

- (void)addTag:(nonnull NSString *)tag inCollection:(nonnull NSString *)collection {
    NSError *err = nil; // We don't do anything with it right now but it will be useful later
    collection = [self validateAndNormalizeTagCollection:collection
                                                   error:&err
                               operationErrorDescription:@"tag '%@' for collection '%@'", tag, collection];

    if (collection == nil) {
        return;
    }

    BOOL didTagValidate = [self validateTag:tag];

    if (!didTagValidate) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Invalid tag. Please make sure that the tag is a non empty string. It also can't be "
                                  @"longer than %d characters. Ignoring tag '%@' for collection '%@'.",
                                  ATTR_STRING_MAX_LENGTH, tag, collection];
        return;
    }

    tag = [self normalizeTag:tag];

    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource addTag:tag toCollection:collection];
    }];
}

- (void)removeTag:(nonnull NSString *)tag fromCollection:(nonnull NSString *)collection {
    NSError *err = nil; // We don't do anything with it right now but it will be useful later
    collection = [self validateAndNormalizeTagCollection:collection
                                                   error:&err
                               operationErrorDescription:@"tag '%@' for collection '%@'", tag, collection];

    if (collection == nil) {
        return;
    }

    BOOL didTagValidate = [self validateTag:tag];

    if (!didTagValidate) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Invalid tag. Please make sure that the tag is a non empty string. It also can't be "
                                  @"longer than %d characters. Ignoring tag '%@' for collection '%@'.",
                                  ATTR_STRING_MAX_LENGTH, tag, collection];
        return;
    }

    tag = [self normalizeTag:tag];

    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource removeTag:tag fromCollection:collection];
    }];
}

- (void)clearTags {
    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource clearTags];
    }];
}

- (void)clearTagCollection:(nonnull NSString *)collection {
    NSError *err = nil; // We don't do anything with it right now but it will be useful later
    collection = [self validateAndNormalizeTagCollection:collection
                                                   error:&err
                               operationErrorDescription:@"tag collection deletion for '%@'", collection];

    if (collection == nil) {
        return;
    }

    [self addToQueueSynchronized:^BOOL {
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      return [datasource clearTagsFromCollection:collection];
    }];
}

/**
 @param completion Used mainly for testing purposes. Called when saving operation completed or failed.
 */
- (void)save:(void (^)(void))completion {
    // Execute user update operation outside the editor's queue to avoid debounce
    // and have updates available in the ids of the profile event
    [self executeUserUpdateOperation];

    // Add custom data operations to the queue
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DISPATCH_QUEUE_TIMER * NSEC_PER_MSEC)),
                   [BAUserDataManager sharedQueue], ^{
                     NSArray<BOOL (^)(void)> *applyQueue;
                     @synchronized(self->_operationQueue) {
                         applyQueue = [self popOperationQueue];
                     }
                     if (![self canSave]) {
                         if (completion != nil) {
                             completion();
                         }
                         return;
                     }
                     [BAUserDataManager addOperationQueueAndSubmit:applyQueue withCompletion:completion];
                   });
}

- (void)save {
    [self save:nil];
}

- (BOOL)canSave {
    return [BAUserDataManager canSave];
}

- (NSArray<BOOL (^)(void)> *)operationQueue {
    return [_operationQueue copy];
}

#pragma mark Private methods

- (void)addToQueueSynchronized:(BOOL (^)(void))operationBlock {
    @synchronized(_operationQueue) {
        [_operationQueue addObject:operationBlock];
    }
}

- (void)addfirstToQueueSynchronized:(BOOL (^)(void))operationBlock {
    @synchronized(_operationQueue) {
        [_operationQueue insertObject:operationBlock atIndex:0];
    }
}

- (void)executeUserUpdateOperation {
    if (!_updatedFields[LANGUAGE_INDEX] && !_updatedFields[REGION_INDEX] && !_updatedFields[IDENTIFIER_INDEX]) {
        // Nothing to do
        return;
    }

    NSString *previousUserFields[3];
    BAUserProfile *userProfile = [BAUserProfile defaultUserProfile];
    previousUserFields[LANGUAGE_INDEX] = [userProfile language];
    previousUserFields[REGION_INDEX] = [userProfile region];
    previousUserFields[IDENTIFIER_INDEX] = [userProfile customIdentifier];

    if (self->_updatedFields[LANGUAGE_INDEX]) {
        [userProfile setLanguage:self->_userFields[LANGUAGE_INDEX]];
    }

    if (self->_updatedFields[REGION_INDEX]) {
        [userProfile setRegion:self->_userFields[REGION_INDEX]];
    }

    if (self->_updatedFields[IDENTIFIER_INDEX]) {
        [userProfile setCustomIdentifier:self->_userFields[IDENTIFIER_INDEX]];
    }

    [self clearUserFieldsStates];
}

- (void)clearUserFieldsStates {
    _updatedFields[0] = NO;
    _updatedFields[1] = NO;
    _updatedFields[2] = NO;
    _userFields[0] = nil;
    _userFields[1] = nil;
    _userFields[2] = nil;
}

- (NSArray<BOOL (^)(void)> *)popOperationQueue {
    NSMutableArray<BOOL (^)(void)> *applyQueue = [_operationQueue mutableCopy];
    [_operationQueue removeAllObjects];
    return applyQueue;
}

- (BOOL)validateAttributeKey:(NSString *)key error:(NSError *_Nullable *_Nonnull)error {
    if (key == nil) {
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidKey
                                            reason:@"Key cannot be nil. Ignoring attribute '%@'.", key];
        return NO;
    }

    if (!_attributeNameValidationRegexp) {
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInternal
                                            reason:@"Internal error. Ignoring attribute '%@'.", key];
        return NO;
    }

    if ([key isKindOfClass:[NSString class]]) {
        NSRange matchingRange = [_attributeNameValidationRegexp rangeOfFirstMatchInString:key
                                                                                  options:0
                                                                                    range:NSMakeRange(0, key.length)];
        if (matchingRange.location != NSNotFound) {
            return YES;
        }
    }

    *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidKey
                                        reason:@"Invalid key. Please make sure that the key is made of letters, "
                                               @"underscores and numbers only (a-zA-Z0-9_). It also can't be longer "
                                               @"than 30 characters. Ignoring attribute '%@'.",
                                               key];

    return NO;
}

- (NSString *)validateAndNormalizeTagCollection:(NSString *)collection
                                          error:(NSError *_Nullable *_Nonnull)error
                      operationErrorDescription:(NSString *)descriptionFormatString, ... {
    if (collection == nil) {
        va_list arglist;
        va_start(arglist, descriptionFormatString);
        NSString *operationDescription = [[NSString alloc] initWithFormat:descriptionFormatString arguments:arglist];
        va_end(arglist);
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidKey
                                            reason:@"Collection cannot be nil. Ignoring '%@'.", operationDescription];
        return nil;
    }

    if (!_attributeNameValidationRegexp) {
        va_list arglist;
        va_start(arglist, descriptionFormatString);
        NSString *operationDescription = [[NSString alloc] initWithFormat:descriptionFormatString arguments:arglist];
        va_end(arglist);
        *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInternal
                                            reason:@"Internal error. Ignoring %@.", operationDescription];
        return nil;
    }

    if ([collection isKindOfClass:[NSString class]]) {
        NSRange matchingRange =
            [_attributeNameValidationRegexp rangeOfFirstMatchInString:collection
                                                              options:0
                                                                range:NSMakeRange(0, collection.length)];
        if (matchingRange.location != NSNotFound) {
            return [collection lowercaseString];
        }
    }

    va_list arglist;
    va_start(arglist, descriptionFormatString);
    NSString *operationDescription = [[NSString alloc] initWithFormat:descriptionFormatString arguments:arglist];
    va_end(arglist);
    *error = [self logAndMakeSaveErrorWithCode:BAInstallDataEditorErrorInvalidKey
                                        reason:@"Invalid collection. Please make sure that the collection is made of "
                                               @"letters, underscores and numbers only (a-zA-Z0-9_). It also can't be "
                                               @"longer than 30 characters. Ignoring %@.",
                                               operationDescription];

    return nil;
}

- (nullable NSString *)validateAndNormalizeKey:(NSString *)key error:(NSError *_Nullable *_Nonnull)error {
    BOOL didKeyValidate = [self validateAttributeKey:key error:error];

    if (!didKeyValidate) {
        return nil;
    }

    return [key lowercaseString];
}

- (BOOL)validateTag:(NSString *)tag {
    if ([tag isKindOfClass:[NSString class]]) {
        return [tag length] <= ATTR_STRING_MAX_LENGTH;
    }

    return NO;
}

- (NSString *)normalizeTag:(NSString *)tag {
    return [tag lowercaseString];
}

- (NSError *)logAndMakeSaveErrorWithCode:(BAInstallDataEditorError)code reason:(NSString *)reasonFormatString, ... {
    va_list arglist;
    va_start(arglist, reasonFormatString);
    NSString *reason = [[NSString alloc] initWithFormat:reasonFormatString arguments:arglist];
    va_end(arglist);
    [BALogger publicForDomain:PUBLIC_DOMAIN message:@"%@", reason];
    return [NSError errorWithDomain:BAInstallDataEditorErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey : reason}];
}

@end
