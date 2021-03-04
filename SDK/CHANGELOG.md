CHANGELOG
=========

1.17.0
---

*Compiled with Xcode 12.4*  
**Batch requires Xcode 12 and iOS 10.0 or higher**  

**Core**

* Added the ability to enable Batch's internal logging using `[Batch setInternalLogsEnabled:true]`. They can also be enabled using the `-BatchSDKEnableInternalLogs` process argument.  
  Internal logs should be disabled when submitting your app to the App Store.
* Added nullability annotations to `BatchLoggerDelegate`. This might trigger a warning in your Swift code.

**Actions**

* Add a "copy to clipboard" builtin action (`batch.clipboard`).
* Add a "rate app" builtin action (`batch.rating`). Requires iOS 10.3 or higher.

**Messaging**

* Added support for a new UI format: WebView. See documentation for more info.
* Added `batchMessageWasCancelledByError:` to `BatchMessagingDelegate`, called when a message could not be loaded due to an error when loading the message's content.
* Added `batchWebViewMessageDidTriggerAction:messageIdentifier:analyticsIdentifier:` to `BatchMessagingDelegate`, called when a message could not be loaded due to an error when loading the message's content.
* Modal formats can now be closed with the escape key
* Fix a bug where cached in-app campaigns might not be deleted when all campaigns were disabled
* In-App campaign cache is now cleared on server errors
* Fix an issue where the statusbar color would not be applied

**Event Dispatchers**
* Added the new event types `BatchEventDispatcherTypeMessagingCloseError` and `BatchEventDispatcherTypeMessagingWebViewClick`.

**Push**

* Notification opens, deeplinks and mobile landings are now working when notifications aren't displayed in the foreground (`willShowSystemForegroundAlert: false`).

**Inbox**

* `[BatchInbox fetcherForUserIdentifier:authenticationKey:]` now returns a nil instance if "userIdentifier" is nil.

1.16.0
---

A migration guide from Batch 1.15 and lower is [available here](https://doc.batch.com/ios/advanced/1_16-migration).

**BREAKING:**
**This version drops support for iOS 8 and 9**
**Batch requires Xcode 12 and iOS 10.0 or higher**

Batch now depends on libz. This might require a change in your project:  
* Cocoapods:
  The podspec has been updated to add the required linker flag. No action is needed.
* Carthage/Manual integration:
  When building, Xcode should automatically link your project with libz. If you get a compilation error, add `-lz` to your linker flags, or add `libz` to "Frameworks and Libraries" in your app's target.

**Batch and Apple Silicon**  
In order to support Apple Silicon, Batch will adopt the XCFramework format: it is not possible to support the iOS Simulator on Apple Silicon macs in a "fat" framework.
What it means for you:
 - Cocoapods users will be migrated to the XCFramework automatically
 - Carthage users will stay on the old distribution style until Carthage supports XCFrameworks.
 - Manual integrations should update to XCFramework as soon as possible. Batch will be distributed in both formats for a couple of versions.

Note that the `armv7s` slice is not included in the XCFramework distribution.

**BatchExtension**

BatchExtension isn't distributed with the SDK zip anymore. It will be released on github soon after this release.

**Core**

* Batch is now compatible with iOS 14's tracking consent and IDFA changes.
* Added UIScene support. If your application uses it, you must add an `UNUserNotificationCenterDelegate`, otherwise Direct Opens, Deeplinks and Mobile Landings will not work: UIScene disables legacy push application delegate methods.
* eSIMs are now supported. Phones that only have an eSIM will now properly report back their carrier, if the feature hasn't been disabled.
* More nullability annotations have been added. As those annotations match Apple's own, we do not expect source compatibility to break.
* Support for TLS versions older than 1.2 has been removed.
* Added a new builtin action named `batch.ios_tracking_consent`, which requests tracking consent via AppTrackingTransparency. More info in the documentation. 

**Event Dispatchers**

* `BatchEventDispatcherTypeNotificationOpen` is no longer broadcasted when the application is processing a background push.

**Inbox**

* Enhanced the way the SDK fetchs notifications from the servers to greatly reduce bandwidth usage. No public API change.

**Push**

* Add a new method `BatchPush.isBatchPush` to check if a received push comes from Batch.
* Added `BatchUNUserNotificationCenterDelegate`, an UNUserNotificationCenterDelegate implementation that forwards events for Batch. Call `BatchUNUserNotificationCenterDelegate.register()` to automatically set it as your delegate.
  BatchUNUserNotificationCenterDelegate can display notifications when your app is in the foreground using the `showForegroundNotifications` property.
* Batch will now emit a warning in the console when your app does not register an `UNUserNotificationCenterDelegate` by the time `application:didFinishLaunchingWithOptions:` returns. Implementing this delegate improves Batch's handling of various features that rely on notification interaction feedback, such as analytics or deeplinks: it is strongly recommended that you implement it if you don't already.
* Batch now emits the `BatchPushOpenedNotification` NSNotification when a notification has been opened by the user. This deprecates BatchPushReceivedNotification: see `BatchPush.h` for more info.
* In automatic mode, `application:didReceiveRemoteNotification:fetchCompletionHandler:`'s completion handler is no longer called on your behalf when a deeplink is opened.

**Messaging**

* The "modal" format now correctly triggers actions after it has been dismissed. This will have an impact on when the custom actions are executed, making them more consistent with the Fullscreen format.
* This fixes an issue where deeplinks could not be opened in the application using SFSafariViewController with modal formats.
* The image format is now properly sized when in a freeform window (iPad in Split View, Catalyst)
* Fix a rare race condition with the interstitial format where it would fail to layout properly when the image server could not be reached.
* Modally presented messages will not be allowed to be dismissed unless they're the frontmost view controller. This fix an issue where a message with an autodismiss might dismiss a view controller presented on top of it.
* Improved dismissal logic. While automatic dismissal may fail in some rare occasions due to iOS refusing to dismiss a modal view controller when one is animating, it will not prevent the user from manually dismissing the view anymore.

**User**

* Added new strongly typed methods for setting attributes on BatchUserDataEditor. They greatly enhance Swift usage of the API. See `setBooleanAttribute:forKey:error` and similar methods (`set(attribute: Bool, forKey: String)` in Swift).
 - Those new methods return validation errors: you can now know if your attribute key/value does not pass validation and will be discarded.
 - nil values are not supported in the new methods. Use `removeAttributeForKey:` explicitly.

**Debug**

* Clicking the "share" buttons in the debug views no longer crash on iPads.

1.15.2
---

Compiled with Xcode 11.5
This minor release is the last one to support iOS 8 and 9.

**Event Dispatcher**

* Fix an issue where event dispatchers might not be called.

**User**

* Fix an issue where events that had not been sent to the server would be lost when the app's process was killed.


1.15.1
---

Compiled with Xcode 11.5

**User**

* Added support for Date in BatchEventData.
* BatchEventData now supports up to 15 attributes (from 10).

1.15.0
---

Compiled with Xcode 11.3.1

**This is the LAST release that support iOS 8 and 9. Future releases will require iOS 10+**

**Core**

* Changed how notification status is reported: The SDK will now tell Batch's servers that notifications are enabled if :
 - The app has requested and holds a provisional authorization.
 - The user has disabled banners but kept lockscreen or notification center delivery enabled.
* Added support for external analytics using `BatchEventDispatcher`. See the documentation for more details.

**Messaging**

* New enum property `BatchMessagingContentType contentType` on class `BatchInAppMessage` to help cast to the right content class.
* A new optional delegate method `BatchMessagingDelegate.presentingViewControllerForBatchUI` allows to specify which view controller to display Batch messages on.
* Fixed an issue where the last line of a label could be cut.
* Improved accessibility of all message formats

**Inbox**

* Added the `markNotificationAsDeleted:` method on `BatchInboxFetcher`, allowing the deletion of notifications

1.14.2
---
This release has been built using Xcode 11.1.

**Messaging**

* Fix an issue where mobile landings might fail to be shown after opening a push for a backgrounded app on iOS 13
* Fix an issue where BatchDeeplinkDelegate does not fire  in certain conditions when opening a push from the lockscreen
* Fix an issue where banners would move more than expected when swiping on them on iOS 13

1.14.1
---

This release officially supports iOS 13.
It has been built using **and requires** Xcode 11.0 GM 2.

**This is the LAST release that support iOS 8 and 9. Apple has already removed their simulators from Xcode 11.**  

**Messaging**
* Add UIScene support
* Add an analytics event for iOS 13's modal swipe-to-dismiss

1.14.0
---

**Core**

* Bug fix: deeplinks from actions are properly sent to Deeplink delegate method
* Fixed an issue where the server-side GDPR wipe event was not sent properly
* Fixed an issue where the Installation ID may not be wiped properly after a GDPR wipe

**User**

* High level data (language/region/custom user id) can now be read back.
* User data (attributes and tags) can now be read back. [Documentation](https://batch.com/doc/ios/custom-data/custom-attributes.html#_reading-attributes-and-tag-collections)

**Messaging**
* Added support for two new UI formats: Modal, and Image. See the documentation for more information.
* Added support for GIFs in Mobile Landings and In-App messages
* Added support for rich text.
* Added support for text scrolling in all formats. Banners will now have a maximum body height of ~160pt, and their text will scroll.

* Deeplinks can now be open directly in the app using a SFSafariViewController for Push Notifications, Mobile Landings and In-App Mesasges  
* Added new methods on the messaging delegate allowing you to track more information such as close/autoclose and button presses. More info in the Mobile Landings documentation.
* In swift, `BatchMessaging.setAutomaticMode` has been renamed to `BatchMessaging.setAutomaticMode(on:)`

**Push**
* BatchPushAlertDidResignNotification is sent when user dismissed the Remote notification authorization alert. Notification's userInfo dict contains user's choice in BatchPushNotificationDidAcceptKey

1.13.2
---

**Core**

* Fixed a rare race condition crash that could happen when tracking an event while In-App campaigns are fetched from the server.

**User**

* Fixed an issue where adding tags would not work with 1.13.1

1.13.1
---

Re-release of 1.13.0, compiled with Xcode 10.1.
Batch now includes an arm64e slice. **arm64e bitcode isn't present**

**Note:** This release comes with an update to the included BatchExtension framework. Its strip-frameworks script will strip the arm64e slice to prevent bitcode-related submission errors: we strongly **discourage** from enabling `arm64e` in your extension's Architectures

1.13.0
---

**Core**  

* Fixed a rare crash that could happen when Batch's internal database failed to initialize in `[BAUserDataManager startAttributesSendWSWithDelay:]`.
* Opting-out from the SDK now sends an event notifying the server of this. If a data wipe has been asked, the request will also be forwarded to the server.
  New methods have been introduced to be informed of the status of the request to update your UI accordingly, and possibly revert the opt-out if the network is unreachable.

* Added the `BatchDeeplinkDelegate` protocol. Adopting it allows you to manually process deeplink open requests from Batch, rather than having to implement `openURL`. See `Batch.deeplinkDelegate` for more information.

**Push**

* The SDK will report whether notifications are allowed, denied, or undecided more accurately on iOS 10 or higher
* Added a method to easily open iOS' settings for the current application's notification settings
* Split `+[BatchPush registerForRemoteNotifications]` into more explicit methods.
  - `+[BatchPush requestNotificationAuthorization]` shows the system notification authorization prompt, and then fetches the push token. Equivalent to calling `+[BatchPush registerForRemoteNotifications]`.
  - `+[BatchPush refreshToken]` will *only* ask iOS for a new token. This needs to be called on every application start to handle upgrades from versions without Batch, or if iOS changes the push token.
* Added support for iOS 12's notification changes:
  - You can now ask for provisional notification authorization using `+[BatchPush requestProvisionalNotificationAuthorization]`. This method does nothing on versions lower than iOS 12.
  - You can now ask Batch to tell iOS that your app supports opening an in-app notification settings from the system settings by calling `[BatchPush setsetSupportsAppNotificationSettings:true]`
    Note that this still requires you to implement a UNUserNotificationCenterDelegate, and the appropriate method to open the settings.

**Events**

Event data support has been overhauled. As a result:  

* Introduced `BatchEventData`. Use this class to attach attributes and tags to an event. See this class' documentation for more information about limits.
* `+[BatchUser trackEvent:withLabel:data:]` has been deprecated
 - Calls to this method will log deprecation warnings in the console
 - Legacy data (NSDictionary) will be converted to `BatchEventData`. Same data format restrictions apply: Any key/value entry that can't be converted will be ignored, and logged. Tags are not supported
* Introduced `+[BatchUser trackEvent:withLabel:associatedData:]` which uses `BatchEventData`, replacing the deprecated method.
 - Swift users: Since Swift allows methods to be overloaded by type, the method and arguments name **do not** change: simply replace your data dictionary with a `BatchEventData` instance
   Example: `BatchUser.trackEvent("event_name", withLabel: "label", data: BatchEventData())`

1.12.0
---

* Added methods to handle opting-out from Batch, and wiping user data.
  Please see `[Batch optOut]`, `[Batch optOutAndWipeData]` and `[Batch optIn]`.
  You can control whether Batch is opted out from by default setting a boolean TRUE in your Info.plist for the key:  
  `BATCH_OPTED_OUT_BY_DEFAULT`
  For compatibility reasons, Batch will be enabled by default.
  More info in our documentation.

* Fixed a bug where an In-App Campaign might not trigger for a certain configuration if a tracked event had a label

1.11.0
---

* Added support for Banners in In-App Messaging

  If your app uses the Mobile Landing/In-App Messaging manual mode, and especially `[BatchMessaging loadViewControllerForMessage:error:]` you need to change the way you present the view controllers manually: please check the [updated manual mode documentation](https://batch.com/doc/ios/mobile-landings.html) for more information.
  A helper has been added on BatchMessaging, which is especially useful if you don't feel like making your own UIWindow: `[BatchMessaging presentMessagingViewController:]`

* Fix In-App Campaigns not honoring the grace period
* Fix an issue where on iOS 11, the fullscreen Messaging template may not be displayed correctly for themes with no CTA
* The SDK will now log the current Installation ID on start

1.10.4
---

* Added [BatchMessaging presentViewController:], which takes care of showing a previously loaded BatchMessagingViewController in the most appropriate way.

  If you used [BatchMessaging loadViewControllerForMessage:error:] to display messages in manual mode, you should go to the messaging documentation to follow updated instructions: failure to do so will result in incorrect banner behaviour.

* Added support for Smart Invert in Mobile Landings/In-App Messaging. Images won't be inverted anymore.

* Added iPhone X support for Mobile Landings/In-App Messaging.

* [BatchMessaging loadViewControllerForMessage:error:] is now allowed in automatic mode.

* Delay button handling in messaging views to until animations are over. This may have prevented deeplinks or custom actions from working properly, as UIKit does not support presenting a view controller while one is already animating.

* Fix In-App Campaigns accidentally performing too much work on the main thread.

* Fix a concurrency issue with In-App Campaigns which could very rarely cause a crash

1.10.3
---
* Added a method on BatchInAppMessage, allowing you to fetch the visual content of the message. See BatchInAppMessage's content property for more info

1.10.2
---
* Fixed a bug where overriding a bold font would not work proper for mobile landings
* Various bugfixes

1.10.1
---
* Removed the one minute minimum delay between two In-App campaign triggers
* Fixed a bug where In-App Campaigns were sometimes not refreshed when coming back in foreground
* Fixed a bug where In-App Campaigns failed to trigger on "Next Session"
* Other bugfixes

1.10.0
----
* Fixed issues found by the Main Thread Checker in Xcode 9
* Introduced In-App Campaigns
* Added a Do Not Disturb mode on BatchMessaging, allowing easier control of when landings will be shown

1.9.0
----
* Added the Inbox module, allowing you to fetch previously received notifications from your code. More info: https://batch.com/doc/ios/inbox.html 

1.8.0
----
* BREAKING CHANGE: Removed BatchAds and BatchUnlock methods and related classes.
* Added BatchUser.trackLocation, allowing you to natively track user position updates
* Deprecated Batch.isRunningInDevelopmentMode. It is useless, as DEV API Keys always start with "DEV"
* Fix a temporary freeze when opening a push containing a deeplink when triggered by a UNUserNotification delegate
* Fixed a memory leak with network requests
* Rewrote documentation with a more modern syntax. Our API docs are now based on jazzy.

1.7.4
----
* Fix a bug where the delegate set on BatchMessaging was never called.

1.7.3
----
* A bug where landings and open rate tracking didn't work when coming from a cold start in some situations on iOS 10.1/10.2 was fixed. Apps implementing UNUserNotificationCenterDelegate or the "fetchCompletionHandler:" variant of the legacy app delegate callbacks are not concerned.
* Applying changes with the user data before starting Batch doesn't fail silently anymore, but now logs an error.
* Improved log clarity for some errors

1.7.2
----
* Rebuild the SDK without debug symbols

1.7.0
----
* Fix the handling of notifications opened while the app is on the screen when using UNUserNotificationCenter on iOS 10. The "bug" remains on iOS 9 because of framework limitations.
* Introduced [Mobile Landings](https://batch.com/doc/ios/mobile-landings.html)

1.6.0
----
* Batch now requires iOS 8 or greater due to Xcode 8 dropping support for earlier versions.
* [Batch setUseAdvancedDeviceInformation:] has been introduced to reduce the quantity of device information Batch will use. Note that disabling this will limit several dashboard features.
* Batch will now use the UserNotification framework when possible. UIUserNotificationCategory instances given to [BatchPush setNotificationsCategories:] are automatically converted to UNNotificationCategory on iOS 10.
* BatchPush has new methods that allows it to be integrated into a UNUserNotificationCenterDelegate instance.
* [BatchPush registerForRemoteNotificationsWithCategories:] has been split in two methods and is now deprecated
* Introduced a new dynamic framework, `BatchExtension`. It is compatible with application extensions APIs, and will progressively bring more Batch features to your extensions. In this version, it is used to add support for [Rich Notifications](https://batch.com/doc/ios/sdk-integration/notification-service-setup.html).  

Since iOS 10 changes quite a lot in how notifications work, it is strongly advised that you read our iOS 10 documentation: https://batch.com/doc/ios/advanced/ios10-migration.html . Upgrading to UNUserNotificationDelegate is recommended.

1.5.4
----
* Fixed push token environment detection (Production/Sandbox) logging
* Fixes a bug where +[BatchPush trackEvent:withLabel:] didn't track the event label correctly

1.5.3
----
* Removed most of the categories used by the SDK. -ObjC shouldn't be needed anymore, but it is encouraged to keep it
* Added support for manual integrations: Application Delegate swizzling can now be disabled, but ALL Batch entry points should be implemented carefully. More info on https://batch.com/doc
* Improved support for notifications containing "content-available":1
* Added .gitignore in "Batch.bundle" to fix git issues for those who commited Batch itself
* Deprecated [BatchPush setupPush]. It is now implied.

1.5.2
----
* Minor bugfixes

1.5.1
----  
* Fixed: push token environment detection failed in some rare cases

1.5
----
* Custom user data (attributes, tags and events)
* Added an API to retrieve Batch's unique installation identifier
* Deprecated BatchUserProfile
* HTTP/2 Support (NSURLSession replaces the NSURLConnection backend when available)

1.4
----
* Deprecated Batch Ads
* Added a method for getting the last known push token
* Improved push registration logs in case of failure
* Fixed Xcode 7 compatibility when integrated via CocoaPods
	NOTE : If you previously integrated Batch, you may need to remove lines
		   that look like "$(PODS_ROOT)/Batch/**" from "Framework Search Paths"
		   in your Build settings for Batch to work with Xcode 7.
* Added Bitcode support

1.3.2
----
* Improved Native Ads:
    * Added properties on BatchNativeAd to get image paths on disk (icon and cover)
    * Added a method to load Native Ads without preloading their UIImages
    * Added a MoPub custom event for Native Ads: BatchMoPubCustomNative
* Automatic deeplink handling can now be disabled
* Added a method for getting the deeplink from Batch Push

1.3.1
----
* Fix an issue that could cause a freeze if your application embedded custom fonts and was started in Airplane mode


1.3
----
* Native Ads
* Renamed ad methods to avoid confusion between interstitial ads and native ads. Old methods are deprecated but still work
* Faster interstitial ad display
* "Batch" Objective-C module now imports everything. Base Batch functionality is in the new "Batch.Core" submodule.
* Batch now logs starts for DEV API Keys


1.2.6
----
* iOS 6 Bugfixes
* Ads optimisations


1.2.5
-----
* Bug fixes


1.2.4
-----
* Bug fix
* Better push implementation
* Deeplink management improvement


1.2.3
-----
* Bug fix


1.2
-----
* Batch Ads


1.1.1 & 1.1.2 & 1.1.3
-----
* Stability improvements


1.1
-----

 * Add push capabilities.
 * iOS 8 and Objective-C modules support.
 * Dropped iOS 5 compatibility.
 * BatchUnlockDelegate is now weakly retained, rather than strongly retained.
 * Batch now requires you to link with libsqlite3.dylib


1.0.1
-----

 * Move a file put by mistake in /Documents/ into /Library/Application Support/


1.0
-----

 * Batch release.
