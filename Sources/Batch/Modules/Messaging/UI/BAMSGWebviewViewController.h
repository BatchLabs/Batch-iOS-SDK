//
//  BAMSGWebviewViewController.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGViewController.h>
#import <UIKit/UIKit.h>

@class BAMSGMessageWebView;
@class BACSSDocument;

@interface BAMSGWebviewViewController : BAMSGViewController

- (instancetype _Nonnull)initWithMessage:(BAMSGMessageWebView *_Nonnull)message andStyle:(BACSSDocument *_Nonnull)style;

@property (nonatomic, readonly) BAMSGMessageWebView *_Nonnull message;

@end
