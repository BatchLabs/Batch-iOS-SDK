#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>

@interface BALocalCampaignsSQLTracker : NSObject <BALocalCampaignTrackerProtocol>

+ (BALocalCampaignsSQLTracker *)instance;

/*!
 @property lock
 @abstract Read/Write lock.
 */
@property NSObject *lock;

@end

/**
 * TABLE SCHEMAS
 *
 * event
 * +-----------+----+-----+---------------+
 * |campaign_id|kind|count|last_occurrence|
 * +-----------+----+-----+---------------+
 *
 */
