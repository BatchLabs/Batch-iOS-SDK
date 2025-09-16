#import <Batch/BALocalCampaignCountedEvent.h>

@implementation BALocalCampaignCountedEvent

/**
 * Factory method to create a new counted event instance.
 * Convenience method that calls the designated initializer internally.
 */
+ (instancetype)eventWithCampaignID:(NSString *)campaignID
                               kind:(BALocalCampaignTrackerEventKind)kind
                       customUserID:(nullable NSString *)customUserID {
    return [[self alloc] initWithCampaignID:campaignID kind:kind customUserID:customUserID];
}

/**
 * Designated initializer for BALocalCampaignCountedEvent.
 * Initializes a new event with the provided parameters and sets default values for count and lastOccurrence.
 */
- (instancetype)initWithCampaignID:(NSString *)campaignID
                              kind:(BALocalCampaignTrackerEventKind)kind
                      customUserID:(nullable NSString *)customUserID {
    self = [super init];
    if (self) {
        self.campaignID = campaignID;
        self.kind = kind;
        self.customUserID = customUserID;
        self.count = 0;
        self.lastOccurrence = nil;
    }

    return self;
}

/**
 * Provides a detailed debug description of the event instance.
 * Used for debugging and logging purposes to display all event properties.
 */
- (NSString *)debugDescription {
    return [NSString
        stringWithFormat:@"BALocalCampaignCountedEvent - Campaign ID: %@\nCustomer User ID: %@\nKind: %lu\nCount: "
                         @"%lli\nLast occurrence: %@",
                         self.campaignID, self.customUserID, (unsigned long)self.kind, self.count, self.lastOccurrence];
}

@end
