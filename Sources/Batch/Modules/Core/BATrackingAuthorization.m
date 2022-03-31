//
//  BATrackingAuthorization.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BATrackingAuthorization.h"

#import <Batch/BAConfiguration.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BANotificationCenter.h>
#import <Batch/BATrackerCenter.h>

#if !TARGET_OS_MACCATALYST
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif

@implementation BATrackingAuthorization {
    NSUUID *_zeroUUID;
    NSUUID *_previousTrackingId;
    BATrackingAuthorizationStatus _previousAuthorizationStatus;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _zeroUUID = [[NSUUID alloc] initWithUUIDBytes:(uuid_t){0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                                               0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}];

        _previousTrackingId = [self attributionIdentifier];
        _previousAuthorizationStatus = [self trackingAuthorizationStatus];

        [[BANotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(settingsMayHaveChanged)
                                                     name:kBATConfigurationChangedNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)applicationDidBecomeActive {
    [self settingsMayHaveChanged];
}

- (void)settingsMayHaveChanged {
    NSUUID *newTrackingId = [self attributionIdentifier];
    BATrackingAuthorizationStatus newAuthorizationStatus = [self trackingAuthorizationStatus];
    if (_previousAuthorizationStatus != newAuthorizationStatus || ![self uuidMatchesPrevious:newTrackingId]) {
        _previousTrackingId = newTrackingId;
        _previousAuthorizationStatus = newAuthorizationStatus;
        [self trackingStatusChanged];
    }
}

- (void)trackingStatusChanged {
    [BATrackerCenter trackPrivateEvent:@"_TRACKING_STATUS_CHANGE"
                            parameters:[self statusDictionaryRepresentation]
                           collapsable:true];
}

- (BOOL)uuidMatchesPrevious:(NSUUID *)newUUID {
    if (newUUID == _previousTrackingId) {
        // Handles nil
        return true;
    }
    return [_previousTrackingId isEqual:newUUID];
}

// This method returns the IDFA, except if:
// - It's disabled in the config
// - the UUID is zeroed out
// - We don't compile support for it
- (NSUUID *)attributionIdentifier {
#if BATCH_ENABLE_IDFA

    if (![[BACoreCenter instance].configuration useIDFA]) {
        return nil;
    }

#if !TARGET_OS_MACCATALYST
    if (@available(iOS 14.5, *)) {
        if (ATTrackingManager.trackingAuthorizationStatus != ATTrackingManagerAuthorizationStatusAuthorized) {
            [BALogger debugForDomain:@"TAth" message:@"Skipping attribution identifier, disallowed by ATT."];
            return nil;
        }
    }
#endif

    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Id%@", @"advertising", @"entifier"]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class class = NSClassFromString([NSString stringWithFormat:@"%@Ma%@", @"ASIdentifier", @"nager"]);
    if (class != nil) {
        if ([class respondsToSelector:NSSelectorFromString(@"sharedManager")] == YES) {
            id manager = [class performSelector:NSSelectorFromString(@"sharedManager")];
            if (manager != nil) {
                if ([manager respondsToSelector:selector] == YES) {
                    NSUUID *uuid = [manager performSelector:selector];
                    // Filter out iOS 10+'s zeroed uuid in case of limited ad tracking
                    if ([uuid isEqual:_zeroUUID]) {
                        return nil;
                    }
                    return uuid;
                }
            }
        }
    }
#pragma clang diagnostic pop

    return nil;

#else

    return nil;

#endif
}

- (nonnull NSDictionary *)statusDictionaryRepresentation {
    id attributionID = [[self attributionIdentifier] UUIDString];
    if (attributionID == nil) {
        attributionID = [NSNull null];
    }
    return @{@"attid" : attributionID, @"tath" : @([self trackingAuthorizationStatus])};
}

- (BATrackingAuthorizationStatus)trackingAuthorizationStatus {
    // Even if Batch has no IDFA support compiled in, returning the tracking status
    // has some use cases, so do not remove support for it

    if (![[BACoreCenter instance].configuration useIDFA]) {
        return BATrackingAuthorizationStatusForbiddenByBatchConfig;
    }

#if !TARGET_OS_MACCATALYST
    if (@available(iOS 14.0, *)) {
        switch (ATTrackingManager.trackingAuthorizationStatus) {
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                return BATrackingAuthorizationStatusNotDetermined;
            case ATTrackingManagerAuthorizationStatusDenied:
                return BATrackingAuthorizationStatusDenied;
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return BATrackingAuthorizationStatusAuthorized;
            case ATTrackingManagerAuthorizationStatusRestricted:
                return BATrackingAuthorizationStatusRestricted;
            default:
                return BATrackingAuthorizationStatusUnknown;
        }
    }
#endif

    return [self legacyAuthorizationStatus];
}

- (BATrackingAuthorizationStatus)legacyAuthorizationStatus {
#if BATCH_ENABLE_IDFA

    // This always returns false on iOS 14+, don't use this method on this OS.
    SEL selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class class = NSClassFromString([NSString stringWithFormat:@"%@Ma%@", @"ASIdentifier", @"nager"]);
    if (class != nil) {
        if ([class respondsToSelector:NSSelectorFromString(@"sharedManager")] == YES) {
            id manager = [class performSelector:NSSelectorFromString(@"sharedManager")];
            if (manager != nil) {
                if ([manager respondsToSelector:selector] == YES) {
                    NSInvocation *invocation = [NSInvocation
                        invocationWithMethodSignature:[class instanceMethodSignatureForSelector:selector]];
                    [invocation setSelector:selector];
                    [invocation setTarget:manager];
                    [invocation invoke];
                    BOOL isTrackingEnabled = false;
                    [invocation getReturnValue:&isTrackingEnabled];
                    return isTrackingEnabled ? BATrackingAuthorizationStatusAuthorized
                                             : BATrackingAuthorizationStatusDenied;
                }
            }
        }
    }
#pragma clang diagnostic pop

    return BATrackingAuthorizationStatusAuthorized;

#else

    // If we didn't compile IDFA support, return Unknown: we do not want to invoke ASIdentifierManager at all
    // but we do not want to always return "denied" either

    return BATrackingAuthorizationStatusUnknown;
#endif
}

@end
