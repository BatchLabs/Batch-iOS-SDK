//
//  UnlockViewController.m
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import "UnlockViewController.h"
#import "UnlockManager.h"

@interface UnlockViewController ()

@end

@implementation UnlockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshUI {
    UnlockManager *unlockManager = [UnlockManager new];
    self.noAdsSwitch.on = unlockManager.hasNoAds;
    self.proTrialSwitch.on = unlockManager.hasProTrial;
    self.livesLabel.text = [NSString stringWithFormat:@"%lu", unlockManager.lives];
    
    long long timeLeftForProTrial = unlockManager.timeLeftForProTrial;
    
    if (timeLeftForProTrial > 0) {
        if (timeLeftForProTrial < 86400) {
            self.proTrialDaysLeft.text = @"Less than a day left";
        } else {
            self.proTrialDaysLeft.text = [NSString stringWithFormat:@"%lli days left", (timeLeftForProTrial/86400)];
        }
    } else if (timeLeftForProTrial == 0) {
        self.proTrialDaysLeft.text = @"";
    } else {
        self.proTrialDaysLeft.text = @"Unlimited";
    }
}

- (IBAction)restoreAction:(id)sender {
    NSLog(@"Restoring features");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Restoring features" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:NO completion:^{
       [BatchUnlock restoreFeatures:^(NSArray *features) {
           if ([features count] > 0) {
               [[UnlockManager new] unlockFeatures:features];
               [self refreshUI];
           }
           
           [alert dismissViewControllerAnimated:YES completion:^{
               NSString *message;
               if ([features count] > 0) {
                   message = @"Features restored";
               } else {
                   message = @"No features restored";
               }
               
               NSLog(@"%d features restored", [features count]);
               
               UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
               [successAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
               [self presentViewController:successAlert animated:YES completion:nil];
           }];
       } failure:^(BatchError *error) {
           NSLog(@"Restore failed");
           
           [alert dismissViewControllerAnimated:YES completion:^{
               NSString *message = @"A unknown error occurred";
               if ([error code] == BatchFailReasonNetworkError) {
                   message = @"A network error occurred";
               }
               
               UIAlertController *failureAlert = [UIAlertController alertControllerWithTitle:@"Failed to restore features" message:message preferredStyle:UIAlertControllerStyleAlert];
               [failureAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
               [self presentViewController:failureAlert animated:YES completion:nil];
           }];
       }];
    }];
}

@end
