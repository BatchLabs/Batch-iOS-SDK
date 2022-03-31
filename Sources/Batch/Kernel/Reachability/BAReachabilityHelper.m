//
//  BAReachabilityHelper.m
//  Core
//
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//

#define kBAReachabilityHelperNetworkStatusDidChangeNotification @"reachability.network.statuschanged"

#import <Batch/BANotificationCenter.h>
#import <Batch/BAReachabilityHelper.h>

@interface BAReachabilityHelper () {
   @private
    BAReachability *_reachability;
}

+ (BAReachabilityHelper *)instance;

- (void)startNotifierWithHostName:(NSString *)hostName;

- (void)reachabilityForInternetConnection;

- (void)updateStatus;

- (BANetworkStatus)currentReachabilityStatus;

- (BOOL)isInternetReachable;

@end

@implementation BAReachabilityHelper

#pragma mark -
#pragma mark Public methods

// Start the network observing for an host name.
+ (void)startNotifierWithHostName:(NSString *)hostName {
    [[BAReachabilityHelper instance] startNotifierWithHostName:hostName];
}

// Start the standard network observing.
+ (void)reachabilityForInternetConnection {
    [[BAReachabilityHelper instance] reachabilityForInternetConnection];
}

// Ask for a network status update.
+ (void)updateStatus {
    [[BAReachabilityHelper instance] updateStatus];
}

// Add an observer in the observers list.
+ (void)addObserver:(id)observer selector:(SEL)selector {
    [[BANotificationCenter defaultCenter] addObserver:observer
                                             selector:selector
                                                 name:kBAReachabilityHelperNetworkStatusDidChangeNotification
                                               object:nil];
}

// Remove an observer from the observers list.
+ (void)removeObserver:(id)observer {
    [[BANotificationCenter defaultCenter] removeObserver:observer
                                                    name:kBAReachabilityHelperNetworkStatusDidChangeNotification
                                                  object:nil];
}

// Return the status of the Reachability.
+ (BANetworkStatus)currentReachabilityStatus {
    return [[BAReachabilityHelper instance] currentReachabilityStatus];
}

// Method that will check if the internet is reachable or not.
+ (BOOL)isInternetReachable {
    return [[BAReachabilityHelper instance] isInternetReachable];
}

#pragma mark -
#pragma mark Private methods

+ (BAReachabilityHelper *)instance {
    static BAReachabilityHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAReachabilityHelper alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if ([BANullHelper isNull:self] == NO) {
        _reachability = nil;
    }

    return self;
}

- (void)dealloc {
    [[BANotificationCenter defaultCenter] removeObserver:self];
}

- (void)startNotifierWithHostName:(NSString *)hostName {
    @try {
        _reachability = [BAReachability reachabilityWithHostName:hostName];

        [[BANotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkStatusDidChanged:)
                                                     name:kBAReachabilityChangedNotification
                                                   object:nil];

        [_reachability startNotifier];
    } @catch (NSException *exception) {
        NSLog(@"Error while initializing reachability : %@", [exception description]);
    }
}

- (void)reachabilityForInternetConnection {
    @try {
        _reachability = [BAReachability reachabilityForInternetConnection];

        // Add notifiaction observer, ensure not to have it twice.
        [[BANotificationCenter defaultCenter] removeObserver:self];
        [[BANotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(networkStatusDidChanged:)
                                                     name:kBAReachabilityChangedNotification
                                                   object:nil];

        [_reachability startNotifier];
    } @catch (NSException *exception) {
        NSLog(@"Error while initializing reachability : %@", [exception description]);
    }
}

- (void)updateStatus {
    @try {
        [[BANotificationCenter defaultCenter]
            postNotificationName:kBAReachabilityHelperNetworkStatusDidChangeNotification
                          object:nil
                        userInfo:@{@"status" : [NSNumber numberWithBool:[self isInternetReachable]]}];
    } @catch (NSException *exception) {
        NSLog(@"Error while posting reachability notification : %@", [exception description]);
    }
}

- (void)networkStatusDidChanged:(NSNotification *)notification {
    @try {
        [[BANotificationCenter defaultCenter]
            postNotificationName:kBAReachabilityHelperNetworkStatusDidChangeNotification
                          object:nil
                        userInfo:@{@"status" : [NSNumber numberWithBool:[self isInternetReachable]]}];
    } @catch (NSException *exception) {
        NSLog(@"Error while posting reachability notification:%@, exception: %@", notification,
              [exception description]);
    }
}

- (BANetworkStatus)currentReachabilityStatus {
    return [_reachability currentReachabilityStatus];
}

- (BOOL)isInternetReachable {
    if ([_reachability currentReachabilityStatus] != 0) {
        return YES;
    }

    return NO;
}

@end
