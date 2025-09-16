#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>

/**
 * SQLite-based implementation of the local campaigns tracker protocol.
 * Manages persistence of campaign events and view tracking in a SQLite database.
 */
@interface BALocalCampaignsSQLTracker : NSObject <BALocalCampaignTrackerProtocol>

/**
 * Returns the singleton instance of the SQL tracker.
 * @return The shared BALocalCampaignsSQLTracker instance
 */
+ (BALocalCampaignsSQLTracker *)instance;

/**
 * Deletes all view events from the database.
 * @return YES if deletion was successful, NO otherwise
 */
- (BOOL)deleteViewEvents;

/**
 * Clears all data from the database without destroying table structures.
 * This includes both event data and view events.
 */
- (void)clear;

/**
 * Closes the database connection and cleans up prepared statements.
 * Should be called when the tracker is no longer needed.
 */
- (void)close;

@end

/**
 * TABLE SCHEMAS
 *
 * event (v3)
 * +-----------+----+-----+---------------+--------------+-------+
 * |campaign_id|kind|count|last_occurrence|custom_user_id|
 * +-----------+----+-----+---------------+--------------+-------+
 *
 * view_events (v3)
 * +-------+-----------+-----------+--------------+-------+
 * |_db_id |campaign_id|timestamp_s|custom_user_id|
 * +-------+-----------+-----------+--------------+-------+
 *
 */
