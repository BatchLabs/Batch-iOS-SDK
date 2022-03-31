//
//  BAUserDefaults.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAUserDefaults.h>

#import <Batch/BAOSHelper.h>

// Internal methods and parameters.
@interface BAUserDefaults () {
    // Domain protected preferences.
    NSUserDefaults *_defaults;

    // Cryptor.
    id<BAEncryptionProtocol> _cryptor;
}

@end

@implementation BAUserDefaults

#pragma mark -
#pragma mark Public methods

static const NSUInteger DEFAULTS_VERSION = 1;
static const NSString *DEFAULTS_VERSION_KEY = @"com.batch.defaults.version";

// Build the storage.
- (instancetype)initWithCryptor:(id<BAEncryptionProtocol>)cryptor andSuiteName:(NSString *_Nullable)suiteName {
    self = [super init];
    if ([BANullHelper isNull:self] == NO) {
        NSString *actualSuiteName = suiteName;
        if (actualSuiteName == nil) {
            actualSuiteName = BABundleIdentifier;
        }

        _defaults = [[NSUserDefaults alloc] initWithSuiteName:actualSuiteName];

        NSString *version = [_defaults stringForKey:(NSString *)DEFAULTS_VERSION_KEY];
        if ([BANullHelper isStringEmpty:version]) {
            [_defaults setObject:@(DEFAULTS_VERSION) forKey:(NSString *)DEFAULTS_VERSION_KEY];
            [_defaults synchronize];
        }

        // Cryptor can be NULL.
        _cryptor = cryptor;
    }

    return self;
}

- (instancetype)initWithCryptor:(id<BAEncryptionProtocol>)cryptor {
    return [self initWithCryptor:cryptor andSuiteName:nil];
}

// Retrieve the value for the given key.
- (id)objectForKey:(NSString *)key {
    id value = [_defaults objectForKey:key];

    // Treat only strings.
    if ([BANullHelper isStringEmpty:value] == NO) {
        if ([BANullHelper isNull:_cryptor] == NO) {
            value = [_cryptor decrypt:value];
        }
    }

    return value;
}

// Change the value for a given key.
- (void)setValue:(id)value forKey:(NSString *)key {
    // Treat only strings.
    if ([BANullHelper isStringEmpty:value] == NO) {
        if ([BANullHelper isNull:_cryptor] == NO) {
            value = [_cryptor encrypt:value];
        }
    }

    [_defaults setValue:value forKey:key];
    [_defaults synchronize];
}

- (void)removeObjectForKey:(NSString *)key {
    [_defaults removeObjectForKey:key];
    [_defaults synchronize];
}

// Save a custom object implementing NSCoding.
- (void)saveCustomObject:(id)object key:(NSString *)key {
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
    [_defaults setObject:encodedObject forKey:key];
    [_defaults synchronize];
}

// Load a custom object implementing NSCoding.
- (id)loadCustomObjectWithKey:(NSString *)key {
    NSData *encodedObject = [_defaults objectForKey:key];
    id object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];

    return object;
}

- (void)removeAllObjects {
    for (NSString *key in _defaults.dictionaryRepresentation.keyEnumerator) {
        [_defaults removeObjectForKey:key];
    }
    [_defaults synchronize];
}

@end
