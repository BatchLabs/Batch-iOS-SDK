//
//  NativeAdsTableViewController.swift
//  sample-swift
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

import UIKit
import Batch

/**
* Constants used only in this file
*/
private struct LocalConstants {
    // This define controls the position of the native ad in the feed
    static let NativeAdListPosition = 2
    
    // This one controls whether the native ad will be shown with a cover or not
    static let NativeAdShowCover = true
}

class NativeAdsTableViewController: UITableViewController {

    var feedItems: [AnyObject] = []
    var listItems: [AnyObject] = []
    var nativeAd: BatchNativeAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initFeedItems()
        
        tableView.estimatedRowHeight = 44.0;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func initFeedItems() {
        feedItems =
        [
            FeedItem(title: "One", subtitle: "Subtitle"),
            FeedItem(title: "Two", subtitle: "Subtitle"),
            FeedItem(title: "Three", subtitle: "Subtitle"),
            FeedItem(title: "Four", subtitle: "Subtitle"),
            FeedItem(title: "Five", subtitle: "Subtitle")
        ]
        
        listItems = feedItems
    }
    
    @IBAction func loadAdAction(sender: AnyObject) {
        listItems = feedItems
        nativeAd?.unregisterView()
        nativeAd = BatchNativeAd(placement: BatchPlacementDefault)
        listItems.insert(nativeAd!, atIndex: LocalConstants.NativeAdListPosition)
        tableView.reloadData()
        
        let adContent = LocalConstants.NativeAdShowCover ? BatchNativeAdContent.All : BatchNativeAdContent.NoCover
        BatchAds.loadNativeAd(nativeAd, withContent: adContent) { (error: BatchError!) -> Void in
            if let _error = error {
                println("Error while loading Native Ad \(_error.localizedDescription)")
                self.listItems = self.feedItems
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func clicAction(sender: AnyObject) {
        if let _nativeAd = nativeAd {
            _nativeAd.performClickAction()
        }
    }
    
    // MARK: UITableViewDatasource methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item: AnyObject = listItems[indexPath.row]
        var cell: UITableViewCell!
        
        if let adItem = item as? BatchNativeAd {
            if (adItem.state == .Loading) {
                cell = tableView.dequeueReusableCellWithIdentifier("adLoadingCell", forIndexPath: indexPath) as! UITableViewCell
            } else {
                // It is possible that the ad does not have a cover, even if requested
                cell = tableView.dequeueReusableCellWithIdentifier(adItem.coverImage != nil ? "adCoverCell" : "adCell", forIndexPath: indexPath) as! UITableViewCell
                if let adCell = cell as? NativeAdTableViewCell {
                    adCell.updateWithBatchNativeAd(adItem)
                }
            }
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("feedCell", forIndexPath: indexPath) as! UITableViewCell
            if let feedCell = cell as? FeedItemTableViewCell, feedItem = item as? FeedItem {
                feedCell.updateWithFeedItem(item as! FeedItem)
            }
        }

        return cell
    }

    // MARK: UITableViewDelegate methods
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

class FeedItem {
    var title: String
    var subtitle: String
    
    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }
}

class FeedItemTableViewCell: UITableViewCell {
    
    func updateWithFeedItem(item: FeedItem) {
        textLabel!.text = item.title
        detailTextLabel!.text = item.title
    }
    
}

class NativeAdTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var star1ImageView: UIImageView!
    @IBOutlet weak var star2ImageView: UIImageView!
    @IBOutlet weak var star3ImageView: UIImageView!
    @IBOutlet weak var star4ImageView: UIImageView!
    @IBOutlet weak var star5ImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let ctaTintColor = UIColor(red: 0.30, green: 0.65, blue: 0.90, alpha: 1)
        ctaButton.tintColor = ctaTintColor
        ctaButton.layer.borderColor = ctaTintColor.CGColor
        ctaButton.layer.borderWidth = 1.0
        ctaButton.layer.cornerRadius = 3.0
    }
    
    func updateWithBatchNativeAd(ad: BatchNativeAd) {
        ad.registerView(contentView)
        
        iconImageView.image = ad.iconImage
        titleLabel.text = ad.title
        bodyLabel.text = ad.body
        ctaButton.setTitle(ad.callToAction.uppercaseString, forState: .Normal)
        
        // Hide the stars if starRating is nil, since it means that there is no rating
        // to display.
        if let starRating = ad.starRating?.floatValue {
            star1ImageView.hidden = false
            star2ImageView.hidden = false
            star3ImageView.hidden = false
            star4ImageView.hidden = false
            star5ImageView.hidden = false
            
            for var i: Float = 1; i < 6; i++ {
                var targetStarImageView: UIImageView?
                switch i {
                    case 1:
                        targetStarImageView = self.star1ImageView
                        break
                    case 2:
                        targetStarImageView = self.star2ImageView
                        break
                    case 3:
                        targetStarImageView = self.star3ImageView
                        break
                    case 4:
                        targetStarImageView = self.star4ImageView
                        break
                    case 5:
                        targetStarImageView = self.star5ImageView
                        break
                    default:
                        targetStarImageView = nil
                        break
                }
                
                if starRating >= i {
                    targetStarImageView?.image = UIImage(named: "StarFull")
                } else if starRating < i && starRating > i-1 {
                    targetStarImageView?.image = UIImage(named: "StarHalf")
                } else {
                    targetStarImageView?.image = UIImage(named: "StarEmpty")
                }
            }
        } else {
            star1ImageView.hidden = true
            star2ImageView.hidden = true
            star3ImageView.hidden = true
            star4ImageView.hidden = true
            star5ImageView.hidden = true
        }
    }
}

class NativeAdCoverTableViewCell: NativeAdTableViewCell {
    @IBOutlet weak var coverImageView: UIImageView!
    
    override func updateWithBatchNativeAd(ad: BatchNativeAd) {
        super.updateWithBatchNativeAd(ad)
        coverImageView.image = ad.coverImage
    }
}