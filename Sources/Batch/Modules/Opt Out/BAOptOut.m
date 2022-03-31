#import <Batch/BAOptOut.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BADisplayReceiptCache.h>
#import <Batch/BAInboxDatasourceProtocol.h>
#import <Batch/BAInjection.h>
#import <Batch/BAInstallationID.h>
#import <Batch/BALocalCampaignsCenter.h>
#import <Batch/BALogger.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BAOptOutEventTracker.h>
#import <Batch/BAParameter.h>
#import <Batch/BAPromise.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BAThreading.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BatchCore.h>

NSString *const kBATOptOutChangedNotification = @"batch.optout.changed";
NSString *const kBATOptOutValueKey = @"optout";
NSString *const kBATOptOutWipeDataKey = @"wipe_data";

@implementation BAOptOut {
    BOOL _optedOut;
    BAOptOutEventTracker *_eventTracker;
    NSObject *_lock;
}

+ (BAOptOut *)instance {
    static BAOptOut *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAOptOut alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [NSObject new];
        [self refresh];
    }
    return self;
}

- (void)refresh {
    _optedOut = [self readOptOutFromDisk];
}

- (NSUserDefaults *)userDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:OptOutUserDefaultsSuite];
}

- (void)initEventTrackerIfNeeded {
    @synchronized(_lock) {
        if (!_eventTracker) {
            [self setEventTracker:[BAOptOutEventTracker new]];
        }
    }
}

- (void)setEventTracker:(BAOptOutEventTracker *)eventTracker {
    _eventTracker = eventTracker;
}

- (void)setOptedOut:(BOOL)shouldOptOut
             wipeData:(BOOL)wipeData
    completionHandler:(BatchOptOutNetworkErrorPolicy (^_Nonnull)(BOOL success))completionHandler {
    [self initEventTrackerIfNeeded];

    [BALogger debugForDomain:@"OptOut"
                     message:@"Setting opt-out value: %@, wipe data: %@", shouldOptOut ? @"true" : @"false",
                             wipeData ? @"true" : @"false"];

    if (shouldOptOut != _optedOut) {
        if (shouldOptOut && ![[[BACoreCenter instance] status] isRunning]) {
            [BALogger publicForDomain:nil message:@"Attempting to opt out is not supported when Batch is not started."];
            [BAThreading performBlockOnMainThreadAsync:^{
              completionHandler(false);
            }];
            return;
        }

        // Prepare the operation block. If there is a completion handler, and the user asked for an opt out, wait for
        // the event promise Otherwise, don't wait for it

        BAPromise *waitPromise = nil;
        if (shouldOptOut && wipeData) {
            waitPromise = [_eventTracker track:[BAEvent eventWithName:@"_OPTOUT_WIPE_DATA"
                                                        andParameters:[self makeBaseEventData]]];
        } else if (shouldOptOut) {
            waitPromise = [_eventTracker track:[BAEvent eventWithName:@"_OPTOUT"
                                                        andParameters:[self makeBaseEventData]]];
        }

        if (waitPromise != nil && completionHandler != nil) {
            [BALogger debugForDomain:@"OptOut"
                             message:@"Waiting for server and developer response before optin-out and/or wiping data"];

            [waitPromise then:^(NSObject *_Nullable value) {
              [BAThreading performBlockOnMainThreadAsync:^{
                completionHandler(true);
                [self applyOptOut:shouldOptOut wipeData:wipeData];
              }];
            }];

            [waitPromise catch:^(NSError *_Nullable error) {
              [BAThreading performBlockOnMainThreadAsync:^{
                BatchOptOutNetworkErrorPolicy errorPolicy = completionHandler(false);
                if (errorPolicy == BatchOptOutNetworkErrorPolicyIgnore) {
                    [self applyOptOut:shouldOptOut wipeData:wipeData];
                }
              }];
            }];
        } else {
            [self applyOptOut:shouldOptOut wipeData:wipeData];
        }
    } else if (completionHandler != nil) {
        [BAThreading performBlockOnMainThreadAsync:^{
          completionHandler(false);
        }];
    }
}

- (void)applyOptOut:(BOOL)shouldOptOut wipeData:(BOOL)wipeData {
    _optedOut = shouldOptOut;

    if (shouldOptOut && wipeData) {
        [BALogger debugForDomain:@"OptOut" message:@"Wiping data"];
        [self wipeData];
    }

    [[BANotificationCenter defaultCenter]
        postNotificationName:kBATOptOutChangedNotification
                      object:nil
                    userInfo:@{kBATOptOutValueKey : @(shouldOptOut), kBATOptOutWipeDataKey : @(wipeData)}];

    NSUserDefaults *defaults = [self userDefaults];
    [defaults setObject:@(shouldOptOut) forKey:OptOutDefaultKey];

    [BADisplayReceiptCache saveIsOptOut:shouldOptOut];

    if (!shouldOptOut) {
        [defaults setObject:@(true) forKey:ShouldFireOptinEventDefaultKey];
    }
}

- (NSMutableDictionary *)makeBaseEventData {
    NSMutableDictionary *data = [NSMutableDictionary new];

    data[@"di"] = [[BAPropertiesCenter valueForShortName:@"di"] uppercaseString];
#if BATCH_ENABLE_IDFA
    data[@"idfa"] = [BAPropertiesCenter valueForShortName:@"idfa"];
#endif
    data[@"cus"] = [BAPropertiesCenter valueForShortName:@"cus"];
    data[@"tok"] = [BAPropertiesCenter valueForShortName:@"tok"];

    return data;
}

- (BOOL)isOptedOut {
    return _optedOut;
}

- (void)fireOptInEventIfNeeded {
    NSUserDefaults *defaults = [self userDefaults];

    NSObject *shouldFireOptIn = [defaults objectForKey:ShouldFireOptinEventDefaultKey];
    if ([shouldFireOptIn isKindOfClass:[NSNumber class]]) {
        [defaults removeObjectForKey:ShouldFireOptinEventDefaultKey];
        if ([(NSNumber *)shouldFireOptIn boolValue]) {
            [BATrackerCenter trackPrivateEvent:@"_OPTIN" parameters:[self makeBaseEventData] collapsable:YES];
        }
    }
}

- (BOOL)readOptOutFromDisk {
    NSUserDefaults *defaults = [self userDefaults];

    NSObject *optOut = [defaults objectForKey:OptOutDefaultKey];
    if ([optOut isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)optOut boolValue];
    } else {
        BOOL plistOptOut = false;
        NSObject *infoPlistOptout = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BATCH_OPTED_OUT_BY_DEFAULT"];
        [BALogger
            debugForDomain:@"OptOut"
                   message:@"No opt out value, reading BATCH_OPTED_OUT_BY_DEFAULT from plist: %@", infoPlistOptout];
        if ([infoPlistOptout isKindOfClass:[NSNumber class]]) {
            plistOptOut = [(NSNumber *)infoPlistOptout boolValue];
        }

        [defaults setObject:@(plistOptOut) forKey:OptOutDefaultKey];
        return plistOptOut;
    }
}

- (void)wipeData {
    [BAParameter removeAllObjects];
    [BAInstallationID delete];
    [BALocalCampaignsCenter.instance userDidOptOut];
    [BADisplayReceiptCache removeAll];
    [[BAInjection injectProtocol:@protocol(BAInboxDatasourceProtocol)] clear];
}

@end
