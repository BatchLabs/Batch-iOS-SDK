//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BADBGFindMyInstallationHelper.h>
#import <Batch/BatchUser.h>
#import <Batch/BatchLogger.h>
#import <Batch/BATrackerCenter.h>

#define MAX_DELAY_BETWEEN_FOREGROUNDS 20000

#define MIN_FOREGROUND_THRESHOLD 4

static BOOL BADebugEnablesFindMyInstallation = true;

@implementation BADBGFindMyInstallationHelper
{
    
    /// Pasteborard 
    UIPasteboard *_pasteboard;
    
    /// Timestamps when app is foregrounded
    NSMutableArray<NSNumber*>* _timestamps;
}
#pragma mark  - Instance setup

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pasteboard = [UIPasteboard generalPasteboard];
        _timestamps = [NSMutableArray new];
        [self registerObserver];
    }
    return self;
}

- (instancetype)initWithPasteboard:(UIPasteboard*)pasteboard;
{
    self = [super init];
    if (self) {
        _pasteboard = pasteboard;
        _timestamps = [NSMutableArray new];
        [self registerObserver];
    }
    return self;
}

- (void)registerObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Feature control methods

+ (BOOL)enablesFindMyInstallation
{
    return BADebugEnablesFindMyInstallation;
}

+ (void)setEnablesFindMyInstallation:(BOOL)enabled
{
    BADebugEnablesFindMyInstallation = enabled;
}

#pragma mark - Utility methods

/// Notify the app has been foregrounded, we save the current timestamp
- (void)notifyForeground
{
    if (BADebugEnablesFindMyInstallation) {
        NSNumber *timestamp = @(floor([[NSDate date]  timeIntervalSince1970] * 1000));
        [_timestamps addObject: timestamp];
        if ([_timestamps count] >= MIN_FOREGROUND_THRESHOLD) {
            if ([self shouldCopyInstallationID]) {
                // Cleaning all timestamps
                [_timestamps removeAllObjects];
                [self copyInstallationIDToClipboard];
                [BATrackerCenter trackPrivateEvent:@"_FIND_MY_INSTALLATION" parameters:nil];
                [BALogger publicForDomain:@"Debug" message:@"User triggered Find My Installation"];
            } else {
                // Removing older timestamp
                [_timestamps removeObjectAtIndex:0];
            }
        }
    }
}
    

/// Check if we should copy the installation id to the clipboard
- (BOOL)shouldCopyInstallationID
{
    NSMutableArray<NSNumber*>* reversed = [[[_timestamps reverseObjectEnumerator] allObjects] copy];
    for (NSNumber *timestamp in reversed) {
        NSNumber *now = @(floor([[NSDate date]  timeIntervalSince1970] * 1000));
        double delta = [now doubleValue] - [timestamp doubleValue];
        if (delta >= MAX_DELAY_BETWEEN_FOREGROUNDS) {
            return NO;
        }
    }
    return YES;
}


/// Copy the user installation id to the clipboard
- (void)copyInstallationIDToClipboard
{
    [_pasteboard setString:[NSString stringWithFormat:@"Batch Installation ID: %@", [BatchUser installationID]]];
}

@end
