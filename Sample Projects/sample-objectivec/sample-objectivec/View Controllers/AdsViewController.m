//
//  AdsViewController.m
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import "AdsViewController.h"

@interface AdsViewController ()

@end

@implementation AdsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshStatus];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)manuallyLoadInterstitialAction:(id)sender {
    NSLog(@"Loading interstitial for default placement");
    [BatchAds loadAdForPlacement:BatchPlacementDefault completion:^(NSString *placement, BatchError *error) {
        if (error) {
            NSLog(@"Failed to load interstitial for default placement: %@", [error localizedDescription]);
        } else {
            NSLog(@"Interstitial loaded for default placement");
        }
        [self refreshStatus];
    }];
}

- (IBAction)displayInterstitialAction:(id)sender {
    NSLog(@"Displaying interstitial");
    [BatchAds displayAdForPlacement:BatchPlacementDefault withDelegate:self];
}

- (void)refreshStatus {
    if ([BatchAds hasAdForPlacement:BatchPlacementDefault]) {
        self.displayInterstitialButton.enabled = true;
        self.interstitialStatusLabel.text = @"Ad available";
    } else {
        self.displayInterstitialButton.enabled = false;
        self.interstitialStatusLabel.text = @"No ad available";
    }
}

#pragma mark BatchAdsDisplayDelegate

- (void)adDidAppear:(NSString*)placement {
    NSLog(@"Ad did appear for placement %@", placement);
}

- (void)adDidDisappear:(NSString*)placement {
    NSLog(@"Ad did disappear for placement %@", placement);
}

- (void)adClicked:(NSString*)placement {
    NSLog(@"Ad clicked for placement %@", placement);
}

- (void)adCancelled:(NSString*)placement {
    NSLog(@"Ad cancelled for placement %@", placement);
}

- (void)adNotDisplayed:(NSString*)placement {
    NSLog(@"Ad not displayed for placement %@", placement);
}

@end
