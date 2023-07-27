//
//  BAUserDataEditor.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BatchUser.h>
#import <Foundation/Foundation.h>

@interface BAUserDataEditor : NSObject

- (void)setLanguage:(nullable NSString *)language;

- (void)setRegion:(nullable NSString *)region;

- (void)setIdentifier:(nullable NSString *)identifier;

- (BOOL)setEmail:(nullable NSString *)email error:(NSError *_Nullable *_Nullable)error;

- (void)setEmailMarketingSubscriptionState:(BatchEmailSubscriptionState)state;

- (void)setAttribute:(nullable NSObject *)attribute forKey:(nonnull NSString *)key;

- (BOOL)setBooleanAttribute:(BOOL)attribute
                     forKey:(nonnull NSString *)key
                      error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setDateAttribute:(nonnull NSDate *)attribute
                  forKey:(nonnull NSString *)key
                   error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setStringAttribute:(nonnull NSString *)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setNumberAttribute:(nonnull NSNumber *)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setIntegerAttribute:(NSInteger)attribute
                     forKey:(nonnull NSString *)key
                      error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setLongLongAttribute:(long long)attribute
                      forKey:(nonnull NSString *)key
                       error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setFloatAttribute:(float)attribute
                   forKey:(nonnull NSString *)key
                    error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setDoubleAttribute:(double)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (BOOL)setURLAttribute:(nonnull NSURL *)attribute
                 forKey:(nonnull NSString *)key
                  error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setAttribute(_:forKey:));

- (void)removeAttributeForKey:(nonnull NSString *)key;

- (void)clearAttributes;

- (void)addTag:(nonnull NSString *)tag inCollection:(nonnull NSString *)collection;

- (void)removeTag:(nonnull NSString *)tag fromCollection:(nonnull NSString *)collection;

- (void)clearTags;

- (void)clearTagCollection:(nonnull NSString *)collection;

- (void)save;

- (void)save:(void (^_Nullable)(void))completion;

- (BOOL)canSave;

// Testing methods

- (NSArray<BOOL (^)(void)> *_Nonnull)operationQueue;

@end
