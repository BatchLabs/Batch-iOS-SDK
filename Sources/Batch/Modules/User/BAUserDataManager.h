//
//  BAUserDataManager.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAUserDataManager
 @abstract Manages the user data: webservices, shared queue, etc...
 */
@interface BAUserDataManager : NSObject

/*
 @abstract Shared operation queue that should synchronize all access to the db. ANY SQL ACCESS should happen in this
 queue.
 */
+ (nonnull dispatch_queue_t)sharedQueue;

// Delay is in ms
+ (void)startAttributesSendWSWithDelay:(long long)delay;

+ (void)startAttributesCheckWSWithDelay:(long long)delay;

+ (void)storeTransactionID:(nonnull NSString *)transaction forVersion:(nonnull NSNumber *)version;

+ (void)updateWithServerDataVersion:(long long)serverVersion;

+ (void)clearData;

/// Only clears attributes and tags where clearData removes versions & stuff.
+ (void)clearRemoteInstallationDataWithCompletion:(void (^_Nullable)(void))completion;

/// Exposed for tests only
+ (void)_performClearRemoteInstallationDataWithCompletion:(void (^_Nullable)(void))completion;

/// Can we save data?
+ (BOOL)canSave;

+ (void)addOperationQueueAndSubmit:(NSArray<BOOL (^)(void)> *_Nonnull)queue
                    withCompletion:(void (^_Nullable)(void))completion;

// Testing methods

+ (BOOL)writeChangesToDatasource:(NSArray<BOOL (^)(void)> *_Nonnull)applyQueue
                       changeset:(long long)changeset NS_SWIFT_NAME(writeToDatasource(changes:changeset:));
@end
