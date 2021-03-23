//
//  BAStatus.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BASessionManager.h>

@class BANotificationAuthorization;
@class BATrackingAuthorization;

/*!
 @class BAStatus
 @abstract General status of Batch library.
 @discussion This class stores the different states of the library.
 */
@interface BAStatus : NSObject

/// Like isRunning, but once true never becomes false  (aka, has Batch.startWithAPIKey been called)
@property (readonly) BOOL isInitialized;

/**
 Session manager
 */
@property (nonnull, readonly) BASessionManager *sessionManager;

/**
 Notification Authorization manager
 */
@property (nonnull, readonly) BANotificationAuthorization *notificationAuthorization;

/**
 Tracking Authorization manager
 */
@property (nonnull, readonly) BATrackingAuthorization *trackingAuthorization;

/*!
 @method initialization
 @abstract Set the library in an initialize state.
 @return an NSError is the library is already init.
 */
- (NSError *_Nullable)initialization __attribute__((warn_unused_result));

/*!
 @method start
 @abstract Change the running status into started state.
 @return An NSError with the reason or nil.
 */
- (NSError *_Nullable)start __attribute__((warn_unused_result));

/*!
 @method stop
 @abstract Change the running status into stoped state.
 @return An NSError with the reason or nil.
 */
- (NSError *_Nullable)stop __attribute__((warn_unused_result));

/*!
 @method isRunning
 @abstract Gives the running state of the library.
 @return YES if the library is running, NO otherwise.
 */
- (BOOL)isRunning __attribute__((warn_unused_result));

/*!
 @method startWebservice
 @abstract Change the start webservice status into started state.
 @return An NSError with the reason or nil.
 */
- (NSError *_Nullable)startWebservice __attribute__((warn_unused_result));

/*!
 @method hasStartWebservice
 @abstract Gives the start webservice state.
 @return YES if start webservice has already succed, NO otherwise.
 */
- (BOOL)hasStartWebservice __attribute__((warn_unused_result));

/*!
 @method isLikeProduction
 @abstract Tells if the application is signed like a Production.
 @return YES if it is, No otherwise.
 */
- (BOOL)isLikeProduction __attribute__((warn_unused_result));

@end
