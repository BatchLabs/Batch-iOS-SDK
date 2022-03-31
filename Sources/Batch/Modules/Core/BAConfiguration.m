//
//  BAConfiguration.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAConfiguration.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BANullHelper.h>
#import <Batch/BAParameter.h>
#import <Batch/BatchLogger.h>

NSString *const kBATConfigurationChangedNotification = @"ConfigurationChangedNotification";

#define kDevelopmentModeKey @"key.dev.mode"

// Internal methods and parameters.
@interface BAConfiguration () {
    // Application developper key.
    NSString *_developperKey;

    // Use IDFA.
    BOOL _idfa;

    // Use advanced device information.
    BOOL _advancedDeviceInformation;

    // Logger delegate.
    __weak id<BatchLoggerDelegate> _loggerDelegate;

    // Universal links associated domains
    NSMutableArray<NSString *> *_associatedDomains;
}

@end

@implementation BAConfiguration

- (instancetype)init {
    self = [super init];
    if ([BANullHelper isNull:self] == YES) {
        return nil;
    }

    // Default use the IDFA.
    _idfa = YES;

    // We allow advanced device information (aka advenced identifiers) by default
    _advancedDeviceInformation = YES;

    return self;
}

#pragma mark -
#pragma mark Public methods

// Set the IDFA use condition.
- (void)setUseIDFA:(BOOL)useIDFA {
    _idfa = useIDFA;
    [[BANotificationCenter defaultCenter] postNotificationName:kBATConfigurationChangedNotification object:nil];
}

// Condition to use the IDFA.
- (BOOL)useIDFA {
    return _idfa;
}

- (void)setUseAdvancedDeviceInformation:(BOOL)use {
    _advancedDeviceInformation = use;
    [[BANotificationCenter defaultCenter] postNotificationName:kBATConfigurationChangedNotification object:nil];
}

- (BOOL)useAdvancedDeviceInformation {
    return _advancedDeviceInformation;
}

// Keep and check the developper key value.
- (NSError *)setDevelopperKey:(NSString *)key {
    // Check developper key.
    if ([BANullHelper isStringEmpty:key] == YES) {
        return [[NSError alloc] initWithDomain:ERROR_DOMAIN
                                          code:BAInternalFailReasonInvalidAPIKey
                                      userInfo:@{NSLocalizedDescriptionKey : @"Empty or void developper key."}];
    }

    // Keep the value.
    _developperKey = [NSString stringWithString:key];

    [[BANotificationCenter defaultCenter] postNotificationName:kBATConfigurationChangedNotification object:nil];

    return nil;
}

// Gives the keept developper key.
- (NSString *)developperKey {
    // Return NULL if not set.
    if (_developperKey == NULL) {
        return NULL;
    }

    // Return a copy of the developper key.
    return [NSString stringWithString:_developperKey];
}

// Get the development mode.
- (BOOL)developmentMode {
    return [self guessDevmodeFromAPIKey];
}

- (void)setLoggerDelegate:(id<BatchLoggerDelegate>)loggerDelegate {
    _loggerDelegate = loggerDelegate;

    [[BANotificationCenter defaultCenter] postNotificationName:kBATConfigurationChangedNotification object:nil];
}

- (id<BatchLoggerDelegate>)loggerDelegate {
    return _loggerDelegate;
}

- (void)setAssociatedDomains:(NSArray<NSString *> *)domains {
    _associatedDomains = [NSMutableArray array];

    for (NSString *domain in domains) {
        NSString *domainTrimmed = [domain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [_associatedDomains addObject:[domainTrimmed lowercaseString]];
    }

    [[BANotificationCenter defaultCenter] postNotificationName:kBATConfigurationChangedNotification object:nil];
}

- (NSArray<NSString *> *)associatedDomains {
    return _associatedDomains;
}

#pragma mark -
#pragma mark Private methods

// Try to guess the development mode from the key.
- (BOOL)guessDevmodeFromAPIKey {
    return [_developperKey hasPrefix:@"DEV"];
}

@end
