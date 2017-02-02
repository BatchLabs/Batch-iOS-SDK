CHANGELOG
=========

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
