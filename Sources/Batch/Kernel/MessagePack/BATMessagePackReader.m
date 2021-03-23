//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BATMessagePackReader.h>
#include "msgpack-c.h" // not #import

#define LOCAL_ERROR_DOMAIN @"BATMessagePackReader"

/// Read the next messagepack object
/// This also nils the error pointer before continuing, as most methods can't rely on a non-nil output to check if an error occurred.
#define MP_READ_OBJECT() MP_READ_OBJECT_OR_RETURN(nil)

#define MP_READ_OBJECT_OR_RETURN(retVal) \
if (error != nil) { *error = nil; }\
bat_cmp_object_t msgpackObj;\
if (![self readObject:&msgpackObj error:error]) { return retVal; }

#define MP_ENFORCE_TYPE(_typeName, _typeInt) \
if (allowNil && msgpackObj.type == BAT_CMP_TYPE_NIL) { \
    if (error != nil) { *error = nil; } \
    return nil; \
} \
if (msgpackObj.type != _typeInt) { \
    if (error != nil) { *error = [self typeMismatchErrorForExpectedType:_typeName]; } \
    return nil; \
}

#define MP_ENFORCE_TYPES(_typeName, _typesCount, ...) \
if (allowNil && msgpackObj.type == BAT_CMP_TYPE_NIL) { \
    if (error != nil) { *error = nil; } \
    return nil; \
} \
if (![self objectType:msgpackObj.type isOfAnyType:_typesCount, __VA_ARGS__]) { \
    if (error != nil) { *error = [self typeMismatchErrorForExpectedType:_typeName]; } \
    return nil; \
}

#define MP_BAIL_ERROR(_code, message) \
if (error != nil) {\
    *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN\
                      code:_code\
                      userInfo:@{NSLocalizedDescriptionKey: message}];\
}\
return nil;

#define MP_BAIL_ERROR_WITH_UNDERLYING(_code, message, _underlyingError) \
if (error != nil) {\
    *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN\
                      code:_code\
                  userInfo:@{NSLocalizedDescriptionKey: message, \
                            NSUnderlyingErrorKey: _underlyingError != nil ? _underlyingError : [self unknownError]}];\
}\
return nil;

#pragma mark Private variables and method declarations
@interface BATMessagePackReader ()
{
    bat_cmp_ctx_t _msgpackContext;
    NSData *_data;
    size_t _offset;
}

- (size_t)_readDataInto:(void *)outData limit:(size_t)limit;
- (BOOL)_skipBytes:(size_t)count;

@end

#pragma mark MessagePack C Bridge

static bool mp_reader_bridge(bat_cmp_ctx_t *ctx, void *data, size_t limit) {
    //buf is actually a pointer to our objc reader
    //the method actually returns a size_t, but we return it as a bool
    //this is how the official cmp example does it, by returning fread's size_t
    return [(__bridge BATMessagePackReader*)ctx->buf _readDataInto:data limit:limit];
}

static bool mp_skipper_bridge(struct bat_cmp_ctx_s *ctx, size_t count) {
    BOOL bytesSkipped = [(__bridge BATMessagePackReader*)ctx->buf _skipBytes:count];
    // mimic fseek's return values, as per the official cmp example
    return bytesSkipped ? 0 : -1;
}

static size_t mp_writer_bridge(bat_cmp_ctx_t *ctx, const void *data, size_t count) {
    return 0;
}

@implementation BATMessagePackReader

#pragma mark Public interface

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _data = data;
        _offset = 0;
        // Use the messagepack context data to store a pointer to our reader
        bat_cmp_init(&_msgpackContext,
                     (__bridge void*)self,
                     mp_reader_bridge,
                     mp_skipper_bridge,
                     mp_writer_bridge);
    }
    return self;
}

- (BOOL)readNilWithError:(NSError **)error
{
    MP_READ_OBJECT_OR_RETURN(false)
    return [self readNil:msgpackObj error:error];
}

- (nullable NSNumber *)readBoolAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readBool:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSNumber *)readIntegerAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readInteger:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSNumber *)readDecimalAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readDecimal:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSString *)readStringAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readString:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSData *)readDataAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readData:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSDictionary *)readDictionaryAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readDictionary:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSNumber *)readDictionaryHeaderWithError:(NSError **)error
{
    MP_READ_OBJECT()
    return [self readDictionaryHeader:msgpackObj error:error];
}

- (nullable NSArray *)readArrayAllowingNil:(BOOL)allowNil error:(NSError * _Nullable * _Nullable)error
{
    MP_READ_OBJECT()
    return [self readArray:msgpackObj error:error allowNil:allowNil];
}

- (nullable NSNumber *)readArrayHeaderWithError:(NSError **)error
{
    MP_READ_OBJECT()
    return [self readArrayHeader:msgpackObj error:error];
}

- (nullable id)readAnyWithError:(NSError **)error {
    MP_READ_OBJECT()

    switch (msgpackObj.type) {
        case BAT_CMP_TYPE_NIL:
        {
            BOOL success = [self readNil:msgpackObj error:error];
            return success ? [NSNull null] : nil;
        }
        case BAT_CMP_TYPE_BOOLEAN:
            return [self readBool:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_BIN8:
        case BAT_CMP_TYPE_BIN16:
        case BAT_CMP_TYPE_BIN32:
            return [self readData:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_FLOAT:
        case BAT_CMP_TYPE_DOUBLE:
            return [self readDecimal:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_POSITIVE_FIXNUM:
        case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
        case BAT_CMP_TYPE_UINT8:
        case BAT_CMP_TYPE_UINT16:
        case BAT_CMP_TYPE_UINT32:
        case BAT_CMP_TYPE_UINT64:
        case BAT_CMP_TYPE_SINT8:
        case BAT_CMP_TYPE_SINT16:
        case BAT_CMP_TYPE_SINT32:
        case BAT_CMP_TYPE_SINT64:
            return [self readInteger:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_FIXSTR:
        case BAT_CMP_TYPE_STR8:
        case BAT_CMP_TYPE_STR16:
        case BAT_CMP_TYPE_STR32:
            return [self readString:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_FIXARRAY:
        case BAT_CMP_TYPE_ARRAY16:
        case BAT_CMP_TYPE_ARRAY32:
            return [self readArray:msgpackObj error:error allowNil:false];
        case BAT_CMP_TYPE_FIXMAP:
        case BAT_CMP_TYPE_MAP16:
        case BAT_CMP_TYPE_MAP32:
            return [self readDictionary:msgpackObj error:error allowNil:false];
    }

    if (error) {
        *error = [self typeNotImplementedError];
    }
    return nil;
}

#pragma mark -
#pragma mark Private methods

- (nonnull NSError*)libraryError
{
    return [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                               code:BATMessagePackReaderErrorLibraryFailure
                           userInfo:@{NSLocalizedDescriptionKey: @"C Messagepack Library error"}];
}

- (nonnull NSError*)unknownError
{
    return [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                               code:BATMessagePackReaderErrorUnknownError
                           userInfo:@{NSLocalizedDescriptionKey: @"Unknown error"}];
}


- (nonnull NSError*)typeNotImplementedError
{
    return [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                               code:BATMessagePackReaderErrorUnsupportedType
                           userInfo:@{NSLocalizedDescriptionKey:@"Type mismatch: underlying library supports the type, but our wrapper does not"}];
}

- (nonnull NSError*)typeMismatchErrorForExpectedType:(NSString*)expectedType
{
    return [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                               code:BATMessagePackReaderErrorTypeMismatch
                           userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Type mismatch: the expected type (%@) doesn't match the read one", expectedType]}];
}

- (BOOL)readObject:(bat_cmp_object_t*)obj error:(NSError **)error
{
    if (!bat_cmp_read_object(&_msgpackContext, obj)) {
        if (error != nil) {
            if (_msgpackContext.error == BATCMP_INVALID_TYPE_ERROR) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:BATMessagePackReaderErrorUnsupportedType
                                         userInfo:@{NSLocalizedDescriptionKey: @"Unable to read object"}];
            } else {
                *error = [self libraryError];
            }
        }
        return false;
    }
    return true;
}

- (BOOL)objectType:(uint8_t)type isOfAnyType:(int)count, ...
{
    va_list args;
    va_start(args, count);
    for (int i = 0; i < count; i++) {
        if (type == va_arg(args, int)) {
            return true;
        }
    }
    return false;
}

#pragma mark Underlying data manipulation

- (size_t)_readDataInto:(void *)outData limit:(size_t)limit
{
    // Fail if too many bytes have been asked
    if (_offset + limit > [_data length]) {
        return 0;
    }
    
    [_data getBytes:outData range:NSMakeRange(_offset, limit)];
    _offset += limit;
    // This method's return value looks like fread
    return limit;
}

- (NSData*)_subDataWithLength:(size_t)length
{
    // Fail if too many bytes have been asked
    if (_offset + length > [_data length]) {
        return nil;
    }
    NSRange range = NSMakeRange(_offset, length);
    _offset += length;
    return [_data subdataWithRange:range];
}

- (BOOL)_skipBytes:(size_t)count
{
    // Fail if too many bytes have been asked
    if (_offset + count > [_data length]) {
        return false;
    }
    
    _offset += count;
    
    return true;
}

#pragma mark MessagePack converters

- (BOOL)readNil:(bat_cmp_object_t)msgpackObj error:(NSError **)error
{
    if (msgpackObj.type != BAT_CMP_TYPE_NIL) {
        if (error != nil) {
            *error = [self typeMismatchErrorForExpectedType:@"nil"];
        }
        return false;
    }
    return true;
}

- (nullable NSNumber *)readBool:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPE(@"bool", BAT_CMP_TYPE_BOOLEAN)
    return @(msgpackObj.as.boolean);
}

- (nullable NSNumber *)readInteger:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"integer", 10,
                     BAT_CMP_TYPE_POSITIVE_FIXNUM,
                     BAT_CMP_TYPE_NEGATIVE_FIXNUM,
                     BAT_CMP_TYPE_UINT8,
                     BAT_CMP_TYPE_UINT16,
                     BAT_CMP_TYPE_UINT32,
                     BAT_CMP_TYPE_UINT64,
                     BAT_CMP_TYPE_SINT8,
                     BAT_CMP_TYPE_SINT16,
                     BAT_CMP_TYPE_SINT32,
                     BAT_CMP_TYPE_SINT64
                     )
    
    NSNumber *outNbr = nil;
    switch (msgpackObj.type) {
        case BAT_CMP_TYPE_POSITIVE_FIXNUM:
        case BAT_CMP_TYPE_UINT8:
            outNbr = @(msgpackObj.as.u8);
            break;
        case BAT_CMP_TYPE_UINT16:
            outNbr = @(msgpackObj.as.u16);
            break;
        case BAT_CMP_TYPE_UINT32:
            outNbr = @(msgpackObj.as.u32);
            break;
        case BAT_CMP_TYPE_UINT64:
            outNbr = @(msgpackObj.as.u64);
            break;
        case BAT_CMP_TYPE_NEGATIVE_FIXNUM:
        case BAT_CMP_TYPE_SINT8:
            outNbr = @(msgpackObj.as.s8);
            break;
        case BAT_CMP_TYPE_SINT16:
            outNbr = @(msgpackObj.as.s16);
            break;
        case BAT_CMP_TYPE_SINT32:
            outNbr = @(msgpackObj.as.s32);
            break;
        case BAT_CMP_TYPE_SINT64:
            outNbr = @(msgpackObj.as.s64);
            break;
    }
    
    if (outNbr == nil) {
        if (error != nil) {
            *error = [self unknownError];
        }
    }
    
    return outNbr;
}

- (nullable NSNumber *)readDecimal:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"decimal", 2,
        BAT_CMP_TYPE_FLOAT,
        BAT_CMP_TYPE_DOUBLE
    )
    
    NSNumber *outNbr = nil;
    switch (msgpackObj.type) {
        case BAT_CMP_TYPE_FLOAT:
            outNbr = @(msgpackObj.as.flt);
            break;
        case BAT_CMP_TYPE_DOUBLE:
            outNbr = @(msgpackObj.as.dbl);
            break;
    }
    
    if (outNbr == nil) {
        if (error != nil) {
            *error = [self unknownError];
        }
    }
    
    return outNbr;
}

- (nullable NSString *)readString:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"string", 4,
        BAT_CMP_TYPE_FIXSTR,
        BAT_CMP_TYPE_STR8,
        BAT_CMP_TYPE_STR16,
        BAT_CMP_TYPE_STR32
    )
    
    uint32_t strLen = msgpackObj.as.str_size;
    
    if (strLen == 0) {
        return @"";
    }
    
    NSData *rawStr = [self _subDataWithLength:strLen];

    if (rawStr == nil) {
        MP_BAIL_ERROR(BATMessagePackReaderErrorMalformedData, @"Invalid string length");
    }

    NSString *outStr = [[NSString alloc] initWithData:rawStr encoding:NSUTF8StringEncoding];
    if (outStr == nil) {
        MP_BAIL_ERROR(BATMessagePackReaderErrorMalformedData, @"Could not decode utf8 string");
    }

    return outStr;
}

- (nullable NSData *)readData:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"data", 3,
        BAT_CMP_TYPE_BIN8,
        BAT_CMP_TYPE_BIN16,
        BAT_CMP_TYPE_BIN32
    )
    
    uint32_t dataLen = msgpackObj.as.bin_size;
    
    if (dataLen == 0) {
        return [NSData data];
    }
    
    NSData *outData = [self _subDataWithLength:dataLen];

    if (outData == nil) {
        MP_BAIL_ERROR(BATMessagePackReaderErrorMalformedData, @"Invalid data length");
    }
    
    return outData;
}

- (nullable NSDictionary *)readDictionary:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"dictionary", 3,
        BAT_CMP_TYPE_FIXMAP,
        BAT_CMP_TYPE_MAP16,
        BAT_CMP_TYPE_MAP32
    )
    
    uint32_t dictionaryLength = msgpackObj.as.map_size;
    NSMutableDictionary *outDict = [[NSMutableDictionary alloc] initWithCapacity:dictionaryLength];
    
    NSError *readError = nil;
    for (uint32_t i = 0; i < dictionaryLength; i++) {
        readError = nil;
        id key = [self readAnyWithError:&readError];
        if (key == nil) {
            MP_BAIL_ERROR_WITH_UNDERLYING(BATMessagePackReaderErrorMalformedData,
                                          @"Unable to decode dictionary key See underlying error for more info.",
                                          readError)
        }
        if (![key conformsToProtocol:@protocol(NSCopying)]) {
            const char* keyClassName = object_getClassName(key);
            NSString *errorDescription = [NSString stringWithFormat:@"Dictionaries keys must conform to NSCopying: only MessagePack strings, numbers and nil are supported. You will have to read this dictionary manually if this is not a mistake. Key vas of type: '%s'", keyClassName];
            MP_BAIL_ERROR(BATMessagePackReaderErrorMalformedData, errorDescription)
        }
        readError = nil;
        id value = [self readAnyWithError:&readError];
        if (value == nil) {
            MP_BAIL_ERROR_WITH_UNDERLYING(BATMessagePackReaderErrorMalformedData,
                                          @"Unable to decode dictionary value. See underlying error for more info.",
                                          readError)
        }
        
        outDict[key] = value;
    }
    
    return outDict;
}

- (nullable NSNumber *)readDictionaryHeader:(bat_cmp_object_t)msgpackObj error:(NSError **)error {
    BOOL allowNil = false; // necessary for the macro
    MP_ENFORCE_TYPES(@"dictionary", 3,
        BAT_CMP_TYPE_FIXMAP,
        BAT_CMP_TYPE_MAP16,
        BAT_CMP_TYPE_MAP32
    )
    return @(msgpackObj.as.map_size);
}

- (nullable NSArray *)readArray:(bat_cmp_object_t)msgpackObj error:(NSError **)error allowNil:(BOOL)allowNil {
    MP_ENFORCE_TYPES(@"array", 3,
        BAT_CMP_TYPE_FIXARRAY,
        BAT_CMP_TYPE_ARRAY16,
        BAT_CMP_TYPE_ARRAY32
    )
    
    uint32_t arrayLength = msgpackObj.as.map_size;
    NSMutableArray *outArray = [[NSMutableArray alloc] initWithCapacity:arrayLength];
    
    NSError *readError = nil;
    for (uint32_t i = 0; i < arrayLength; i++) {
        readError = nil;
        id value = [self readAnyWithError:&readError];
        if (value == nil) {
            MP_BAIL_ERROR_WITH_UNDERLYING(BATMessagePackReaderErrorMalformedData,
                                          @"Unable to decode array value. See underlying error for more info.",
                                          readError)
        }
        
        [outArray addObject:value];
    }
    
    return outArray;
}

- (nullable NSNumber *)readArrayHeader:(bat_cmp_object_t)msgpackObj error:(NSError **)error {
    BOOL allowNil = false; // necessary for the macro
    MP_ENFORCE_TYPES(@"array", 3,
        BAT_CMP_TYPE_FIXARRAY,
        BAT_CMP_TYPE_ARRAY16,
        BAT_CMP_TYPE_ARRAY32
    )
    return @(msgpackObj.as.array_size);
}

@end
