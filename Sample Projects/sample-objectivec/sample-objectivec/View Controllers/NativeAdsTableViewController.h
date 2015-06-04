//
//  NativeAdsTableViewController.h
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Batch;

@interface NativeAdsTableViewController : UITableViewController

@end

@interface FeedItem : NSObject

@property (strong) NSString *title;
@property (strong) NSString *subtitle;

+ (instancetype)itemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle;

@end

@interface FeedItemTableViewCell : UITableViewCell

- (void)updateWithFeedItem:(FeedItem*)item;

@end

@interface NativeAdTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UIButton *ctaButton;
@property (weak, nonatomic) IBOutlet UIImageView *star1ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *star2ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *star3ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *star4ImageView;
@property (weak, nonatomic) IBOutlet UIImageView *star5ImageView;

- (void)updateWithBatchNativeAd:(BatchNativeAd*)ad;

@end

@interface NativeAdCoverTableViewCell : NativeAdTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;

@end