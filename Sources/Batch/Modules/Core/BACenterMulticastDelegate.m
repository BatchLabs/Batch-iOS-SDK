//
//  BACenterMulticastDelegate.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BACenterMulticastDelegate.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BAUserCenter.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAActionsCenter.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BADisplayReceiptCenter.h>
#import <Batch/BAOptOut.h>

@implementation BACenterMulticastDelegate

static NSArray * kPluginsList = nil;

#pragma mark -
#pragma mark Instance methods

+ (void)initialize
{
    kPluginsList = @[[BACoreCenter class], [BAPushCenter class], [BATrackerCenter class], [BAUserCenter class], [BAMessagingCenter class], [BAActionsCenter class], [BALocalCampaignsCenter class], [BAEventDispatcherCenter class], [BADisplayReceiptCenter class]];
}


#pragma mark -
#pragma mark Public methods

// Activate the whole Batch system.
+ (void)startWithAPIKey:(NSString *)key
{
    // Setup the logger
    [BALogger setup];
    
    // Check the delegate.
    if ([BANullHelper isNull:key])
    {
        [BALogger publicForDomain:nil message:@"Missing API key for method startWithAPIKey:"];
        return;
    }
    
    if ([[BAOptOut instance] isOptedOut])
    {
        [BALogger publicForDomain:nil message:@"Refusing to start Batch SDK: SDK was opted-out from."];
        return;
    }
    
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(batchWillStart)])
        {
            [plugin batchWillStart];
        }
    }
    
    [BACoreCenter startWithAPIKey:key];
    
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(batchDidStart)])
        {
            [plugin batchDidStart];
        }
    }
}

// Give the URL to Batch systems.
+ (BOOL)handleURL:(NSURL *)url
{
    if (!url)
    {
        return NO;
    }
    
    BOOL hasHandled = NO;
    
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(handleURL:)])
        {
            hasHandled |= [plugin handleURL:url];
        }
    }
    
    return hasHandled;
}

// Set the custom user identifier to Batch, you should use this method if you have your own login system.
+ (void)setCustomUserIdentifier:(NSString *)identifier
{
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(setCustomUserIdentifier:)])
        {
            [plugin setCustomUserIdentifier:identifier];
        }
    }
}

// Set if Batch can try to use IDFA (default = YES)
+ (void)setUseIDFA:(BOOL)use
{
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(setUseIDFA:)])
        {
            [plugin setUseIDFA:use];
        }
    }
}

+ (void)setUseAdvancedDeviceInformation:(BOOL)use
{
    for (id<BACenterProtocol> plugin in kPluginsList)
    {
        if ([plugin respondsToSelector:@selector(setUseAdvancedDeviceInformation:)])
        {
            [plugin setUseAdvancedDeviceInformation:use];
        }
    }
}

@end
