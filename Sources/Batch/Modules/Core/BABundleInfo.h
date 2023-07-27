//
//  BABundleInfo.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BABundleInfo : NSObject

+ (BOOL)usesAPNSandbox;

+ (BOOL)isSharedGroupConfigured;

/**
Returns the shared group id to use.

If it is found in the main bundle info plist under the key "BATCH_APP_GROUP_ID" and not empty, this value will be
returned Otherwise, it will be "group.{bundle_id}.batch
*/
+ (nullable NSString *)sharedGroupId;
+ (nullable NSURL *)sharedGroupDirectory;
+ (nullable NSUserDefaults *)sharedDefaults;

@end
