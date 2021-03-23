//
//  BAParameter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAParameter.h>
#import <Batch/BAUserDefaults.h>

#import <Batch/BAErrorHelper.h>
#import <Batch/BANullHelper.h>

#import <Batch/BAAESB64Cryptor.h>

#import <Batch/BAOSHelper.h>

// Internal methods and parameters.
@interface BAParameter ()
{
    // Domain protected preferences.
    BAUserDefaults      *_defaults;
    
    // Cached parameters.
    NSMutableDictionary *_cacheParameters;
    
    // Builtin parameters
    NSDictionary *_builtinParameters;
}

// Return the singleton instance
+ (BAParameter *)instance;

// Return the value for a key else fallback.
- (id)objectForKey:(NSString *)key fallback:(id)value;

// Set a value for a key and write it into document Plist if needed.
- (void)setValue:(id<NSCoding>)value forKey:(NSString *)key save:(BOOL)save;

@end

@implementation BAParameter


#pragma mark -
#pragma mark Public methods

// Return the value for the givent key, fallback otherwise.
+ (id)objectForKey:(NSString *)key fallback:(id)fallback
{
    // Test key.
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return fallback;
    }
    
    return [[BAParameter instance] objectForKey:key fallback:fallback];
}

// Return the value for the given key and class, fallback otherwise.
+ (id)objectForKey:(NSString *)key kindOfClass:(Class)class fallback:(id)fallback
{
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return fallback;
    }
    
    id instance = [BAParameter objectForKey:key fallback:nil];
    if (instance == [NSNull null])
    {
        instance = nil;
    }
    
    if (![instance isKindOfClass:class])
    {
        return fallback;
    }
    
    return instance;
}

// Set a value for a key and write it into the domain preferences if needed.
+ (NSError *)setValue:(id)value forKey:(NSString *)key saved:(BOOL)save
{
    // Test value.
    if ([BANullHelper isNull:value] == YES)
    {
        return [NSError errorWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Cannot store a null value."}];
    }
    
    // Test key.
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return [NSError errorWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Cannot store a value with a null or empty key."}];
    }
    
    // Store value.
    [[BAParameter instance] setValue:value forKey:key save:save];
    
    return nil;
}

// Remove the value an the key.
+ (NSError *)removeObjectForKey:(NSString *)key
{
    // Test key.
    if ([BANullHelper isStringEmpty:key] == YES)
    {
        return [NSError errorWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Cannot store a value with a null or empty key."}];
    }
    
    // Remove the key-value.
    [[BAParameter instance] removeObjectForKey:key];
    
    return nil;
}

+ (void)removeAllObjects
{
    [[BAParameter instance] removeAllObjects];
}

#pragma mark -
#pragma mark Singleton

// Return the singleton instance.
+ (BAParameter *)instance
{
    static BAParameter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BAParameter alloc] init];
    });
    return sharedInstance;
}

- (instancetype)initWithSuiteName:(NSString * _Nullable)suiteName
{
    self = [super init];
    if ([BANullHelper isNull:self] == NO)
    {
        // Build defaults.
        BAAESB64Cryptor *cryptor = [[BAAESB64Cryptor alloc] initWithKey:[NSString stringWithFormat:@"%@XpBXC%iH",BAPrivateKeyStorage,58]];
        _defaults = [[BAUserDefaults alloc] initWithCryptor:cryptor andSuiteName:suiteName];
        _builtinParameters = [self builtinParameters];
        _cacheParameters = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithSuiteName:nil];
}

#pragma mark -
#pragma mark Private methods

// Return builtin parameters value (useful when you can't use "fallback" easily)
- (NSDictionary *)builtinParameters
{
    return @{};
}

// Return the value for a key else fallback.
- (id<NSCoding>)objectForKey:(NSString *)key fallback:(id<NSCoding>)value
{
    id<NSCoding> storedValue = nil;
    @synchronized( _cacheParameters )
    {
        storedValue = [_cacheParameters objectForKey:key];
    }
    
    if ([BANullHelper isNull:storedValue] == YES)
    {
        storedValue = [_defaults objectForKey:key];
    }
    
    if ([BANullHelper isNull:storedValue] == YES)
    {
        storedValue = [_builtinParameters objectForKey:key];
    }
    
    if ([BANullHelper isNull:storedValue] == YES)
    {
        storedValue = value;
    }
    
    return storedValue;
}

// Set a value for a key and write it into document Plist if needed.
- (void)setValue:(id<NSCoding>)value forKey:(NSString *)key save:(BOOL)save
{
    if (save == NO)
    {
        @synchronized( _cacheParameters )
        {
            [_cacheParameters setValue:value forKey:key];
        }
    }
    else
    {
        [_defaults setValue:value forKey:key];
    }
}

// Remove the value and the key.
- (void)removeObjectForKey:(NSString *)key
{
    @synchronized( _cacheParameters )
    {
        [_cacheParameters removeObjectForKey:key];
    }

    [_defaults removeObjectForKey:key];
}

- (void)removeAllObjects
{
    @synchronized( _cacheParameters )
    {
        [_cacheParameters removeAllObjects];
        [_defaults removeAllObjects];
    }
}

@end
