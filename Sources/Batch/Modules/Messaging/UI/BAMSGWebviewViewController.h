//
//  BAMSGWebviewViewController.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Batch/BAMSGViewController.h>

@class BAMSGMessageWebView;
@class BACSSDocument;

@interface BAMSGWebviewViewController: BAMSGViewController

- (instancetype _Nonnull )initWithMessage:(BAMSGMessageWebView *_Nonnull)message andStyle:(BACSSDocument*_Nonnull)style;

@property (nonatomic, readonly) BAMSGMessageWebView * _Nonnull message;

@end
