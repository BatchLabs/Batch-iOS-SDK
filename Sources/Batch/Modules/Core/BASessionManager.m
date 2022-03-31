//
//  BASessionManager.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BASessionManager.h>

#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUptimeProvider.h>

#define LOCAL_LOGGER_DOMAIN @"SessionManager"

#define NEW_SESSION_BACKGROUND_THREASHOLD_SEC 300

NSString *const BATNewSessionStartedNotification = @"NewSessionStarted";

@implementation BASessionManager {
    BOOL _activeSession;
    NSTimeInterval _lastBackgroundUptime;
}

#pragma mark Instance setup

- (instancetype)init {
    self = [super init];
    if (self) {
        _activeSession = false;
        _lastBackgroundUptime = 0;

        [self registerObservers];
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
            [self startNewSession];
        }
    }
    return self;
}

- (void)registerObservers {
    NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
    [c addObserver:self
          selector:@selector(applicationWillEnterForeground)
              name:UIApplicationWillEnterForegroundNotification
            object:nil];

    [c addObserver:self
          selector:@selector(applicationDidEnterBackground)
              name:UIApplicationDidEnterBackgroundNotification
            object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Utility methods

- (void)startNewSession {
    if (_activeSession) {
        [BALogger debugForDomain:@"SessionManager"
                         message:@"Refusing to start a new session, since no backgrounding was detected"];
        [BALogger
            debugForDomain:@"SessionManager"
                   message:
                       @"This can happen in some situations (such as app first launch). Previous uptime %f, actual %f",
                       _lastBackgroundUptime, [BAUptimeProvider uptime]];
        return;
    }

    _activeSession = YES;
    _sessionID = [[NSUUID UUID] UUIDString];
    [BALogger debugForDomain:@"SessionManager" message:@"New session started. ID: '%@'", _sessionID];
    [[BANotificationCenter defaultCenter] postNotificationName:BATNewSessionStartedNotification object:nil];
    [[[BALocalCampaignsCenter instance] viewTracker] resetSessionViewsCount];

    // TODO: re-enable this [ch13776]
    //[BATrackerCenter trackPrivateEvent:@"_NEW_SESSION"
    //                         parameters:@{@"session": _sessionID}];
}

- (BOOL)shouldStartNewSession {
    if (_lastBackgroundUptime <= 0) {
        return true;
    }

    return ([BAUptimeProvider uptime] - _lastBackgroundUptime) >= NEW_SESSION_BACKGROUND_THREASHOLD_SEC;
}

#pragma mark Lifecycle events

- (void)applicationDidEnterBackground {
    _activeSession = false;
    _lastBackgroundUptime = [BAUptimeProvider uptime];
}

- (void)applicationWillEnterForeground {
    if ([self shouldStartNewSession]) {
        [self startNewSession];
    }
}

@end
