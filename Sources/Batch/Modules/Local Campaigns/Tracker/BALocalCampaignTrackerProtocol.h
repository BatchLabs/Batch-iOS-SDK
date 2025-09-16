#import <Batch/BALocalCampaignsVersion.h>
#import <Foundation/Foundation.h>

@class BALocalCampaignCountedEvent;

/**
 * Enumeration of event types that can be tracked for local campaigns.
 * Currently only view events are supported.
 */
typedef NS_ENUM(int, BALocalCampaignTrackerEventKind) {
    /** Campaign view event */
    BALocalCampaignTrackerEventKindView,
};

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol defining the interface for tracking local campaign events.
 * Implementations should support customer user ID for personalized tracking.
 */
@protocol BALocalCampaignTrackerProtocol <NSObject>

@required

/**
 * Tracks an event occurrence for the specified campaign ID and kind with customer user ID support.
 * This method increments the count and updates the last occurrence timestamp.
 * @param campaignID The unique identifier of the campaign
 * @param kind The type of event being tracked
 * @param version The campaign version (MEP or CEP) affecting customer user ID support
 * @param customUserID Optional customer user identifier for user-specific tracking
 * @return The updated counted event if successful, nil otherwise
 */
- (nullable BALocalCampaignCountedEvent *)trackEventForCampaignID:(NSString *)campaignID
                                                             kind:(BALocalCampaignTrackerEventKind)kind
                                                          version:(BALocalCampaignsVersion)version
                                                     customUserID:(nullable NSString *)customUserID;

/**
 * Gets aggregated event information for a given campaign ID and event kind with customer user ID support.
 * This method never returns nil, even if no event of that kind was ever tracked for this campaign ID.
 * @param campaignID The unique identifier of the campaign
 * @param kind The type of event to query
 * @param version The campaign version (MEP or CEP) affecting customer user ID support
 * @param customUserID Optional customer user identifier for user-specific queries
 * @return Event information with current count and last occurrence
 */
- (BALocalCampaignCountedEvent *)eventInformationForCampaignID:(NSString *)campaignID
                                                          kind:(BALocalCampaignTrackerEventKind)kind
                                                       version:(BALocalCampaignsVersion)version
                                                  customUserID:(nullable NSString *)customUserID;

/**
 * Gets the number of view events tracked since a given timestamp.
 * Used for time-based capping calculations.
 * @param timestamp The timestamp to count events from (as Unix timestamp)
 * @return The number of view events since the timestamp, or nil if query failed
 */
- (nullable NSNumber *)numberOfViewEventsSince:(double)timestamp;

/**
 * Gets events tracked since a given timestamp.
 * Returns detailed event information including campaign ID, custom user ID, and timestamp.
 * @param timestamp The timestamp to retrieve events from (as Unix timestamp)
 * @return Array of dictionaries containing event details
 */
- (NSArray<NSDictionary *> *)eventsSince:(double)timestamp;

@end

NS_ASSUME_NONNULL_END
