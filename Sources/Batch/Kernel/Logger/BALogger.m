//
//  BALogger.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BALogger.h>
#import <Batch/BAOSHelper.h>
#import <Batch/BANullHelper.h>
#import "Defined.h"
#import <Batch/BALoggerUnified.h>

#import <os/log.h>

NSString *const kBATLoggerEnableInternalArgument = @"-BatchSDKEnableInternalLogs";

static BOOL BATLoggerInternalForceEnable = false;

__weak static id <BALoggerDelegateSource> BALoggerDelegateSource;

@implementation BALogger

#pragma mark -
#pragma mark Public methods

// Log the message using a public tag.
+ (void)publicForDomain:(NSString *)name message:(NSString *)formatstring,...
{
    va_list arglist;
    va_start(arglist, formatstring);
    NSString *statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
    va_end(arglist);
    
    [BALogger logMessage:statement domain:name internal:false];
}

// Log the message using an error tag.
+ (void)errorForDomain:(NSString *)name message:(NSString *)formatstring,...
{
    if (BATLoggerInternalForceEnable)
    {
        va_list arglist;
        va_start(arglist, formatstring);
        NSString *statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
        va_end(arglist);
        
        [BALogger logMessage:statement domain:name internal:true];
    }
}

// Log the message using a warning tag.
+ (void)warningForDomain:(NSString *)name message:(NSString *)formatstring,...
{
    if (BATLoggerInternalForceEnable)
    {
        va_list arglist;
        va_start(arglist, formatstring);
        NSString *statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
        va_end(arglist);
        
        [BALogger logMessage:statement domain:name internal:true];
    }
}

// Log the message using a debug tag.
+ (void)debugForDomain:(NSString *)name message:(NSString *)formatstring,...
{
    if (BATLoggerInternalForceEnable)
    {
        va_list arglist;
        va_start(arglist, formatstring);
        NSString *statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
        va_end(arglist);
        
        [BALogger logMessage:statement domain:name internal:true];
    }
}

+ (void)setup
{
    // Add a dispatch_once if this method does more work at some point
    // This might break the tests, so expect having some refactoring to do.
    
    // Check if there is a process argument to enable Batch Internal Logs
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    if ([arguments containsObject:kBATLoggerEnableInternalArgument]) {
        BATLoggerInternalForceEnable = true;
    }
}

#pragma mark - Swift only methods

+ (void)__SWIFT_publicForDomain:(nullable NSString *)domain message:(NSString *)message
{
    [self publicForDomain:domain message:@"%@", message];
}

+ (void)__SWIFT_errorForDomain:(nullable NSString *)domain message:(NSString *)message
{
    [self errorForDomain:domain message:@"%@", message];
}

+ (void)__SWIFT_warningForDomain:(nullable NSString *)domain message:(NSString *)message
{
    [self warningForDomain:domain message:@"%@", message];
}

+ (void)__SWIFT_debugForDomain:(nullable NSString *)domain message:(NSString *)message
{
    [self warningForDomain:domain message:@"%@", message];
}

#pragma mark - Internal log control

+ (BOOL)internalLogsEnabled
{
    return BATLoggerInternalForceEnable;
}

+ (void)setInternalLogsEnabled:(BOOL)internalLogsEnabled
{
    BATLoggerInternalForceEnable = internalLogsEnabled;
}

#pragma mark -
#pragma mark Private methods

+ (id<BALoggerProtocol>)sharedLogger
{
    static id<BALoggerProtocol> logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [BALoggerUnified new];
    });
    return logger;
}

+ (void)enableInternalLogs __attribute__((deprecated("Use setEnableInternalLogs")))
{
    BATLoggerInternalForceEnable = true;
}

+ (void)disableInternalLogs __attribute__((deprecated("Use setEnableInternalLogs")))
{
    BATLoggerInternalForceEnable = false;
}

+ (void)setLoggerDelegateSource:(id <BALoggerDelegateSource>)delegateSource
{
    BALoggerDelegateSource = delegateSource;
}

+ (void)setEnableInternalLogs:(BOOL)enableInternalLogs
{
    BATLoggerInternalForceEnable = enableInternalLogs;
}

// Private method that do the NSLog().
+ (void)logMessage:(NSString *)message domain:(NSString *)domain internal:(BOOL)internal
{
    if ([BANullHelper isNull:message] == YES)
    {
        return;
    }
    
    if ([BANullHelper isStringEmpty:domain] == YES)
    {
        domain = @"";
    }
    else
    {
        domain = [NSString stringWithFormat:@"%@ - ",domain];
    }
    
    [[BALogger sharedLogger] logMessage:message subsystem:domain internal:internal];
    
    [BALoggerDelegateSource.loggerDelegate logWithMessage:[NSString stringWithFormat:@"[%@] - %@%@", internal ? @"Batch-Internal" : @"Batch", domain, message]];
}

@end
