//
//  BAMSGImageViewController.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMSGViewController.h>
#import <UIKit/UIKit.h>

@class BAMSGMessageImage;
@class BACSSDocument;

@interface BAMSGImageViewController : BAMSGViewController

- (instancetype _Nonnull)initWithMessage:(BAMSGMessageImage *_Nonnull)message andStyle:(BACSSDocument *_Nonnull)style;

@property (nonatomic, readonly) BAMSGMessageImage *_Nonnull message;

@end
