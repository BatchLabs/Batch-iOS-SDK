//
//  BatchTests
//
//  Copyright © Batch.com. All rights reserved.
//

import XCTest
import Batch

class localCampaignsManagerTests: XCTestCase {
    
    private let dateProvider = BASecureDateProvider()
    
    private let manager = BALocalCampaignsManager(dateProvider: BASystemDateProvider(), viewTracker: BALocalCampaignsSQLTracker())

    func testEligibleCampaignsSortedByPriority() {
        let campaigns: [BALocalCampaign] = [
            createFakeCampaignWith(priority: 0, jit: false),
            createFakeCampaignWith(priority: 50, jit: false),
            createFakeCampaignWith(priority: 10, jit: false),
        ];
        manager.load(campaigns);
        
        let sortedCampaigns: [BALocalCampaign] = manager.eligibleCampaignsSorted(byPriority: BANewSessionSignal());
        XCTAssertEqual(sortedCampaigns[0], campaigns[1])
        XCTAssertEqual(sortedCampaigns[1], campaigns[2])
        XCTAssertEqual(sortedCampaigns[2], campaigns[0])
    }
    
    func testFirstEligibleCampaignsRequiringSync() {
        let campaigns: [BALocalCampaign] = [
            createFakeCampaignWith(priority: 0, jit: true),
            createFakeCampaignWith(priority: 0, jit: true),
            createFakeCampaignWith(priority: 0, jit: false),
        ];
        let eligibleCampaignRequiringSync = manager.firstEligibleCampaignsRequiringSync(campaigns);
        
        XCTAssertEqual(2, eligibleCampaignRequiringSync.count);
        XCTAssertEqual(campaigns[0], eligibleCampaignRequiringSync[0]);
        XCTAssertEqual(campaigns[1], eligibleCampaignRequiringSync[1]);
    }
    
    func testFirstCampaignNotRequiringJITSync() {
        let campaigns: [BALocalCampaign] = [
            createFakeCampaignWith(priority: 0, jit: true),
            createFakeCampaignWith(priority: 0, jit: true),
            createFakeCampaignWith(priority: 0, jit: false),
        ];
        let eligibleCampaign = manager.firstCampaignNotRequiringJITSync(campaigns);
        XCTAssertEqual(campaigns[2], eligibleCampaign);
    }

    func testIsJITServiceAvailable() {
        XCTAssertTrue(manager.isJITServiceAvailable())
        manager.setValue((dateProvider.currentDate().timeIntervalSince1970 + 30), forKey: "_nextAvailableJITTimestamp")
        XCTAssertFalse(manager.isJITServiceAvailable())
    }
    
    func testSyncedJITCampaignState() {
        
        let dateProvider = BAMutableDateProvider(timestamp: 0)
        let manager = BALocalCampaignsManager(dateProvider: dateProvider, viewTracker: BALocalCampaignsSQLTracker())

        // Ensure non-jit campaign is return as eligible
        let campaign = createFakeCampaignWith(priority: 0, jit: false);
        XCTAssertEqual(BATSyncedJITCampaignState.eligible, manager.syncedJITCampaignState(campaign));
        
        // Ensure non-cached jit campaign requires a sync
        campaign.requiresJustInTimeSync = true;
        XCTAssertEqual(BATSyncedJITCampaignState.requiresSync, manager.syncedJITCampaignState(campaign));
        
       // Adding fake synced jit result in cache
        let syncedJITResult = BATSyncedJITResult(timestamp: 0);
        syncedJITResult.eligible = false;
        let syncedCampaigns: NSMutableDictionary? = [campaign.campaignID: syncedJITResult];
        manager.setValue(syncedCampaigns, forKey: "_syncedJITCampaigns");
        
        // Ensure cached jit campaign is not eligible
        XCTAssertEqual(BATSyncedJITCampaignState.notEligible, manager.syncedJITCampaignState(campaign));

        // Ensure cached jit campaign is eligible
        syncedJITResult.eligible = true;
        XCTAssertEqual(BATSyncedJITCampaignState.eligible, manager.syncedJITCampaignState(campaign));
        
        dateProvider.setTime(30);
        XCTAssertEqual(BATSyncedJITCampaignState.requiresSync, manager.syncedJITCampaignState(campaign));

    }
    
    private func createFakeCampaignWith(priority: Int, jit: Bool) -> BALocalCampaign {
        let campaign = BALocalCampaign()
        campaign.campaignID = "campaign_id"
        campaign.priority = priority
        campaign.requiresJustInTimeSync = jit
        campaign.triggers = [BANextSessionTrigger()]
        return campaign
    }
}

