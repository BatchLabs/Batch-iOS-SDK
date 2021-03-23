//
//  BADisplayReceiptCache.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BADisplayReceiptCache.h>
#import <Batch/BALogger.h>
#import <Batch/BABundleInfo.h>
#import "Defined.h"

#define BA_RECEIPT_CACHE_DIRECTORY @"com.batch.displayreceipts"
#define BA_RECEIPT_CACHE_FILENAME_FORMAT @"%@.bin"
#define BA_RECEIPT_MAX_BATCH_FILE 5
#define BA_RECEIPT_MAX_FILE_AGE 2592000.0 // 30 days in seconds

#define LOGGER_DOMAIN @"BADisplayReceiptCache"

static NSFileCoordinator *coordinator = nil;

@implementation BADisplayReceiptCache

+ (void)initialize {
    coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
}

+ (nullable NSURL *)sharedDirectory
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *sharedGroupDir = [BABundleInfo sharedGroupDirectory];
    NSURL *cacheDir = [sharedGroupDir URLByAppendingPathComponent:BA_RECEIPT_CACHE_DIRECTORY isDirectory:true];
    if (cacheDir == nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not get app group folder."];
        return nil;
    }
    
    NSError *error;
    if ([fm createDirectoryAtURL:cacheDir withIntermediateDirectories:true attributes:nil error:&error] == false) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not create the cache directory: %@.", [error localizedDescription]];
        return nil;
    }
    return cacheDir;
}

// MARK: Methods updating cache files

+ (nonnull NSString *)newFilename
{
    return [NSString stringWithFormat:BA_RECEIPT_CACHE_FILENAME_FORMAT, [[NSUUID UUID] UUIDString]];
}

+ (nullable NSData *)readFromFile:(nonnull NSURL *)file
{
    NSError *error;
    __block NSData *data;
    [coordinator coordinateReadingItemAtURL:file options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL * _Nonnull newURL) {
        data = [NSData dataWithContentsOfURL:newURL];
    }];
    
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not read cache file: %@.", [error localizedDescription]];
        return nil;
    }
    
    return data;
}

+ (BOOL)writeToFile:(nonnull NSURL *)file data:(nonnull NSData *)data
{
    if (data == nil) {
        return false;
    }
    
    NSError *error;
    __block NSError *writeError;
    [coordinator coordinateWritingItemAtURL:file options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL * _Nonnull newURL) {
        [data writeToURL:newURL options:NSDataWritingAtomic error:&writeError];
    }];
    
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not write cache file: %@.", [error localizedDescription]];
        return false;
    }
    
    if (writeError != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not write cache file: %@.", [writeError localizedDescription]];
        return false;
    }
    return true;
}

+ (BOOL)write:(nonnull NSData *)data
{
    NSURL *cacheDir = [self sharedDirectory];
    if (cacheDir == nil) {
        return false;
    }
    
    NSURL *cacheFile = [cacheDir URLByAppendingPathComponent:[self newFilename]];
    return [self writeToFile:cacheFile data:data];
}

+ (void)remove:(nonnull NSURL *)file
{
    NSError *error;
    __block NSError *deleteError;
    [coordinator coordinateWritingItemAtURL:file options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL * _Nonnull newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:&deleteError];
    }];
    
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not delete cache file: %@.", [error localizedDescription]];
        return;
    }
    
    if (deleteError != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not delete cache file: %@.", [deleteError localizedDescription]];
    }
}

+ (void)removeAll
{
    NSURL *sharedGroupDir = [self sharedDirectory];
    NSURL *cacheDir = [sharedGroupDir URLByAppendingPathComponent:BA_RECEIPT_CACHE_DIRECTORY isDirectory:true];
    if (cacheDir == nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not get app group folder."];
        return;
    }
    
    NSError *error;
    __block NSError *deleteError;
    [coordinator coordinateWritingItemAtURL:cacheDir options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL * _Nonnull newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:&deleteError];
    }];
    
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not delete cache directory: %@.", [error localizedDescription]];
        return;
    }
    
    if (deleteError != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not delete cache directory: %@.", [deleteError localizedDescription]];
    }
}

+ (nullable NSArray<NSURL *> *)cachedFiles
{
    NSURL *cacheDir = [self sharedDirectory];
    if (cacheDir == nil) {
        return nil;
    }
    
    NSError *error;
    NSArray<NSURL *> *files = [[NSFileManager defaultManager]
                              contentsOfDirectoryAtURL:cacheDir
                              includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLCreationDateKey, NSURLIsReadableKey]
                              options:NSDirectoryEnumerationSkipsHiddenFiles
                              error:&error];
    
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Could not list cache files: %@.", [error localizedDescription]];
        return nil;
    }
    
    if (files == nil) {
        return nil;
    }
    
    NSMutableDictionary *cachedReceipts = [NSMutableDictionary dictionary];
    for (NSURL *file in files) {
        error = nil;
        NSDictionary<NSURLResourceKey, id> *fileAttributes = [file resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLCreationDateKey, NSURLIsReadableKey] error:&error];
        if (fileAttributes != nil &&
            [[fileAttributes objectForKey:NSURLIsRegularFileKey] boolValue] == true &&
            [[fileAttributes objectForKey:NSURLIsReadableKey] boolValue] == true) {
            
            NSDate *creationDate = [fileAttributes objectForKey:NSURLCreationDateKey];
            if (creationDate != nil && creationDate.timeIntervalSinceNow > BA_RECEIPT_MAX_FILE_AGE * -1.0) {
                [cachedReceipts setObject:creationDate forKey:file];
            } else {
                // File too old, deleting
                [self remove:file];
            }
            
        }
    }
    
    if ([cachedReceipts count] <= 0) {
        return nil;
    }
    
    [cachedReceipts keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return obj1 > obj2;
    }];
    
    NSArray<NSURL *> *tmp = [cachedReceipts allKeys];
    return [tmp subarrayWithRange:NSMakeRange(0, MIN(BA_RECEIPT_MAX_BATCH_FILE, tmp.count))];
}

// MARK: Methods updating user defaults

+ (NSString*)lastInstallId
{
    return [[BABundleInfo sharedDefaults] stringForKey:kParametersDisplayReceiptInstallIdKey];
}

+ (NSString*)apiKey
{
    return [[BABundleInfo sharedDefaults] stringForKey:kParametersDisplayReceiptLastApiKey];
}

+ (BOOL)isOptOut
{
    return [[BABundleInfo sharedDefaults] boolForKey:kParametersDisplayReceiptOptOutKey];
}

+ (void)saveApiKey:(NSString*)value
{
    [self persistStringWithKey:kParametersDisplayReceiptLastApiKey value:value];
}

+ (void)saveLastInstallId:(NSString*)value
{
    [self persistStringWithKey:kParametersDisplayReceiptInstallIdKey value:value];
}

+ (void)saveCustomId:(NSString*)value
{
    [self persistStringWithKey:kParametersDisplayReceiptCustomIdKey value:value];
}

+ (void)saveIsOptOut:(BOOL)value
{
    [self persistBoolWithKey:kParametersDisplayReceiptOptOutKey value:value];
}

+ (void)persistStringWithKey:(NSString*)key value:(NSString*)value
{
    [self persistOperation:^(NSUserDefaults *ud) {
        [ud setValue:value forKey:key];
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Will save in groups: KEY: %@ VALUE: %@", key, value];
    }];
}

+ (void)persistBoolWithKey:(NSString*)key value:(BOOL)value
{
    [self persistOperation:^(NSUserDefaults *ud) {
        [ud setBool:value forKey:key];
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Will save in defaults: KEY: %@ VALUE: %@", key, value ? @"true" : @"false"];
    }];
}

+ (void)persistOperation:(void (^)(NSUserDefaults *))persistOperation
{
    NSUserDefaults *defaults = [BABundleInfo sharedDefaults];
    if (defaults == nil) {
        return;
    }
    
    persistOperation(defaults);
}

@end
