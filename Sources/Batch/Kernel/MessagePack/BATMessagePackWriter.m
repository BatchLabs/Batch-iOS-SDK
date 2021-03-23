//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BATMessagePackWriter.h>
#include "msgpack-c.h" // not #import

#define LOCAL_ERROR_DOMAIN @"BATMessagePackWriter"

#define MP_WRITE_AND_RETURN_IF_NIL(value) if (value == nil) { [self writeNil]; return; }
#define MP_WRITE_AND_SUCCESS_IF_NIL(value) if (value == nil) { [self writeNil]; return true; }
#define MP_BAIL_ERROR(_code, message) \
if (error != nil) {\
    *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN\
                      code:_code\
                      userInfo:@{NSLocalizedDescriptionKey: message}];\
}\
return false;

@interface BATMessagePackWriter ()
{
    bat_cmp_ctx_t _msgpackContext;
    NSMutableData *_data;
}

- (void)_append:(const void*)data count:(size_t)count;

@end

static bool mp_reader_bridge(bat_cmp_ctx_t *ctx, void *data, size_t limit) {
    return false;
}

static bool mp_skipper_bridge(struct bat_cmp_ctx_s *ctx, size_t count) {
    return false;
}

static size_t mp_writer_bridge(bat_cmp_ctx_t *ctx, const void *data, size_t count) {
    //buf is actually a pointer to our objc writer
    [(__bridge BATMessagePackWriter*)ctx->buf _append:data count:count];
    return count;
}

@implementation BATMessagePackWriter

- (instancetype)init
{
    self = [super init];
    
    // Use the messagepack context data to store a pointer to our writer
    bat_cmp_init(&_msgpackContext,
                 (__bridge void*)self,
                 mp_reader_bridge,
                 mp_skipper_bridge,
                 mp_writer_bridge);
    
    _data = [NSMutableData new];
    
    return self;
}

- (void)_append:(const void*)data count:(size_t)count
{
    [_data appendBytes:data length:count];
}

+ (BOOL)_canWriteAny:(nonnull id)anyValue
{
    if ([anyValue isKindOfClass:[NSArray class]]) {
        return [self canPackArray:(NSArray*)anyValue];
    }
    if ([anyValue isKindOfClass:[NSDictionary class]]) {
        return [self canPackDictionary:(NSDictionary*)anyValue];
    }
    
    return anyValue == [NSNull null] ||
            [anyValue isKindOfClass:[NSString class]] ||
            [anyValue isKindOfClass:[NSData class]] ||
            [anyValue isKindOfClass:[NSNumber class]];
}

- (BOOL)_writeAny:(nonnull id)anyValue error:(NSError * _Nullable * _Nullable)error
{
    if (![BATMessagePackWriter _canWriteAny:anyValue]) {
        NSString *errMsg;
        if ([anyValue isKindOfClass:[NSArray class]]) {
            errMsg = @"Array is not packable";
        } else if ([anyValue isKindOfClass:[NSDictionary class]]) {
            errMsg = @"Dictionary is not packable";
        } else {
            errMsg = @"Unsupported type";
        }
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, errMsg)
    }
    
    if (anyValue == [NSNull null]) {
        [self writeNil];
        return true;
    }
    
    if ([anyValue isKindOfClass:[NSString class]]) {
        return [self writeString:(NSString*)anyValue error:error];
    }
    
    if ([anyValue isKindOfClass:[NSArray class]]) {
        return [self writeArray:(NSArray*)anyValue error:error];
    }
    
    if ([anyValue isKindOfClass:[NSDictionary class]]) {
        return [self writeDictionary:(NSDictionary*)anyValue error:error];
    }
    
    if ([anyValue isKindOfClass:[NSData class]]) {
        return [self writeData:(NSData*)anyValue error:error];
    }
    
    if ([anyValue isKindOfClass:[NSNumber class]]) {
        return [self writeNumber:(NSNumber*)anyValue error:error];
    }
    
    return false;
}

//pragma mark: Public API

+ (BOOL)canPackArray:(nullable NSArray*)array
{
    if (array == nil) {
        return true;
    }
    
    if (![array isKindOfClass:[NSArray class]]) {
        return false;
    }
    
    for (id value in array) {
        if (![BATMessagePackWriter _canWriteAny:value]) {
            return false;
        }
    }
    
    return true;
}

+ (BOOL)canPackDictionary:(nullable NSDictionary<id<NSCopying>, id>*)dictionary
{
    if (dictionary == nil) {
        return true;
    }
    
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return false;
    }
    
    NSArray *keys = [dictionary allKeys];
    
    for (id key in keys) {
        if (key != [NSNull null] &&
            ![key isKindOfClass:[NSString class]] &&
            ![key isKindOfClass:[NSNumber class]]) {
            return false;
        }
        
        if (![BATMessagePackWriter _canWriteAny:dictionary[key]]) {
            return false;
        }
    }
    
    return true;
}

- (void)writeNil
{
    bat_cmp_write_nil(&_msgpackContext);
}

- (void)writeBool:(BOOL)boolean
{
    bat_cmp_write_bool(&_msgpackContext, boolean);
}

- (void)writeInt64:(int64_t)int64
{
    bat_cmp_write_integer(&_msgpackContext, int64);
}

- (void)writeUnsignedInt64:(uint64_t)uint64
{
    bat_cmp_write_uinteger(&_msgpackContext, uint64);
}

- (void)writeInt:(NSInteger)integer
{
    // TODO: check if this works in 32bit without complaining
    // Check if an uppercast also blanks out the memory
    bat_cmp_write_integer(&_msgpackContext, integer);
}

- (void)writeUnsignedInt:(NSUInteger)integer
{
    // TODO: check if this works in 32bit without complaining
    // Check if an uppercast also blanks out the memory
    bat_cmp_write_uinteger(&_msgpackContext, integer);
}

- (void)writeFloat:(float)value
{
    bat_cmp_write_float(&_msgpackContext, value);
}

- (void)writeDouble:(double)value
{
    bat_cmp_write_double(&_msgpackContext, value);
}

- (BOOL)writeNumber:(nullable NSNumber*)number error:(NSError * _Nullable * _Nullable)error
{
    MP_WRITE_AND_SUCCESS_IF_NIL(number)
    
    if (error) {
        *error = nil;
    }
    
    if (number == (void*)kCFBooleanFalse) {
        [self writeBool:false];
        return true;
    }
        
    if (number == (void*)kCFBooleanTrue) {
        [self writeBool:true];
        return true;
    }
    
    switch (CFNumberGetType((CFNumberRef)number)) {
        case kCFNumberSInt8Type:
        case kCFNumberSInt16Type:
        case kCFNumberSInt32Type:
        case kCFNumberSInt64Type:
        case kCFNumberCharType:
        case kCFNumberShortType:
        case kCFNumberIntType:
        case kCFNumberLongType:
        case kCFNumberLongLongType:
            // NSNumber doesn't expose whether a value is signed or unsigned in
            // its CF type. This is only a problem starting INT64_MAX+1, as
            // misreading will return the wrong type, and NSNumber will convert to what
            // we ask it to, meaning that we might get a wrong value.
            // We use objCType to know that: it will return 'Q' if it needs a uint64_t,
            // while it will return 'q' (or something else) if it fits in a smaller type.
            // Alternatively, checking if the number is positive would also work, as the
            // messagepack library will pick the smallest possible type automatically.
            if (strcmp([number objCType], @encode(unsigned long long)) == 0) {
                [self writeUnsignedInt64:[number unsignedLongLongValue]];
            } else {
                [self writeInt64:[number longLongValue]];
            }
            return true;
        case kCFNumberNSIntegerType:
            [self writeInt:[number integerValue]];
            return true;
        case kCFNumberFloatType:
        case kCFNumberFloat32Type:
            [self writeFloat:[number floatValue]];
            return true;
        case kCFNumberDoubleType:
        case kCFNumberFloat64Type:
            [self writeDouble:[number doubleValue]];
            return true;
        case kCFNumberCGFloatType:
#if CGFLOAT_IS_DOUBLE
            [self writeDouble:[number doubleValue]];
#else
            [self writeFloat:[number floatValue]];
#endif
            return true;
        default:
        {
            NSString *errMsg = [NSString stringWithFormat:@"Unpackable NSNumber type %ld (%s)", CFNumberGetType((CFNumberRef)number), [number objCType]];
            MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, errMsg)
        }
    }
}

- (BOOL)writeArraySize:(NSUInteger)size error:(NSError * _Nullable * _Nullable)error
{
    // We could take a uint32_t but we want to handle the burden
    // of checking the array size and erroring properly
    if (size > UINT32_MAX) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"Array is too big to be written")
    }
    if (!bat_cmp_write_array(&_msgpackContext, (uint32_t)size)) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorLibraryFailure, @"Could not write array size")
    }
    return true;
}

- (BOOL)writeArray:(nullable NSArray*)array error:(NSError * _Nullable * _Nullable)error
{
    if (array == nil) {
        if (error) {
            *error = nil;
        }
        [self writeNil];
        return true;
    }
    
    if (![BATMessagePackWriter canPackArray:array]) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"Array is not made of packable values")
    }
    
    if (![self writeArraySize:array.count error:error]) {
        return false;
    }
    
    NSError *writeErr;
    for (id item in array) {
        if (![self _writeAny:item error:&writeErr]) {
            MP_BAIL_ERROR(writeErr.code, [@"Could not write array value: " stringByAppendingString:writeErr.localizedDescription])
        }
    }
    
    return true;
}

- (BOOL)writeDictionarySize:(NSUInteger)size error:(NSError * _Nullable * _Nullable)error
{
    // We could take a uint32_t but we want to handle the burden
    // of checking the map size and erroring properly
    if (size > UINT32_MAX) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"Map is too big to be written")
    }
    if (!bat_cmp_write_map(&_msgpackContext, (uint32_t)size)) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorLibraryFailure, @"Could not write map size")
    }
    return true;
}

- (BOOL)writeDictionary:(nullable NSDictionary<id<NSCopying>, id>*)dictionary error:(NSError * _Nullable * _Nullable)error
{
    if (dictionary == nil) {
        if (error) {
            *error = nil;
        }
        [self writeNil];
        return true;
    }
    
    if (![BATMessagePackWriter canPackDictionary:dictionary]) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"Dictionary is not made of packable keys or values")
    }
    
    NSArray<id<NSCopying>> *keys = [dictionary allKeys];
    
    if (![self writeDictionarySize:dictionary.count error:error]) {
        return false;
    }
    
    NSError *writeErr;
    for (NSString *key in keys) {
        writeErr = nil;
        if (![self _writeAny:key error:&writeErr]) {
            MP_BAIL_ERROR(writeErr.code, [@"Could not write dictionary key: " stringByAppendingString:writeErr.localizedDescription])
        }
        if (![self _writeAny:dictionary[key] error:&writeErr]) {
            MP_BAIL_ERROR(writeErr.code, [@"Could not write dictionary value: " stringByAppendingString:writeErr.localizedDescription])
        }
    }
    
    return true;
}

- (BOOL)writeData:(nullable NSData*)data error:(NSError * _Nullable * _Nullable)error
{
    MP_WRITE_AND_SUCCESS_IF_NIL(data)
    const void* cData = data.bytes;
    size_t length = [data length];
    if (length > UINT32_MAX) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"Data is too big to be written")
    }
    if (!bat_cmp_write_bin(&_msgpackContext, cData, (uint32_t)length)) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorLibraryFailure, @"Could not write data")
    }
    return true;
}

- (BOOL)writeString:(nullable NSString*)string error:(NSError * _Nullable * _Nullable)error
{
    MP_WRITE_AND_SUCCESS_IF_NIL(string)
    const char* cString = [string UTF8String];
    size_t cStringSize = strlen(cString);
    if (cStringSize > UINT32_MAX) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorPrecondition, @"String is too big to be written")
    }
    if (!bat_cmp_write_str(&_msgpackContext, cString, (uint32_t)cStringSize)) {
        MP_BAIL_ERROR(BATMessagePackWriterErrorLibraryFailure, @"Could not write string")
    }
    return true;
}

- (nonnull NSData*)data
{
    return [_data copy];
}

@end
