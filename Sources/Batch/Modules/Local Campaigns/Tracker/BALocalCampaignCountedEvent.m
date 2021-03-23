#import <Batch/BALocalCampaignCountedEvent.h>


@implementation BALocalCampaignCountedEvent

+ (instancetype)eventWithCampaignID:(NSString *)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    return [[self alloc] initWithCampaignID:campaignID kind:kind];
}

- (instancetype)initWithCampaignID:(NSString *)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    self = [super init];
    if (self) {
        self.campaignID = campaignID;
        self.kind = kind;
        self.count = 0;
        self.lastOccurrence = nil;
    }

    return self;
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"BALocalCampaignCountedEvent - Campaign ID: %@\nKind: %lu\nCount: %lli\nLast occurrence: %@",
            self.campaignID,
            (unsigned long)self.kind,
            self.count,
            self.lastOccurrence];
}

@end
