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

/*!
 @method handleURL:
 @abstract Give the URL to Batch systems.
 @discussion Call this method in application:openURL:sourceApplication:annotation: of your UIApplicationDelegate
 @discussion You can call this method from any thread.
 @param url         :   The input URL.
 @return YES if Batch take care of this URL, No otherwise.
 @warning The delegate methods is always called in the main thread!
 */
+ (BOOL)handleURL:(NSURL *)url __attribute__((warn_unused_result));

/*!
 @method setCustomUserIdentifier:
 @abstract Set the custom user identifier to Batch, you should use this method if you have your own login system.
 @discussion You can call this method from any thread.
 @param identifier  :   The unique user identifier.
 @warning  Be carefull: Do not use it if you don't know what you are doing, giving a bad custom user ID can result in failure into offer delivery and restore.
 */
+ (void)setCustomUserIdentifier:(NSString *)identifier;

/*!
 @method setUseIDFA:
 @abstract Set if Batch can try to use IDFA (default = YES)
 @discussion Setting this to NO have a negative impact on offer delivery and restore.
 @param use :   YES if Batch can try to use the IDFA, NO if you don't want Batch to use the IDFA.
 @warning You should only use it if you know what you are doing.
 */
+ (void)setUseIDFA:(BOOL)use;

/*!
 @method setUseAdvancedDeviceInformation:
 @abstract Set if Batch can try to use advanced device information (default = YES)
 @warning You should only use it if you know what you are doing.
 */
+ (void)setUseAdvancedDeviceInformation:(BOOL)use;

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
