//
//  BAJson.m
//  Batch

#import <Batch/BAJson.h>

#define LOCAL_ERROR_DOMAIN @"com.batch.core.json"

@implementation BAJson

+ (nullable NSString *)serialize:(nonnull id)object error:(NSError **)error {
    NSData *data = [BAJson serializeData:object error:error];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

+ (nullable NSData *)serializeData:(nonnull id)object error:(NSError **)error {
    if (object == nil) {
        [self writeNilInputErrorInto:error];
        return nil;
    }

    if (![NSJSONSerialization isValidJSONObject:object]) {
        [self writeUnserializableErrorInto:error];
        return nil;
    }

    return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
}

+ (nullable id)deserialize:(nonnull NSString *)json error:(NSError **)error {
    return [BAJson deserializeData:[json dataUsingEncoding:NSUTF8StringEncoding] error:error];
}

+ (nullable NSArray *)deserializeAsArray:(nonnull NSString *)json error:(NSError **)error {
    return [BAJson deserializeDataAsArray:[json dataUsingEncoding:NSUTF8StringEncoding] error:error];
}

+ (nullable NSDictionary *)deserializeAsDictionary:(nonnull NSString *)json error:(NSError **)error {
    return [BAJson deserializeDataAsDictionary:[json dataUsingEncoding:NSUTF8StringEncoding] error:error];
}

+ (nullable id)deserializeData:(nonnull NSData *)jsonData error:(NSError **)error {
    if (jsonData == nil) {
        [self writeNilInputErrorInto:error];
        return nil;
    }

    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:error];
}

+ (nullable NSArray *)deserializeDataAsArray:(nonnull NSData *)jsonData error:(NSError **)error {
    id data = [self deserializeData:jsonData error:error];

    // Only add error if data isn't nil, in which case we'll just bubble the previous error
    if (data && ![data isKindOfClass:NSArray.class]) {
        [self writeTypeMismatchErrorInto:error];
        return nil;
    }

    return data;
}

+ (nullable NSDictionary *)deserializeDataAsDictionary:(nonnull NSData *)jsonData error:(NSError **)error {
    id data = [self deserializeData:jsonData error:error];

    // Only add error if data isn't nil, in which case we'll just bubble the previous error
    if (data && ![data isKindOfClass:NSDictionary.class]) {
        [self writeTypeMismatchErrorInto:error];
        return nil;
    }

    return data;
}

+ (void)writeNilInputErrorInto:(NSError **)error {
    if (error) {
        *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                     code:-10
                                 userInfo:@{NSLocalizedDescriptionKey : @"Cannot serialize/deserialize a nil object."}];
    }
}

+ (void)writeTypeMismatchErrorInto:(NSError **)error {
    if (error) {
        *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                     code:-20
                                 userInfo:@{NSLocalizedDescriptionKey : @"Root type mismatch."}];
    }
}

+ (void)writeUnserializableErrorInto:(NSError **)error {
    if (error) {
        *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                     code:-30
                                 userInfo:@{NSLocalizedDescriptionKey : @"Unserializable object."}];
    }
}

@end
