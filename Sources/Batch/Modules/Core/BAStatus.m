//
//  BAStatus.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAStatus.h>

#import <Batch/BAErrorHelper.h>
#import <Batch/BANotificationCenter.h>

#import <Batch/BABundleInfo.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BATrackingAuthorization.h>

// Internal methods and parameters.
@interface BAStatus ()
{
    // Initialization.
    BOOL    _init;
    
    BOOL    _production;
    
    // General start status.
    BOOL    _running;
    
    // Start webservice status.
    BOOL    _startWebservice;
}

@end

@implementation BAStatus

// Set the library in an initialise state.
- (NSError *)initialization
{
    if (_init == YES)
    {
        return [NSError errorWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Library already initialized."}];
    }
    
    _init = YES;
    
    _production = ![BABundleInfo usesAPNSandbox];
    
    _sessionManager = [BASessionManager new];
    
    _notificationAuthorization = [BANotificationAuthorization new];
    
    _trackingAuthorization = [BATrackingAuthorization new];
    
    return nil;
}

// Change the running status into started state.
- (NSError *)start
{
    NSError *e = nil;
    if (_running == YES)
    {
        e = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Batch is already started, restart it again."}];
    }
    
    // Change start state.
    _running = YES;
    
    // Send the notification.
    [[BANotificationCenter defaultCenter] postNotificationName:kNotificationBatchStarts object:nil];
    
    return e;
}

// Change the running status into stoped state.
- (NSError *)stop
{
    NSError *e = nil;
    if (_running == NO)
    {
        e = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Batch is already stopped, stop it again."}];
    }
    
    // Change start state.
    _running = NO;
    
    // Change start webservice status.
    _startWebservice = NO;
    
    // Send the notification.
    [[BANotificationCenter defaultCenter] postNotificationName:kNotificationBatchStops object:nil];
   
    return e;
}

// Gives the running state of the library.
- (BOOL)isRunning
{
    return _running;
}

- (BOOL)isInitialized
{
    return _init;
}

// Force running status. ONLY FOR TESTING
- (void)forceIsRunning:(BOOL)running
{
    _running = running;
}

// Change the start webservice status into started state.
- (NSError *)startWebservice
{
    NSError *e = nil;
    if (_startWebservice == YES)
    {
        e = [[NSError alloc] initWithDomain:ERROR_DOMAIN code:BAInternalFailReasonUnexpectedError userInfo:@{NSLocalizedDescriptionKey: @"Start webservice has already succed."}];
    }
    
    // Change start state.
    _startWebservice = YES;
    
    return e;
}

// Gives the start webservice state.
- (BOOL)hasStartWebservice
{
    return _startWebservice;
}

// Tells if the application is signed like a Production.
- (BOOL)isLikeProduction
{
    return _production;
}

@end
