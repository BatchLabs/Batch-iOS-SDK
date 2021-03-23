//
//  BADirectories.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BADirectories.h>
#import "Defined.h"

@implementation BADirectories

+ (NSString *)pathForBatchAppSupportDirectory
{
    NSString *pathForApplicationSupport = [BADirectories pathForApplicationSupportDirectory];
    pathForApplicationSupport = [pathForApplicationSupport stringByAppendingPathComponent:BABundleIdentifier];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:pathForApplicationSupport isDirectory:&isDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:pathForApplicationSupport withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return pathForApplicationSupport;
}

// The method to get the path to the document directory.
+ (NSString *)pathForDocumentDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// The method to get the path to the application support directory;
+ (NSString *)pathForApplicationSupportDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// The method to get the path to the application support directory with the right bundle.
+ (NSString *)pathForApplicationSupportDirectoryWithBundle
{
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    return [[BADirectories pathForApplicationSupportDirectory] stringByAppendingPathComponent:bundleID];
}

// The method to get the path to the cache directory.
+ (NSString *)pathForCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

// The method to get the path to the cache directory with the right bundle.
+ (NSString *)pathForAppCacheDirectory
{
    NSString *bundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    return [[BADirectories pathForCacheDirectory] stringByAppendingPathComponent:bundleID];
}

// The method to get the path to the cache directory with the right bundle.
+ (NSURL *)pathForAppSharedDirectoryWithGroup:(NSString*)group
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *groupContainerURL = [fm containerURLForSecurityApplicationGroupIdentifier:group];
    return groupContainerURL;
}

@end
