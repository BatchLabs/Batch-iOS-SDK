//
//  BAUserDataEditor.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BACoreCenter.h>
#import <Batch/BAEmailUtils.h>
#import <Batch/BAInjection.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUserDataDiff.h>
#import <Batch/BAUserDataEditor.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/BAUserEmailSubscription.h>
#import <Batch/BAUserProfile.h>
#import <Batch/BAUserSQLiteDatasource.h>

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
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue                         \
                                            reason:@"The attribute's value cannot be nil. Did you mean to use " \
                                                   @"'removeAttributeForKey'?"];                                \
        return false;                                                                                           \
    }                                                                                                           \
    if (![attrValue isKindOfClass:expectedClass]) {                                                             \
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue                         \
                                            reason:@"The attribute's value isn't of the expected class (%@)",   \
                                                   NSStringFromClass(expectedClass)];                           \
        return false;                                                                                           \
    }

@interface BAUserDataEditor ()

@property (readwrite, atomic) volatile BOOL wasApplied;

@end

@implementation BAUserDataEditor {
    NSMutableArray<BOOL (^)(void)> *_operationQueue;
    id<BAUserDatasourceProtocol> _datasource;

    NSRegularExpression *_attributeNameValidationRegexp;
    BOOL _updatedFields[3];
    NSString *_userFields[3];

    /// Email subscription
    BAUserEmailSubscription *_emailSubscription;
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
                          message:@"setIdentifier called with identifier region (must be less 1024 chars)"];
        return;
    }

    _updatedFields[IDENTIFIER_INDEX] = YES;
    _userFields[IDENTIFIER_INDEX] = identifier;
}

- (BOOL)setEmail:(nullable NSString *)email error:(NSError **)error {
    INIT_AND_BLANK_ERROR_IF_NEEDED(error)

    // Ensure we already have a custom user identifier
    // or setIdentifier has been previously called in this editor instance
    if ([BatchUser identifier] == nil &&
        (_updatedFields[IDENTIFIER_INDEX] == NO ||
         (_updatedFields[IDENTIFIER_INDEX] == YES && _userFields[IDENTIFIER_INDEX] == nil))) {
        *error = [self
            logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInternal
                                 reason:@"setEmail called even though no custom user id is set. Please ensure to call "
                                        @"setIdentifier before using this method."];
        return false;
    }

    // Deleting case
    if (email == nil) {
        if (_emailSubscription == nil) {
            _emailSubscription = [[BAUserEmailSubscription alloc] initWithEmail:nil];
        } else {
            [_emailSubscription setEmail:nil];
        }
        return true;
    }

    // Ensure email is not too long
    if ([BAEmailUtils isEmailTooLong:email]) {
        *error =
            [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
                                       reason:@"Email can't be longer than %d characters. Ignoring.", EMAIL_MAX_LENGTH];
        return false;
    }

    // Ensure email is valid
    if (![BAEmailUtils isValidEmail:email]) {
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
                                            reason:@"setEmail called with invalid email format. Please ensure to "
                                                   @"respect the following regex: .@.\\..* "];
        return false;
    }

    if (_emailSubscription == nil) {
        _emailSubscription = [[BAUserEmailSubscription alloc]
            initWithEmail:[email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    } else {
        [_emailSubscription setEmail:[email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }

    return true;
}

- (void)setEmailMarketingSubscriptionState:(BatchEmailSubscriptionState)state {
    if (_emailSubscription == nil) {
        _emailSubscription = [[BAUserEmailSubscription alloc] init];
    }
    [_emailSubscription setEmailSubscriptionState:state forKind:BAEmailKindMarketing];
}

- (void)setAttribute:(nullable NSObject *)attribute forKey:(nonnull NSString *)key {
    if (attribute == nil) {
        [self removeAttributeForKey:key];
        return;
    }

    [BALogger debugForDomain:DEBUG_DOMAIN message:@"Setting attribute (legacy) '%@' for key '%@'", attribute, key];

    // Let's guess the object type
    // Quick reminder of supported objects:
    //    - NSNumber
    //    - NSString
    //    - NSDate
    //    - NSURL
    if ([attribute isKindOfClass:[NSString class]]) {
        [self setStringAttribute:(NSString *)attribute forKey:key error:nil];
        return;
    } else if ([attribute isKindOfClass:[NSDate class]]) {
        [self setDateAttribute:(NSDate *)attribute forKey:key error:nil];
        return;
    } else if ([attribute isKindOfClass:[NSNumber class]]) {
        [self setNumberAttribute:(NSNumber *)attribute forKey:key error:nil];
        return;
    } else if ([attribute isKindOfClass:[NSURL class]]) {
        [self setURLAttribute:(NSURL *)attribute forKey:key error:nil];
        return;
    }

    [BALogger publicForDomain:PUBLIC_DOMAIN
                      message:@"Invalid attribute value. Please check the documentation for accepted values. Ignoring "
                              @"attribute '%@'.",
                              key];
    return;
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
            logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
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
            logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
                                 reason:@"URL attributes can't be longer than %d characters. Ignoring attribute '%@'.",
                                        ATTR_URL_MAX_LENGTH, key];
        return false;
    }

    if (attribute.scheme == nil || attribute.host == nil) {
        *error = [self
            logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
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

    *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidValue
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
    if (![[[BACoreCenter instance] status] isRunning]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Batch must be started before changes to user data can be saved. The changes you've "
                                  @"just tried to save have been discarded."];
        return false;
    }

    if ([[BAOptOut instance] isOptedOut]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Batch is Opted-Out from: BatchUserDataEditor changes cannot be saved"];
        return false;
    }

    return true;
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

- (BOOL (^)(void))userUpdateOperation {
    if (!_updatedFields[LANGUAGE_INDEX] && !_updatedFields[REGION_INDEX] && !_updatedFields[IDENTIFIER_INDEX]) {
        // Nothing to do
        return nil;
    }

    return ^{
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

      bool updated = false;
      for (int i = 0; i < 3; ++i) {
          if (previousUserFields[i] != self->_userFields[i] &&
              ![previousUserFields[i] isEqualToString:self->_userFields[i]]) {
              // Field have changed
              updated = true;
          }
      }

      if (updated) {
          [userProfile incrementVersion];
      }

      [self clearUserFieldsStates];
      return YES;
    };
}

- (BOOL (^)(void))emailUpdateOperation {
    if (_emailSubscription == nil) {
        return nil;
    }
    return ^{
      [self->_emailSubscription sendEmailSubscriptionEvent];
      return YES;
    };
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

    BOOL (^userUpdateOperation)(void) = [self userUpdateOperation];
    if (userUpdateOperation != nil) {
        [applyQueue insertObject:userUpdateOperation atIndex:0];
    }

    BOOL (^emailUpdateOperation)(void) = [self emailUpdateOperation];
    if (emailUpdateOperation != nil) {
        [applyQueue addObject:emailUpdateOperation];
    }

    return applyQueue;
}

- (BOOL)validateAttributeKey:(NSString *)key error:(NSError *_Nullable *_Nonnull)error {
    if (key == nil) {
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidKey
                                            reason:@"Key cannot be nil. Ignoring attribute '%@'.", key];
        return NO;
    }

    if (!_attributeNameValidationRegexp) {
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInternal
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

    *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidKey
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
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidKey
                                            reason:@"Collection cannot be nil. Ignoring '%@'.", operationDescription];
        return nil;
    }

    if (!_attributeNameValidationRegexp) {
        va_list arglist;
        va_start(arglist, descriptionFormatString);
        NSString *operationDescription = [[NSString alloc] initWithFormat:descriptionFormatString arguments:arglist];
        va_end(arglist);
        *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInternal
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
    *error = [self logAndMakeSaveErrorWithCode:BatchUserDataEditorErrorInvalidKey
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

- (NSError *)logAndMakeSaveErrorWithCode:(BatchUserDataEditorError)code reason:(NSString *)reasonFormatString, ... {
    va_list arglist;
    va_start(arglist, reasonFormatString);
    NSString *reason = [[NSString alloc] initWithFormat:reasonFormatString arguments:arglist];
    va_end(arglist);
    [BALogger publicForDomain:PUBLIC_DOMAIN message:@"%@", reason];
    return [NSError errorWithDomain:BatchUserDataEditorErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey : reason}];
}

@end
