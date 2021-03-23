//
//  BADisplayReceiptCache.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

@interface BADisplayReceiptCache : NSObject

// MARK: Methods updating cache files
+ (nonnull NSString *)newFilename;
+ (nullable NSData *)readFromFile:(nonnull NSURL *)file;
+ (BOOL)writeToFile:(nonnull NSURL *)file data:(nonnull NSData *)data;
+ (BOOL)write:(nonnull NSData *)data;
+ (void)remove:(nonnull NSURL *)file;
+ (void)removeAll;
+ (nullable NSArray<NSURL *> *)cachedFiles;

// MARK: Methods updating user defaults
+ (void)saveApiKey:(nonnull NSString*)value;
+ (nullable NSString *)apiKey;
+ (void)saveLastInstallId:(nonnull NSString*)value;
+ (nullable NSString *)lastInstallId;
+ (void)saveIsOptOut:(BOOL)value;
+ (BOOL)isOptOut;

@end
