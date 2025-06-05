//
//  BACenterMulticastDelegate.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BACenterMulticastDelegate.h>

#import <Batch/BAActionsCenter.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAEventDispatcherCenter.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUserCenter.h>
#import <Batch/Batch-Swift.h>

@implementation BACenterMulticastDelegate

static NSArray *kPluginsList = nil;

#pragma mark -
#pragma mark Instance methods

+ (void)initialize {
    kPluginsList = @[
        [BACoreCenter class], [BAPushCenter class], [BATrackerCenter class], [BAUserCenter class],
        [BAMessagingCenter class], [BAActionsCenter class], [BALocalCampaignsCenter class],
        [BAEventDispatcherCenter class], [BAProfileCenter class], [BATDataCollectionCenter class]
    ];
}

#pragma mark -
#pragma mark Public methods

// Activate the whole Batch system.
+ (void)startWithAPIKey:(NSString *)key {
    // Setup the logger
    [BALogger setup];

    // Check the delegate.
    if ([BANullHelper isNull:key]) {
        [BALogger publicForDomain:nil message:@"Missing API key for method startWithAPIKey:"];
        return;
    }

    if ([[BAOptOut instance] isOptedOut]) {
        [BALogger publicForDomain:nil message:@"Refusing to start Batch SDK: SDK was opted-out from."];
        return;
    }

    for (id<BACenterProtocol> plugin in kPluginsList) {
        if ([plugin respondsToSelector:@selector(batchWillStart)]) {
            [plugin batchWillStart];
        }
    }

    [BACoreCenter startWithAPIKey:key];

    for (id<BACenterProtocol> plugin in kPluginsList) {
        if ([plugin respondsToSelector:@selector(batchDidStart)]) {
            [plugin batchDidStart];
        }
    }
}
@end
