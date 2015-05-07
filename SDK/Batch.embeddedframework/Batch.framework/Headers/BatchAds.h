//
//  BatchAds.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BatchError.h"


#pragma mark -
#pragma mark Completion blocks

/*!
 @abstract Completion block to use in your application.
 @param placement   : Unique placement string generated in your account.
 @param error       : The error or NULL. @see BatchError
 */
typedef void (^BatchAdsLoaded) (NSString *placement, BatchError *error);


#pragma mark -
#pragma mark BatchAdsDisplayDelegate delegate

/*!
 @protocol BatchAdsDisplayDelegate
 @abstract The delegate called when an Ad is display.
 */
@protocol BatchAdsDisplayDelegate <NSObject>

@optional
/*!
 @method adDidAppear:
 @abstract Ads have been displayed.
 @param placement  :   Placement for which the Ad has been clicked.
 @warning The delegate method is always called in the main thread!
 */
- (void)adDidAppear:(NSString*)placement NS_AVAILABLE_IOS(6_0);

/*!
 @method adDidDisappear:
 @abstract Ads have disappeared.
 @param placement  :   Placement for which the Ad has been clicked.
 @warning The delegate method is always called in the main thread!
 */
- (void)adDidDisappear:(NSString*)placement NS_AVAILABLE_IOS(6_0);

/*!
 @method adClicked:
 @abstract Called when the user clicked on the ad.
 @discussion adDidDisappear: will be called afterwards.
 @param placement  :   Placement for which the Ad has been clicked.
 @warning The delegate method is always called in the main thread!
 */
- (void)adClicked:(NSString*)placement NS_AVAILABLE_IOS(6_0);

/*!
 @method adCancelled:
 @abstract Called when the user cancelled the ad.
 @discussion adDidDisappear: will be called afterwards.
 @param placement  :   Placement for which the Ad has been clicked.
 @warning The delegate method is always called in the main thread!
 */
- (void)adCancelled:(NSString*)placement NS_AVAILABLE_IOS(6_0);

/*!
 @method adNotDisplayed:
 @abstract Ads have not been displayed, see logs.
 @param placement  :   Placement for which the Ad has been clicked.
 @warning The delegate method is always called in the main thread!
 */
- (void)adNotDisplayed:(NSString*)placement NS_AVAILABLE_IOS(6_0);

@end


#pragma mark -
#pragma mark BatchAds interface

/*!
 @class BatchAds
 @abstract Call for all you need to display Ads.
 @discussion Actions you can perform in BatchAds.
 */
@interface BatchAds : NSObject

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method load
 @warning Never call this method.
 */
+ (void)load NS_UNAVAILABLE;

/*!
 @method setupAds
 @abstract Activate Batch Ads system.
 @discussion You can call this method from any thread.
 */
+ (void)setupAds NS_AVAILABLE_IOS(6_0);

/*!
 @method hasAdForPlacement:
 @abstract Check for the avaibility of Ads.
 @discussion You can call this method from any thread.
 @param placement  : Placement for which you want to check the Ad availability.
 @return YES if an Ad is available for the given placement, NO otherwise.
 */
+ (BOOL)hasAdForPlacement:(NSString*)placement __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(6_0);

/*!
 @method displayAdForPlacement:
 @abstract Show an Ad for a specific placement.
 @discussion You can call this method from any thread.
 @param placement  : Placement for which you want to display an ad.
 @return YES if no error found when displaying the Ad for the given placement, NO otherwise.
 */
+ (BOOL)displayAdForPlacement:(NSString*)placement __attribute__((warn_unused_result)) NS_AVAILABLE_IOS(6_0);

/*!
 @method displayAdForPlacement:withDelegate:
 @abstract Show an Ad for a specific placement.
 @discussion You can call this method from any thread.
 @param placement   : Placement for which you want to display an ad.
 @param delegate    : Object that respond to BatchAdsDisplayDelegate for feedback.
 */
+ (void)displayAdForPlacement:(NSString*)placement
              withDelegate:(id<BatchAdsDisplayDelegate>)delegate __attribute__((nonnull)) NS_AVAILABLE_IOS(6_0);

/*!
 @method setAutoLoad:
 @abstract Disable automatic loading of the ads.
 @discussion You will call loadAds before diplaying any ads.
 @discussion You can call this method from any thread.
 @param load   : Set to NO to disable automatic loading.
 */
+ (void)setAutoLoad:(BOOL)load NS_AVAILABLE_IOS(6_0);

/*!
 @method loadAdForPlacement:completion:
 @abstract Trigger ads loading.
 @discussion Calling this method without calling [BatchAds setAutoLoad:NO] will not load anything.
 @param placement   : Placement for which you want to load an ad.
 @param block       : Completion block called after excecution. @see BatchAdsLoaded
 @discussion You can call this method from any thread.
 */
+ (void)loadAdForPlacement:(NSString *)placement completion:(BatchAdsLoaded)block __attribute__((nonnull(1))) NS_AVAILABLE_IOS(6_0);

@end