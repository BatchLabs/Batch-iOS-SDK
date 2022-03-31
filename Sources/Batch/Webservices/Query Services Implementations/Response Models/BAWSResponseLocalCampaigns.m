//
//  BAWSResponseLocalCampaigns.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSResponseLocalCampaigns.h>

#import <Batch/BALocalCampaignsParser.h>

@interface BAWSResponseLocalCampaigns () {
    NSDictionary *_payload;
}
@end

@implementation BAWSResponseLocalCampaigns

// Default constructor.
- (instancetype)initWithResponse:(NSDictionary *)response {
    self = [super initWithResponse:response];

    if (self) {
        _payload = response;
    }

    return self;
}

- (NSDictionary *)payload {
    return _payload != nil ? _payload : @{};
}

@end
