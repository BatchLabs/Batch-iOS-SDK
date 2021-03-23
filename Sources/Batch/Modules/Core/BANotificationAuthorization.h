#import <Foundation/Foundation.h>

#import <Batch/BatchPushPrivate.h>

typedef NS_OPTIONS(NSUInteger, BANotificationAuthorizationTypes)
{
    BANotificationAuthorizationTypesNone                 = 0,
    BANotificationAuthorizationTypesBadge                = 1 << 0,
    BANotificationAuthorizationTypesSound                = 1 << 1,
    BANotificationAuthorizationTypesAlert                = 1 << 2,
    BANotificationAuthorizationTypesLockscreen           = 1 << 3,
    BANotificationAuthorizationTypesNotificationCenter   = 1 << 4,
};

typedef NS_ENUM(NSUInteger, BANotificationAuthorizationStatus) {
    /**
     For iOS versions < 10, which do not support querying the OS
     Not used anymore.
     */
    BANotificationAuthorizationStatusUnsupported = 0,
    
    /**
     "Waiting for value" is the default state, when the OS hasn't called us back yet
     */
    BANotificationAuthorizationStatusWaitingForValue = 1,
    
    /**
     Unknown is for future API compatibilty, when Apple adds states and we didn't
     This happened in iOS 12 with provisional notifications.
     */
    BANotificationAuthorizationStatusUnknown = 2,
    
    /**
     The notification permission has not been requested yet
     */
    BANotificationAuthorizationStatusNotRequested = 3,
    
    /**
     The notification permission has been granted
     */
    BANotificationAuthorizationStatusGranted = 4,
    
    /**
     The notification permission has been deined
     */
    BANotificationAuthorizationStatusDenied = 5,
    
    /**
     The notification permission is granted provisionally (iOS 12+)
     Implies BANotificationAuthorizationStatusNotRequested
     */
    BANotificationAuthorizationStatusProvisional = 6,
};

@interface BANotificationAuthorizationSettings : NSObject

@property BANotificationAuthorizationStatus status;

@property BANotificationAuthorizationTypes types;

@property BatchPushNotificationSettingStatus applicationSetting;

- (nullable NSDictionary*)optionalDictionaryRepresentation;

- (nonnull NSDictionary*)dictionaryRepresentation;

@end

@interface BANotificationAuthorization : NSObject

@property (nonnull) BANotificationAuthorizationSettings *currentSettings;

+ (BatchPushNotificationSettingStatus)applicationSettings;

- (void)setApplicationSettings:(BatchPushNotificationSettingStatus)appSettings skipServerEvent:(BOOL)skipServerEvent;

- (BOOL)shouldFetchSettings;

- (void)fetch:(void(^ _Nullable)(BANotificationAuthorizationSettings* _Nonnull))completionHandler;

- (void)settingsMayHaveChanged;

@end
