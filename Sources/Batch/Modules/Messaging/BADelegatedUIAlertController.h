//
//  BADelegatedUIAlertController.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BAMessagingCenter.h>
#import <Batch/BAMSGMessage.h>
#import <Batch/BatchMessaging.h>

@interface BADelegatedUIAlertController : UIAlertController <BatchMessagingViewController>

@property (nonnull) BAMSGMessageAlert *messageDescription;

+ (instancetype _Nonnull)alertControllerWithMessage:(BAMSGMessageAlert* _Nonnull)message;

- (instancetype _Nonnull)initWithMessage:(BAMSGMessageAlert* _Nonnull)message;

@end
