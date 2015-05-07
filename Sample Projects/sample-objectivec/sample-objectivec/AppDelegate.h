//
//  AppDelegate.h
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Batch;
@import Batch.Unlock;
@import Batch.Ads;

@interface AppDelegate : UIResponder <UIApplicationDelegate, BatchUnlockDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

