//
//  BADirectories.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BADirectories : NSObject

/*!
 @method pathForBatchAppSupportDirectory
 @abstract The method to get the path to the Batch AppSupport directory: /Library/Application Support/com.batch.ios/
 @return The path to the directory.
 */
+ (NSString *)pathForBatchAppSupportDirectory;

/*!
 @method pathForDocumentDirectory
 @abstract The method to get the path to the document directory.
 @return The path to the document directory.
 */
+ (NSString *)pathForDocumentDirectory;

/*!
 @method pathForApplicationSupportDirectory
 @abstract The method to get the path to the application support directory.
 @return The path to the application support directory.
 */
+ (NSString *)pathForApplicationSupportDirectory;

/*!
 @method pathForApplicationSupportDirectoryWithBundle
 @abstract The method to get the path to the application support directory with the right bundle.
 @return The path to the application support directory with the right bundle.
 */
+ (NSString *)pathForApplicationSupportDirectoryWithBundle;

/*!
 @method pathForCacheDirectory
 @abstract The method to get the path to the cache directory.
 @return The path to the cache directory
 */
+ (NSString *)pathForCacheDirectory;

/*!
 @method pathForAppCacheDirectory
 @abstract The method to get the path to the cache directory with the right bundle.
 @return The path to the cache directory of this bundle
 */
+ (NSString *)pathForAppCacheDirectory;


/*!
 @method pathForAppCacheDirectory
 @abstract The method to get the path to the shared directory with group name.
 @return The path to the shared directory
 */
+ (NSURL *)pathForAppSharedDirectoryWithGroup:(NSString*)group;


@end
