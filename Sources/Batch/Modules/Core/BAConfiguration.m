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

    // Logger delegate.
    __weak id<BatchLoggerDelegate> _loggerDelegate;

    // Universal links associated domains
    NSMutableArray<NSString *> *_associatedDomains;

    // Migrations related configuration
    BatchMigration _disabledMigrations;
}

@end

@implementation BAConfiguration

- (instancetype)init {
    self = [super init];
    if ([BANullHelper isNull:self] == YES) {
        return nil;
    }
    return self;
}

#pragma mark -
#pragma mark Public methods

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

- (void)setDisabledMigrations:(BatchMigration)migrations {
    _disabledMigrations = migrations;
}

- (Boolean)isMigrationDisabledFor:(BatchMigration)migration {
    return _disabledMigrations & migration;
}

@end
