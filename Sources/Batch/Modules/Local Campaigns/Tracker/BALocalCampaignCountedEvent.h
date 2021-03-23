#import <Foundation/Foundation.h>

#import <Batch/BALocalCampaignTrackerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents the informations returned about an aggregated user generated campaign event, ex: an impression.
 */
@interface BALocalCampaignCountedEvent : NSObject

+ (instancetype)eventWithCampaignID:(NSString *)campaignID kind:(BALocalCampaignTrackerEventKind)kind;

- (instancetype)initWithCampaignID:(NSString *)campaignID kind:(BALocalCampaignTrackerEventKind)kind;

@property (nonnull, copy) NSString *campaignID;

@property (assign) BALocalCampaignTrackerEventKind kind;

@property (assign) int64_t count;

@property (nullable) NSDate *lastOccurrence;

@end

NS_ASSUME_NONNULL_END
