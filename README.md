![Dashboard Items](https://raw.github.com/BatchLabs/ios-sdk/master/readme_logo.png)

# Batch Sample Apps
These samples are minimal examples demonstrating a proper integration of the Batch SDK and implementation of Batch Unlock and Batch Ads functionality.

They are currently written for iOS in both Swift and Objective-C. Android and Unity examples will be coming soon.

## App

1. Clone or download the repository, which contains both `sample-swift` and `sample-objectivec` versions of the sample app.

2. Integrate the SDK with one of the two options below:
    * Use Cocoapods (recommended)
        * Install [Cocoapods](https://cocoapods.org/) if not already installed.
        * Navigate to the directory `sample-swift` or `sample-objectivec` and run `pod install`.
        * Launch the respective `xcworkspace`, not the `xcodeproj`.
    * Integrate manually by [downloading the SDK](https://dashboard.batch.com/download) and following the documentation. 

## Dashboard

### 1. Login to your [Batch.com](https://batch.com/) account or create a new one.

### 2. Add your new sample app
Add a new app on the [dashboard](https://dashboard.batch.com/app/new) using the manual option, as your sample app doesn't have an App Store or Play Store URL to autopopulate.

### 3. Retrieve the dev API key
Within your newly-created app, find the dev API key in the settings menu under *API Keys*. 

Place the dev API key in your sample app's AppDelegate didFinishStartingWithOptions function, in the startWithAPIKey method call.

### 4. Enable ads
In the settings menu, activate *interstitial ads* under *Ads*.

### 5. Add items for Batch Unlock
The samples are configured with three static items: `No Ads`, `Pro Trial`, and `Lives`.

![Dashboard Items](https://raw.github.com/BatchLabs/ios-sdk/master/readme_items.png)

While the names can vary in the *NAME* field, the *REFERENCE* is the case-sensitive value used in the sample code.

*No Ads* is used to demonstrate restorability. It is recommended to set this to *Always restore*.

*Pro Trial* demonstrates a time-to-live (TTL) for expiring offers. Set the option to *trial (days)* and choose a valid amount of days for the feature to be active.

*Lives* is an example of a resource, or consumable item. You can define the given quantity in the campaign.  

### 6. Create campaign
In the campaign screen of your dashboard, create a new *Unlock* campaign. You can use any of the wizard options, or choose a *Custom Offer* for manual setup. 

As long as the conditions (time, user targeting, URL scheme, capping) match when you launch the app, you will recieve whatever configuration of features and resources you specify. You will also recieve the `reward_message` custom parameter, sent as alert, to give feedback to the user about the offer redeemed.

## Resources
* [Full Batch documentation](https://dashboard.batch.com/doc)
* [support@batch.com](support@batch.com)