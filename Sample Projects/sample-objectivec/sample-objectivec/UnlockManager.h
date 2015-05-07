//
//  UnlockManager.h
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

@import Foundation;
@import UIKit;

@import Batch;
@import Batch.Unlock;

/*!
 @class UnlockManager
 @abstract Manager reponsible for redeeming and storing unlocked features and items
 */
@interface UnlockManager : NSObject

/**
 * Shows the 'reward_message' custom parameter of an offer in an alert, if found.
 */
- (void)showRedeemAlertForOffer:(id<BatchOffer>)offer withViewController:(UIViewController *)viewController;

/**
 * Unlocks the items (features and resources) from an offer
 */
- (void)unlockItemsFromOffer:(id<BatchOffer>)offer;

/**
 * Unlocks the items (features and resources) from an offer
 */
- (void)unlockFeatures:(NSArray *)features;

/**
 * Returns whether ads should be shown or not
 */
@property (nonatomic, readonly) BOOL hasNoAds;

/**
 * Number of lives left
 */
@property (nonatomic, readonly) unsigned long lives;

/**
 * Returns whether the pro trial is enabled or not
 */
@property (nonatomic, readonly) BOOL hasProTrial;

/**
 * Seconds left for the Pro Trial.
 * Returns -1 if unlimited
 */
@property (nonatomic) long long timeLeftForProTrial;

@end
