#import <Batch/BAActionsCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAUserEventBuiltinActions.h>
#import <Batch/BatchProfile.h>
#import <Batch/BatchUser.h>

#define LOCAL_LOG_DOMAIN @"BatchActions"
#define JSON_ERROR_DOMAIN @"com.batch.module.actions.builtin"

@implementation BAUserEventBuiltinActions

+ (BatchUserAction *)trackEventAction {
    return [BatchUserAction
        userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"user.event"]
                     actionBlock:^(NSString *_Nonnull identifier,
                                   NSDictionary<NSString *, NSObject *> *_Nonnull arguments,
                                   id<BatchUserActionSource> _Nullable source) {
                       [BAUserEventBuiltinActions performTrackEvent:arguments];
                     }];
}

+ (void)performTrackEvent:(NSDictionary<NSString *, NSObject *> *_Nonnull)arguments {
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:arguments errorDomain:JSON_ERROR_DOMAIN];

    NSError *err = nil;

    NSString *event = [json objectForKey:@"e" kindOfClass:[NSString class] allowNil:NO error:&err];
    if (event == nil) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN
                         message:@"Could not perform track event action: %@", [err localizedDescription]];
        return;
    }

    if ([event length] == 0) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform track event action: event name is empty"];
        return;
    }

    BatchEventAttributes *attributes = [BatchEventAttributes new];
    NSString *label = [json objectForKey:@"l" kindOfClass:[NSString class] allowNil:YES error:&err];
    if ([label stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        [attributes putString:label forKey:@"$label"];
    }

    NSArray *tags = [json objectForKey:@"t" kindOfClass:[NSArray class] allowNil:YES error:&err];
    if ([tags count] > 0) {
        NSMutableArray *safeTags = [NSMutableArray arrayWithCapacity:tags.count];
        for (NSObject *tagValue in tags) {
            if ([tagValue isKindOfClass:[NSString class]] && ((NSString *)tagValue).length > 0) {
                [safeTags addObject:tagValue];
            } else {
                [BALogger debugForDomain:LOCAL_LOG_DOMAIN
                                 message:@"Could not add tag in track event action: invalid class '%@'",
                                         NSStringFromClass([tagValue class])];
            }
        }

        if (safeTags.count > 0) {
            [attributes putStringArray:safeTags forKey:@"$tags"];
        }
    }

    NSDictionary *argsData = [json objectForKey:@"a" kindOfClass:[NSDictionary class] allowNil:YES error:&err];
    if (argsData != nil) {
        NSArray<NSString *> *argsDataKeys = argsData.allKeys;
        for (NSString *key in argsDataKeys) {
            NSObject *argValue = argsData[key];

            if ([argValue isKindOfClass:[NSString class]]) {
                NSDate *dateValue = [self parseISO8601:(NSString *)argValue];
                if (dateValue != nil) {
                    [attributes putDate:dateValue forKey:key];
                } else {
                    [attributes putString:(NSString *)argValue forKey:key];
                }
            } else if ([argValue isKindOfClass:[NSNumber class]]) {
                NSNumber *numberAttr = (NSNumber *)argValue;
                const char *ctype = [numberAttr objCType];

                // Possible ctypes for NSNumber: “c”, “C”, “s”, “S”, “i”, “I”, “l”, “L”, “q”, “Q”, “f”, and “d”.
                // Supported ones: "c", "s", "i", "l", "q", "f", "d"

                // Non decimal values are read as long long, which is the biggest on both 32 and 64-bit architectures
                [BALogger debugForDomain:LOCAL_LOG_DOMAIN
                                 message:@"Args data for key '%@' is a NSNumber: %s", key, ctype];
                if (numberAttr == (void *)kCFBooleanFalse || (NSNumber *)numberAttr == (void *)kCFBooleanTrue) {
                    // Boolean value
                    [attributes putBool:[numberAttr boolValue] forKey:key];
                } else if (strcmp(ctype, @encode(char)) == 0 || strcmp(ctype, @encode(short)) == 0 ||
                           strcmp(ctype, @encode(int)) == 0 || strcmp(ctype, @encode(long)) == 0 ||
                           strcmp(ctype, @encode(long long)) == 0) {
                    // Long long might be truncated on 32 bit platforms
                    [attributes putInteger:[numberAttr integerValue] forKey:key];
                } else if (strcmp(ctype, @encode(float)) == 0 || strcmp(ctype, @encode(double)) == 0) {
                    // Decimal values
                    [attributes putDouble:[numberAttr doubleValue] forKey:key];
                } else if (strcmp(ctype, @encode(BOOL)) == 0) {
                    // According to the documentation that's not supported, but give it a shot
                    [attributes putBool:[numberAttr boolValue] forKey:key];
                } else {
                    // Try to make it work in a NSInteger
                    NSInteger val = [numberAttr integerValue];
                    if ([numberAttr isEqualToNumber:[NSNumber numberWithInteger:val]]) {
                        [attributes putInteger:[numberAttr integerValue] forKey:key];
                    }
                }
            } else {
                [BALogger debugForDomain:LOCAL_LOG_DOMAIN
                                 message:@"Could not add data in track event action: invalid class '%@' for key '%@'",
                                         NSStringFromClass([argValue class]), key];
            }
        }
    }

    [BatchProfile trackEventWithName:event attributes:attributes];
}

+ (NSDate *)parseISO8601:(NSString *)dateString {
    if ([BANullHelper isStringEmpty:dateString]) {
        return nil;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];

    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];

    return [formatter dateFromString:dateString];
}

@end
