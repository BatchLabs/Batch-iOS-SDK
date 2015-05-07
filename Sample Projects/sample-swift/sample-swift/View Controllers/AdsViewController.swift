//
//  AdsViewController.swift
//  sample-swift
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

import Foundation
import UIKit
import Batch
import Batch.Ads

class AdsViewController: UIViewController, BatchAdsDisplayDelegate {
    
    @IBOutlet weak var interstitialStatusLabel: UILabel!
    @IBOutlet weak var displayInterstitialButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatus()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func manuallyLoadInterstitialAction(sender: AnyObject) {
        println("Loading interstitial for default placement")
        BatchAds.loadAdForPlacement(BatchPlacementDefault, completion: { (placement: String!, error: BatchError!) -> Void in
            if let _error = error {
                println("Failed to load interstitial for default placement: \(error.localizedDescription())")
            } else {
                println("Interstitial loaded for default placement")
            }
            self.refreshStatus()
        })
    }
    
    @IBAction func displayInterstitialAction(sender: AnyObject) {
        println("Displaying interstitial")
        BatchAds.displayAdForPlacement(BatchPlacementDefault, withDelegate: self)
    }
    
    func refreshStatus() {
        if (BatchAds.hasAdForPlacement(BatchPlacementDefault)) {
            displayInterstitialButton.enabled = true
            interstitialStatusLabel.text = "Ad available."
        } else {
            displayInterstitialButton.enabled = false
            interstitialStatusLabel.text = "No ad available."
        }
    }
    
    // MARK : BatchAdsDisplayDelegate methods
    
    func adDidAppear(placement: String!) {
        println("Ad did appear for placement \(placement)")
    }
    
    func adDidDisappear(placement: String!) {
        println("Ad did disappear for placement \(placement)")
    }
    
    func adClicked(placement: String!) {
        println("Ad clicked for placement \(placement)")
    }
    
    func adCancelled(placement: String!) {
        println("Ad cancelled for placement \(placement)")
    }
    
    func adNotDisplayed(placement: String!) {
        println("Ad not displayed for placement \(placement)")
    }
}