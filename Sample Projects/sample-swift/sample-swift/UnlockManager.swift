//
//  UnlockManager.swift
//  sample-swift
//
//  Copyright (c) 2015 Batch.com. All rights reserved.
//

import Foundation
import Batch
import UIKit

/**
* Constants used only in this file
*/
private struct LocalConstants {
    struct Keys {
        static let NoAds = "no_ads"
        static let Lives = "lives"
        static let ProTrial = "pro_trial"
    }
    
    struct DefaultValues {
        static let NoAds = false
        static let Lives = UInt(10)
        static let ProTrial = Int64(0)
    }
    
    struct References {
        static let NoAds = "NO_ADS"
        static let Lives = "LIVES"
        static let ProTrial = "PRO_TRIAL"
    }
}

/*!
 @class UnlockManager
 @abstract Manager reponsible for redeeming and storing unlocked features and items
 */
class UnlockManager {
    
    /**
    * Returns whether ads should be shown or not
    */
    var noAds: Bool {
        get {
            return self.readBool(LocalConstants.Keys.NoAds, defaultValue: LocalConstants.DefaultValues.NoAds)
        }
    }
    
    /**
    * Number of lives left
    */
    var lives: UInt {
        get {
            return self.readUInt(LocalConstants.Keys.Lives, defaultValue: LocalConstants.DefaultValues.Lives)
        }
        set (value) {
            writeUInt(LocalConstants.Keys.Lives, value: value)
        }
    }
    
    
    /**
    * Returns whether the pro trial is enabled or not
    */
    var proTrial: Bool {
        get {
            // Since -1 means unlimited
            return self.proTrialTimeLeft != 0
        }
    }
    
    /**
     * Seconds left for the Pro Trial.
     * Returns -1 if unlimited
     */
    var proTrialTimeLeft: Int64 {
        let expirationDate = self.readInt64(LocalConstants.Keys.ProTrial, defaultValue: LocalConstants.DefaultValues.ProTrial)
        if expirationDate == -1 {
            return -1
        }
        return max(expirationDate - Int64(NSDate().timeIntervalSince1970), 0)
    }
    
    
    /**
     * Shows the 'reward_message' custom parameter of an offer in an alert, if found.
     */
    func showRedeemAlert(offer: BatchOffer, viewController: UIViewController) {
        if let message = offer.offerAdditionalParameters()["reward_message"] as? String {
            print("Displaying 'reward_message' additional parameter")
            
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Thanks!", style: .Default, handler: nil))
            viewController.presentViewController(alert, animated: true, completion: nil)
        } else {
            print("Didn't find an additional parameter named 'reward_message' to display a reward confirmation message")
        }
    }
    
    /**
    * Unlocks the items (features and resources) from an offer
    */
    func unlockItemsFromOffer(offer: BatchOffer) {
        // Redeem features & resources
        if let features = offer.features() as? [BatchFeature] {
            unlockFeatures(features)
        }
    
        for resource in offer.resources() {
            if LocalConstants.References.Lives == resource.reference() {
                print("Unlocking \(resource.quantity()) \(LocalConstants.References.Lives)")
                writeUInt(LocalConstants.Keys.Lives, value: self.lives + resource.quantity())
            }
        }
    }
    
    /**
    * Unlocks the items (features and resources) from an offer
    */
    func unlockFeatures(features: [BatchFeature]) {
        for feature in features {
            if LocalConstants.References.NoAds == feature.reference() {
                print("Unlocking \(LocalConstants.References.NoAds)")
                
                writeBool(LocalConstants.Keys.NoAds, value: true)
            } else if LocalConstants.References.ProTrial == feature.reference() {
                if feature.isLifetime() {
                    print("Unlocking \(LocalConstants.References.ProTrial) forever")
                    
                    writeInt64(LocalConstants.Keys.ProTrial, value: -1)
                } else {
                    print("Unlocking \(LocalConstants.References.ProTrial) for \(feature.ttl()) seconds")
                    
                    // Store the timestamp of expiration
                    writeInt64(LocalConstants.Keys.ProTrial, value: Int64(NSDate().timeIntervalSince1970) + Int64(feature.ttl()))
                }
            }
        }
    }
    
    // MARK: Private helper methods for storage
    
    private func readBool(key: String, defaultValue: Bool) -> Bool {
        if let objectValue = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber {
            return objectValue.boolValue
        }
        return defaultValue
    }
    
    private func readInt64(key: String, defaultValue: Int64) -> Int64 {
        if let objectValue = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber {
            return objectValue.longLongValue
        }
        return defaultValue
    }
    
    private func readUInt(key: String, defaultValue: UInt) -> UInt {
        if let objectValue = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSNumber {
            return objectValue.unsignedLongValue
        }
        return defaultValue
    }
    
    private func writeBool(key: String, value: Bool) {
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(bool: value), forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func writeInt64(key: String, value: Int64) {
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(longLong: value), forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    private func writeUInt(key: String, value: UInt) {
        NSUserDefaults.standardUserDefaults().setObject(NSNumber(unsignedLong: value), forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
