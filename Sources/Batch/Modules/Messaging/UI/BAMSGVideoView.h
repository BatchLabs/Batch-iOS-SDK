//
//  BAMSGVideoView.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <Batch/BAMSGStylableView.h>

@interface BAMSGVideoView : UIView <BAMSGStylableView>

- (instancetype)initWithURL:(NSURL *)url;

- (void)viewDidAppear;

- (void)viewDidDisappear;

@end
