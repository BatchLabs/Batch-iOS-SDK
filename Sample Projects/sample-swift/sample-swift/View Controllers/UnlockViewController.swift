//
//  UnlockViewController.swift
//  sample-swift
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

import UIKit
import Batch
import Batch.Unlock

class UnlockViewController: UIViewController {
    
    @IBOutlet weak var noAdsSwitch: UISwitch!
    @IBOutlet weak var proTrialSwitch: UISwitch!
    @IBOutlet weak var proTrialDaysLeft: UILabel!
    @IBOutlet weak var livesLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshUI() {
        let unlockManager = UnlockManager()
        noAdsSwitch.on = unlockManager.noAds
        proTrialSwitch.on = unlockManager.proTrial
        livesLabel.text = "\(unlockManager.lives)"
        
        let proTrialTimeLeft = unlockManager.proTrialTimeLeft
        if proTrialTimeLeft > 0 {
            if proTrialTimeLeft < 86400 {
                proTrialDaysLeft.text = "Less than a day left."
            } else {
                proTrialDaysLeft.text = "\(unlockManager.proTrialTimeLeft/86400) days left."
            }
        } else if proTrialTimeLeft == 0 {
            proTrialDaysLeft.text = "Unlimited"
        } else {
            proTrialDaysLeft.text = ""
        }
    }
    
    @IBAction func restoreAction(sender: AnyObject) {
        print("Restoring features")
        
        let alert = UIAlertController(title: nil, message: "Restoring features", preferredStyle: .Alert)
        self.presentViewController(alert, animated: false) { () -> Void in
            BatchUnlock.restoreFeatures({ (features: [AnyObject]!) -> Void in
                
                if let _features = features as? [BatchFeature] {
                    UnlockManager().unlockFeatures(_features)
                    self.refreshUI()
                }
                
                alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                    var message = ""
                    if features.count > 0 {
                        message = "Features restored."
                    } else {
                        message = "No features restored."
                    }
                    
                    print("\(features.count) features restored.")
                    
                    let alert = UIAlertController(title: "Restore successful.", message: message, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
                }, failure: { (failure: BatchError!) -> Void in
                    print("Restore failed.")
                    
                    alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                        var message = "A unknown error occurred."
                        if failure != nil && failure.code == BatchFailReasonNetworkError {
                            message = "A network error occurred."
                        }
                        
                        let alert = UIAlertController(title: "Failed to restore features.", message: message, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
            })
        }
    }
}