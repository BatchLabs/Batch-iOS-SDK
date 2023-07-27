//
//  BAMSGModalViewController.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAMSGBaseBannerViewController.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Modal format

 Uses the banner as a base to render the alert, but draws a background and is presented modally.
 Like a more advanced system alert, based on the banner look & implementation.
 */
@interface BAMSGModalViewController : BAMSGBaseBannerViewController

@end

NS_ASSUME_NONNULL_END
