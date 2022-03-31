#import <Foundation/Foundation.h>

@class BALocalCampaignCountedEvent;

typedef NS_ENUM(int, BALocalCampaignTrackerEventKind) {
    BALocalCampaignTrackerEventKindView,
};

NS_ASSUME_NONNULL_BEGIN

@protocol BALocalCampaignTrackerProtocol <NSObject>

@required

/**
 Track an event occurrence for the specified campaign ID and kind

 Returns the updated counted event if successful, nil otherwise
 */
- (nullable BALocalCampaignCountedEvent*)trackEventForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind;

/**
 Get aggregated event information for a given campaign ID and event kind.

 This method never returns nil, even if no event of that kind was ever tracked for this campaign ID.
 */
- (BALocalCampaignCountedEvent*)eventInformationForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind;

/**
 Get the number of view events tracked since a given timestamp

 Return the number of view events ().
 */
 - (nullable NSNumber*)numberOfViewEventsSince:(double)timestamp;

@end

NS_ASSUME_NONNULL_END
