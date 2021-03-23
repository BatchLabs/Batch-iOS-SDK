//
//  BAWSQueryLocalCampaigns.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQueryLocalCampaigns.h>

@implementation BAWSQueryLocalCampaigns
{
    NSDictionary<NSString*, BALocalCampaignCountedEvent*> *_viewEvents;
}

// Standard constructor.
- (instancetype)initWithViewEvents:(NSDictionary<NSString*, BALocalCampaignCountedEvent*>*)viewEvents
{
    self = [super initWithType:kQueryWebserviceTypeLocalCampaigns];
    if (self) {
        _viewEvents = viewEvents;
    }
    
    return self;
}

// Build the basic object to send to the server as a query.
- (NSMutableDictionary *)objectToSend
{
    NSMutableDictionary *dictionary = [super objectToSend];
    
    NSMutableDictionary *viewsDict = [[NSMutableDictionary alloc] initWithCapacity:[_viewEvents count]];
    for (NSString *campaignID in _viewEvents.keyEnumerator) {
        viewsDict[campaignID] = @{@"count": @(_viewEvents[campaignID].count)};
    }
    dictionary[@"views"] = viewsDict;
    
    return dictionary;
}

@end
