//
//  BACenterMulticastDelegate.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol BACenterProtocol
 @abstract Core methods protocol.
 @discussion Protocol describing all the methods a module can handle.
 */
@protocol BACenterProtocol <NSObject>

@optional
/*!
 @method batchWillStart
 @abstract Called before Batch runtime begins its process.
 @discussion Implements anything that deserve it before all the process starts, like subscribing to events or watever.
 */
+ (void)batchWillStart;

/*!
 @method batchDidStart
 @abstract Called after Batch runtime begins its process.
 */
+ (void)batchDidStart;

@end

/*!
 @class BACenterMulticastDelegate
 @abstract Class for methods distribution.
 @discussion This class dispatches the core methods to all Batch modules.
 */
@interface BACenterMulticastDelegate : NSObject <BACenterProtocol>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method startWithAPIKey:
 @abstract Activate the whole Batch system.
 @discussion Call this method in application:didFinishLaunchingWithOptions: of your UIApplicationDelegate
 @discussion You can call this method from any thread, the start process is execute in background.
 @param key    :   Your API private key.
 */
+ (void)startWithAPIKey:(NSString *)key;

@end
