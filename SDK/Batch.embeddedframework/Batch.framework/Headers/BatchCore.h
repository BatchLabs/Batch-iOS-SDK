//
//  BatchCore.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BatchUserProfile.h"
#import "BatchLogger.h"

/**
 Batch's main entry point.
 
 @version v1.10.1
 
 @availability iOS 8.0
 */
@interface Batch : NSObject

/**
 @warning Never call this method: Batch only uses static methods.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Start Batch.
 You should call this method in application:didFinishLaunchingWithOptions: of your UIApplicationDelegate
 @discussion You can call this method from any thread, the start process is execute in background.
 @param key    :   Your API private key.
 */


/**
 Start Batch SDK.
 
 Note: This is the method that triggers the hooking or your Application to automatically handle some lifecycle events.
 If you run into issues, you can try moving this method before other SDK initializations, or call [BatchPush disableAutomaticIntegration] before this method, and follow the "Manual Integration" advanced documentation.
 
 @param key Your APP's API Key, LIVE or DEV. You can find it on your dashboard.
 */
+ (void)startWithAPIKey:(NSString *)key NS_AVAILABLE_IOS(8_0);

/**
 Handles a URL, if applicable.
 Call this method in application:openURL:sourceApplication:annotation: of your UIApplicationDelegate
 
 @param url The URL given to you by iOS
 
 @return YES if Batch performed an action with this URL, NO otherwise.
 */
+ (BOOL)handleURL:(NSURL *)url __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/**
 Check if Batch is running in development mode.
 
 @return YES if Batch is started AND if it uses a development API key.
 */
+ (BOOL)isRunningInDevelopmentMode __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(8_0);

/**
 Access the default user profile object.
 
 @return An instance of BatchUserProfile, or nil
 */
+ (BatchUserProfile *)defaultUserProfile __attribute__((warn_unused_result, deprecated("Please use Batch User instead"))) NS_AVAILABLE_IOS(8_0);

/**
 Control whether Batch should try to use the IDFA or if you forbid it to. (default = YES)
 
 @param use YES if Batch can try to use the IDFA, NO if you don't want Batch to use the IDFA.
 
 @warning If you disable this, you might not be able to use IDFA based debugging in your dashboard.
 */
+ (void)setUseIDFA:(BOOL)use NS_AVAILABLE_IOS(8_0);

/**
 Set if Batch can use advanced device identifiers (default = YES)
 
 Advanced device identifiers include information about the device itself, but nothing that
 directly identify the user, such as but not limited to:
 
 - Device model
 
 - Device brand
 
 - Carrier name
 
 - IDFV

 Setting this to false have a negative impact on core Batch features
 You should only use it if you know what you are doing.
 
 @param use YES if Batch can try to use advanced device information, NO if you don't
 
 @warning Disabling this does not automatically disable IDFA collection, please use the appropriate methods to control this.
 */
+ (void)setUseAdvancedDeviceInformation:(BOOL)use NS_AVAILABLE_IOS(8_0);

/**
 Set if Batch should send its logs to a custom object of yours.
 Be careful with your implementation: setting this can impact stability and performance
 
 @param loggerDelegate An object implementing BatchLoggerDelegate. Weakly retained.
 
 @warning You should only use it if you know what you are doing.
 */
+ (void)setLoggerDelegate:(id<BatchLoggerDelegate>)loggerDelegate NS_AVAILABLE_IOS(8_0);

@end
