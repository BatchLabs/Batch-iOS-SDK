//
//  BatchPushPrivate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

// Expose private constructors
// This header is private and should NEVER be distributed within the framework

#import <Batch/BatchPush.h>

/// Remote notification setting status
///
/// See `[BatchPush notificationSettingStatus]` for more information.
typedef NS_ENUM(NSUInteger, BatchPushNotificationSettingStatus) {

    /// User did not make a choice yet. Default value.
    BatchPushNotificationSettingStatusUndefined = 0,

    /// User enabled notifications.
    BatchPushNotificationSettingStatusEnabled = 1,

    /// User disabled notifications.
    BatchPushNotificationSettingStatusDisabled = 2,
};

@interface BatchPush ()

/// This property defines the status of the notification setting (or opt-in/opt-out) in your application.
/// It will be sent to the server, to let Batch know whether a user enabled or disabled notifications globally in your
/// app's settings. You can use it to implement your own "Notifications" setting toggle.

/// This property has a default value of BatchPushNotificationSettingStatusUndefined, and will automatically change to
/// BatchPushNotificationSettingStatusEnabled if you prompt the user to allow notifications using Batch's methods.
/// If you have previously overriden the value to BatchPushNotificationSettingStatusDisabled, the property will not
/// change.

/// - Note: This does NOT reflect the system settings. If the user opted out from iOS' settings, you will still get the
/// original value you set previously here. You will need to handle this case in your settings, and redirect the user to
/// the system settings.
@property (class) BatchPushNotificationSettingStatus notificationSettingStatus;

@end
