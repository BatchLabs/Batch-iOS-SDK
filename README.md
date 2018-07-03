Batch.com iOS SDK
==================

![Logo](http://batch-doc.s3.amazonaws.com/logo_batch_192.gif)

![Header](http://batch-doc.s3.amazonaws.com/General/BatchHeader.png)

*Looking for sample code? Please see [BatchLabs/batchcast-ios](https://github.com/batchlabs/batchcast-ios)*

# About

Batch is the leading mobile engagement & push notification suite engineered for the mobile era.

# Requirements
 - iOS 8+
 - Xcode 9.2+

# Installation
CocoaPods (recommended)

```
pod 'Batch'
```

Manual  
 - [Download the SDK](https://batch.com/download#/Android)
 - Drag and drop the framework into your project
 - Add `libsqlite3` and Batch to `Linked Frameworks and Libraries` in your project settings
 - Add `-ObjC` in `Other Build Flags`
 - Enjoy

Note: If you can't add `-ObjC`, you can use `-force_load`:  
![XCode Force Load](https://batch-doc.s3.amazonaws.com/GettingStarted/iOS/ios_force_load.png)

# Usage

## Importing the framework
If you're in swift:
```swift
import Batch
```

or Objective-C

```Objective-C
@import Batch;
```

or
```Objective-C
#import <Batch/Batch.h>
```

## Using it
Describing what Batch can do is a little too big for this README.
Read our [setup documentation](https://batch.com/doc/ios/sdk-integration/initial-setup.html) to follow a step by step tutorial for integrating Batch features into your app.

# Documentation

 - [Technical](https://batch.com/doc)
 - [API Reference](https://batch.com/ios-api-reference/index.html)
 - [FAQ](https://batch.com/doc/faq/general.html)
 - [Developer FAQ](https://batch.com/developers)

Copyright 2016 - Batch.com
