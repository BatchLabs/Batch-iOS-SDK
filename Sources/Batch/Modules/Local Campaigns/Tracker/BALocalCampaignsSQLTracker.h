#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>

@interface BALocalCampaignsSQLTracker : NSObject <BALocalCampaignTrackerProtocol>

+ (BALocalCampaignsSQLTracker *)instance;

- (BOOL)deleteViewEvents;

- (void)clear;

- (void)close;

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
