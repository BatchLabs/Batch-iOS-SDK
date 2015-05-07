//
//  UnlockViewController.h
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UnlockViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *noAdsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *proTrialSwitch;
@property (weak, nonatomic) IBOutlet UILabel *proTrialDaysLeft;
@property (weak, nonatomic) IBOutlet UILabel *livesLabel;

@end
