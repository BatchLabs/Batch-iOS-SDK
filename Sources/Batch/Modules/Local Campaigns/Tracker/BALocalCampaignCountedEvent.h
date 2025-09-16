#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents the informations returned about an aggregated user generated campaign event, ex: an impression.
 */
@interface BALocalCampaignCountedEvent : NSObject

/**
 * Creates a new counted event instance with the specified campaign ID, event kind, and optional custom user ID.
 * @param campaignID The unique identifier of the campaign associated with this event
 * @param kind The type of campaign event (impression, click, etc.)
 * @param customUserID Optional custom user identifier for user-specific tracking
 * @return A new BALocalCampaignCountedEvent instance
 */
+ (instancetype)eventWithCampaignID:(NSString *)campaignID
                               kind:(BALocalCampaignTrackerEventKind)kind
                       customUserID:(nullable NSString *)customUserID;

/**
 * Initializes a new counted event instance with the specified parameters.
 * @param campaignID The unique identifier of the campaign associated with this event
 * @param kind The type of campaign event (impression, click, etc.)
 * @param customUserID Optional custom user identifier for user-specific tracking
 * @return An initialized BALocalCampaignCountedEvent instance
 */
- (instancetype)initWithCampaignID:(NSString *)campaignID
                              kind:(BALocalCampaignTrackerEventKind)kind
                      customUserID:(nullable NSString *)customUserID;

/** The unique identifier of the campaign associated with this event */
@property (nonnull, copy) NSString *campaignID;

/** Optional custom user identifier for user-specific tracking */
@property (nullable, copy) NSString *customUserID;

/** The type of campaign event (impression, click, etc.) */
@property (assign) BALocalCampaignTrackerEventKind kind;

/** The number of times this event has occurred */
@property (assign) int64_t count;

/** The timestamp of the last occurrence of this event */
@property (nullable) NSDate *lastOccurrence;

@end

NS_ASSUME_NONNULL_END
