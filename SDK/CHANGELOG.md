CHANGELOG
=========

1.14.0
---

**Core**

* Bug fix: deeplinks from actions are properly sent to Deeplink delegate method

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
