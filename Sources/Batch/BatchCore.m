//
//  BatchCore.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BatchCore.h>
#import <Batch/BatchUserProfile.h>

#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BADBGFindMyInstallationHelper.h>
#import <Batch/BADBGModule.h>
#import <Batch/BAOptOut.h>
#import <Batch/BATrackerCenter.h>

@implementation Batch

// Activate the whole Batch system.
+ (void)startWithAPIKey:(NSString *)key {
    [BACenterMulticastDelegate startWithAPIKey:key];
}

// Give the URL to Batch systems.
+ (BOOL)handleURL:(NSURL *)url {
    return [BACenterMulticastDelegate handleURL:url];
}

// Test if Batch is running in development mode.
+ (BOOL)isRunningInDevelopmentMode {
    return [BACoreCenter isRunningInDevelopmentMode];
}

+ (BatchUserProfile *)defaultUserProfile {
    static BatchUserProfile *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BatchUserProfile alloc] init];
    });

    return sharedInstance;
}

// Set if Batch can try to use IDFA. Deprecated.
+ (void)setUseIDFA:(BOOL)use {
    [BALogger publicForDomain:nil message:@"Ignoring 'setUseIDFA' API call: Batch has removed support for IDFA."];
}

+ (void)setLoggerDelegate:(id<BatchLoggerDelegate>)loggerDelegate {
    [[[BACoreCenter instance] configuration] setLoggerDelegate:loggerDelegate];
}

+ (void)setUseAdvancedDeviceInformation:(BOOL)use {
    [BACenterMulticastDelegate setUseAdvancedDeviceInformation:use];
}

+ (UIViewController *)debugViewController {
    return [BADBGModule debugViewController];
}

+ (void)setInternalLogsEnabled:(BOOL)enableInternalLogs {
    [BALogger setInternalLogsEnabled:enableInternalLogs];
}

+ (void)optOut {
    [[BAOptOut instance] setOptedOut:true
                            wipeData:false
                   completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
                     return BatchOptOutNetworkErrorPolicyIgnore;
                   }];
}

+ (void)optOutAndWipeData {
    [[BAOptOut instance] setOptedOut:true
                            wipeData:true
                   completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
                     return BatchOptOutNetworkErrorPolicyIgnore;
                   }];
}

+ (void)optOutWithCompletionHandler:(BatchOptOutNetworkErrorPolicy (^_Nonnull)(BOOL success))handler {
    [[BAOptOut instance] setOptedOut:true wipeData:false completionHandler:handler];
}

+ (void)optOutAndWipeDataWithCompletionHandler:(BatchOptOutNetworkErrorPolicy (^_Nonnull)(BOOL success))handler {
    [[BAOptOut instance] setOptedOut:true wipeData:true completionHandler:handler];
}

+ (void)optIn {
    [[BAOptOut instance] setOptedOut:false
                            wipeData:false
                   completionHandler:^BatchOptOutNetworkErrorPolicy(BOOL success) {
                     return BatchOptOutNetworkErrorPolicyIgnore;
                   }];
}

+ (BOOL)isOptedOut {
    return [[BAOptOut instance] isOptedOut];
}

+ (void)setAssociatedDomains:(NSArray<NSString *> *_Nonnull)domains {
    [[[BACoreCenter instance] configuration] setAssociatedDomains:domains];
}

+ (id<BatchDeeplinkDelegate>)deeplinkDelegate {
    return [[BACoreCenter instance] configuration].deeplinkDelegate;
}

+ (void)setDeeplinkDelegate:(id<BatchDeeplinkDelegate>)deeplinkDelegate {
    [[BACoreCenter instance] configuration].deeplinkDelegate = deeplinkDelegate;
}

+ (BOOL)enablesFindMyInstallation {
    return [BADBGFindMyInstallationHelper enablesFindMyInstallation];
}

+ (void)setEnablesFindMyInstallation:(BOOL)enablesFindMyInstallation {
    [BADBGFindMyInstallationHelper setEnablesFindMyInstallation:enablesFindMyInstallation];
}

@end
