CHANGELOG
=========

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
