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
+ (dispatch_queue_t)sharedQueue;

// Delay is in ms
+ (void)startAttributesSendWSWithDelay:(long long)delay;

+ (void)startAttributesCheckWSWithDelay:(long long)delay;

+ (void)storeTransactionID:(NSString *)transaction forVersion:(NSNumber *)version;

+ (void)updateWithServerDataVersion:(long long)serverVersion;

+ (void)printDebugInformation;

+ (void)clearData;

+ (void)addOperationQueueAndSubmit:(NSArray<BOOL (^)(void)> *)queue withCompletion:(void (^_Nullable)(void))completion;

// Testing methods

+ (BOOL)writeChangesToDatasource:(NSArray<BOOL (^)(void)> *_Nonnull)applyQueue
                       changeset:(long long)changeset NS_SWIFT_NAME(writeToDatasource(changes:changeset:));
@end
