//
//  AdsViewController.h
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Batch;
@import Batch.Ads;

@interface AdsViewController : UIViewController <BatchAdsDisplayDelegate>

@property (weak, nonatomic) IBOutlet UILabel *interstitialStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *displayInterstitialButton;

@end
