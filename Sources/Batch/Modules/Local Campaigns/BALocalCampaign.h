//
//  BALocalCampaign.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALocalCampaignTrackerProtocol.h>
#import <Batch/BALocalCampaignTriggerProtocol.h>
#import <Batch/BALocalCampaignOutputProtocol.h>
#import <Batch/BATZAwareDate.h>

/**
 Represents an local campaign
 */
@interface BALocalCampaign : NSObject


/**
 Campaign ID, used to track views and capping
 */
@property (nonnull, copy) NSString *campaignID;

/**
 Public token, used to find the campaign in the dashboard
 */
@property (nullable, copy) NSString *publicToken;

/**
 Developer tracking identifier, used for the messaging delegate
 Optional
 */
@property (nullable, copy) NSString *devTrackingIdentifier;

/**
 Additional event data. Used when tracking events related to this campaign to the backend.
 */
@property (nullable, copy) NSDictionary *eventData;

/**
 Minimum messaging API level
 Optional (0 = ignored)
 
 The minimum messaging API level required to display this campaign (shouldn't be confused with the SDK API level)
 */
@property (assign) NSInteger minimumAPILevel;

/**
 Maximum messaging API level
 Optional (0 = ignored)
 
 The maximum messaging API level that shouldn't be exceeded to display this campaign (shouldn't be confused with the SDK API level)
 */
@property (assign) NSInteger maximumAPILevel;

/**
 Priority
 Optional
 
 Priority score: the higher, the more likely it is to be shown to the user
 Used as a "last resort" method to pick the most appropriate In-App campaign
 */
@property (assign) NSInteger priority;

/**
 Campaign start date
 
 If the device date is earlier than this date, the campaign should not be displayed
 */
@property (nonnull, strong) BATZAwareDate *startDate;

/**
 Campaign end date
 Optional
 
 If it is defined and the device date is later than this date, the campaign should not be displayed
 */
@property (nullable, strong) BATZAwareDate *endDate;

/**
 "Hard" capping
 Optional (0 = ignored)
 
 Number of times a user can view this campaign before being uneligible
 */
@property (assign) NSInteger capping;

/**
 "Soft" capping: minimum display interval (in seconds) for this campaign
 Optional (0 = ignored)
 */
@property (assign) NSTimeInterval minimumDisplayInterval;

/**
 Triggers
 
 Triggers that will trigger the display of the campaign. For example: event-based trigger.
 */
@property (nonnull, strong) NSArray<id<BALocalCampaignTriggerProtocol>>* triggers;

/**
 Persist
 Optional (default = yes)
 
 Whether this campaign should be persisted on disk or not.
 */
@property (assign) BOOL persist;

/**
 Output of the campaign: class managing what action a campaign should perform once triggered
 */
@property (nonnull, strong) id<BALocalCampaignOutputProtocol> output;

/**
 Custom payload
 */
@property (nonnull, copy) NSDictionary *customPayload;

/**
 Requires Just In Time Sync
 Optional (default = false)
 
 Whether this campaign should be verified by the server before being displayed.
 */
@property (assign) BOOL requiresJustInTimeSync;

/**
 Generate a new occurrence identifier.
 It is saved in "eventData", in the "i" key (simulating a sendID)
 */
- (void)generateOccurrenceIdentifier;

@end

/**
 * Class used to cache the result of a LocalCampaign after a JIT sync.
 * Keep the timestamp of the sync and whether the campaign was eligible or not.
 */
@interface BATSyncedJITResult : NSObject

/// Timestamp of the sync
@property NSTimeInterval timestamp;

/// Whether the campaign was eligible or not after the sync
@property BOOL eligible;

- (nonnull instancetype)initWithTimestamp:(NSTimeInterval)timestamp;

@end
