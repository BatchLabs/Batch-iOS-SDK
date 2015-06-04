//
//  NativeAdsTableViewController.m
//  sample-objectivec
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

#import "NativeAdsTableViewController.h"

// This define controls the position of the native ad in the feed
#define NATIVE_AD_LIST_POSITION 2

// This one controls whether the native ad will be shown with a cover or not
#define NATIVE_AD_SHOW_COVER YES

@interface NativeAdsTableViewController ()
{
    NSArray *feedItems;
    NSMutableArray *listItems;
    BatchNativeAd *nativeAd;
}
@end

@implementation NativeAdsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initFeedItems];
    
    self.tableView.estimatedRowHeight = 44.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initFeedItems {
    feedItems =
    @[
      [FeedItem itemWithTitle:@"One" andSubtitle:@"Subtitle"],
      [FeedItem itemWithTitle:@"Two" andSubtitle:@"Subtitle"],
      [FeedItem itemWithTitle:@"Three" andSubtitle:@"Subtitle"],
      [FeedItem itemWithTitle:@"Four" andSubtitle:@"Subtitle"],
      [FeedItem itemWithTitle:@"Five" andSubtitle:@"Subtitle"]
      ];
    
    listItems = [[NSMutableArray alloc] initWithArray:feedItems];
}

- (IBAction)loadAdAction:(id)sender
{
    [listItems removeAllObjects];
    [listItems addObjectsFromArray:feedItems];
    if (nativeAd) {
        [nativeAd unregisterView];
    }
    nativeAd = [[BatchNativeAd alloc] initWithPlacement:BatchPlacementDefault];
    [listItems insertObject:nativeAd atIndex:NATIVE_AD_LIST_POSITION];
    [self.tableView reloadData];
    
    BatchNativeAdContent adContent = NATIVE_AD_SHOW_COVER ? BatchNativeAdContentAll : BatchNativeAdContentNoCover;
    
    [BatchAds loadNativeAd:nativeAd withContent:adContent completion:^(BatchError *error) {
        
        if (error) {
            NSLog(@"Error while loading Native Ad %@", [error localizedDescription]);
            [listItems removeAllObjects];
            [listItems addObjectsFromArray:feedItems];
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)clicAction:(id)sender
{
    [nativeAd performClickAction];
}

#pragma mark UITableViewDatasource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = [listItems objectAtIndex:indexPath.row];
    UITableViewCell *cell;
    
    if ([item isKindOfClass:[BatchNativeAd class]]) {
        BatchNativeAd *ad = (BatchNativeAd*)item;
        if (ad.state == BatchNativeAdStateLoading) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"adLoadingCell"];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:ad.coverImage ? @"adCoverCell" : @"adCell"];
            [(NativeAdTableViewCell*)cell updateWithBatchNativeAd:(BatchNativeAd*)item];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"feedCell"];
        [(FeedItemTableViewCell*)cell updateWithFeedItem:(FeedItem*)item];
    }
    return cell;
}

#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

@implementation FeedItem

+ (instancetype)itemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle {
    FeedItem *item = [[FeedItem alloc] init];
    item.title = title;
    item.subtitle = subtitle;
    return item;
}

@end

@implementation FeedItemTableViewCell

- (void)updateWithFeedItem:(FeedItem*)item {
    self.textLabel.text = item.title;
    self.detailTextLabel.text = item.subtitle;
}

@end

@implementation NativeAdTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIColor *ctaTintColor = [UIColor colorWithRed:0.30 green:0.65 blue:0.90 alpha:1];
    [self.ctaButton setTintColor:ctaTintColor];
    [self.ctaButton.layer setBorderColor:[ctaTintColor CGColor]];
    [self.ctaButton.layer setBorderWidth:1.0f];
    [self.ctaButton.layer setCornerRadius:3.0f];
}

- (void)updateWithBatchNativeAd:(BatchNativeAd*)ad {
    [ad registerView:self.contentView];
    
    self.iconImageView.image = ad.iconImage;
    self.titleLabel.text = ad.title;
    self.bodyLabel.text = ad.body;
    [self.ctaButton setTitle:ad.callToAction.uppercaseString forState:UIControlStateNormal];
    
    // Hide the stars if starRating is nil, since it means that there is no rating
    // to display.
    if (ad.starRating) {
        self.star1ImageView.hidden = NO;
        self.star2ImageView.hidden = NO;
        self.star3ImageView.hidden = NO;
        self.star4ImageView.hidden = NO;
        self.star5ImageView.hidden = NO;
        
        float starRating = [ad.starRating floatValue];
        for (int i = 1; i < 6; i++) {
            UIImageView *targetStarImageView;
            switch (i) {
                case 1:
                    targetStarImageView = self.star1ImageView;
                    break;
                case 2:
                    targetStarImageView = self.star2ImageView;
                    break;
                case 3:
                    targetStarImageView = self.star3ImageView;
                    break;
                case 4:
                    targetStarImageView = self.star4ImageView;
                    break;
                case 5:
                    targetStarImageView = self.star5ImageView;
                    break;
            }
            
            if (starRating >= i) {
                targetStarImageView.image = [UIImage imageNamed:@"StarFull"];
            } else if (starRating < i && starRating > i-1) {
                targetStarImageView.image = [UIImage imageNamed:@"StarHalf"];
            } else {
                targetStarImageView.image = [UIImage imageNamed:@"StarEmpty"];
            }
        }
    } else {
        self.star1ImageView.hidden = YES;
        self.star2ImageView.hidden = YES;
        self.star3ImageView.hidden = YES;
        self.star4ImageView.hidden = YES;
        self.star5ImageView.hidden = YES;
    }
}

@end

@implementation NativeAdCoverTableViewCell

- (void)updateWithBatchNativeAd:(BatchNativeAd*)ad {
    [super updateWithBatchNativeAd:ad];
    self.coverImageView.image = ad.coverImage;
}

@end
