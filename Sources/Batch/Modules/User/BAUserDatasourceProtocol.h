//
//  BAUserDatasourceProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BAUserAttribute.h>

@class BAUserAttribute;
@protocol BAUserDatasourceProtocol

/*!
 @method close
 @abstract Close the database. You should call this before deallocing it
 */
- (void)close;

/*!
 @method clear
 @abstract Clear the database
 */
- (void)clear;

#pragma mark Transaction methods

- (BOOL)acquireTransactionLockWithChangeset:(long long)changeset;

- (BOOL)commitTransaction;

- (BOOL)rollbackTransaction;

#pragma mark Attributes methods

- (BOOL)setLongLongAttribute:(long long)attribute forKey:(nonnull NSString*)key;

- (BOOL)setDoubleAttribute:(double)attribute forKey:(nonnull NSString*)key;

- (BOOL)setBoolAttribute:(BOOL)attribute forKey:(nonnull NSString*)key;

- (BOOL)setStringAttribute:(nonnull NSString*)attribute forKey:(nonnull NSString*)key;

- (BOOL)setDateAttribute:(nonnull NSDate*)attribute forKey:(nonnull NSString*)key;

- (BOOL)removeAttributeNamed:(nonnull NSString*)attribute;

#pragma mark Tags methods

- (BOOL)addTag:(nonnull NSString*)tag toCollection:(nonnull NSString*)collection;

- (BOOL)removeTag:(nonnull NSString*)tag fromCollection:(nonnull NSString*)collection;

#pragma mark Cleanup methods

- (BOOL)clearTags;

- (BOOL)clearTagsFromCollection:(nonnull NSString*)collection;

- (BOOL)clearAttributes;

#pragma mark Reader methods

- (nonnull NSDictionary<NSString*, BAUserAttribute*>*)attributes;

- (nonnull NSDictionary<NSString*, NSSet<NSString*>*>*)tagCollections;

#pragma mark Debug methods

- (nonnull NSString*)printDebugDump;

@end
