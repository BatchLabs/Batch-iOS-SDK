//
//  BAWebserviceQueryPush.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQueryPushToken.h>

#import <Batch/BAPropertiesCenter.h>
#import <Batch/BACoreCenter.h>

@interface BAWSQueryPushToken ()
{
    // Token to send
    NSString *_token;
    
    // Is it a production token?
    BOOL _production;
}
@end

@implementation BAWSQueryPushToken

// Standard constructor.
- (instancetype)initWithToken:(NSString *)token andIsProduction:(BOOL)production
{
    self = [super initWithType:kQueryWebserviceTypePush];
    if (self) {
        _token = token;
        _production = production;
    }
    
    return self;
}

// Build the basic object to send to the server as a query.
- (NSDictionary *)objectToSend;
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:[super objectToSend]];
    
    // Add code.
    [dictionary setValue:_token forKey:kWebserviceKeyQueryToken];
    
    // Add notification types.
    [dictionary setValue:[BAPropertiesCenter valueForShortName:@"nty"] forKey:kWebserviceKeyQueryNotifType];
    
    // Add token environment.
    [dictionary setValue:@(_production) forKey:kWebserviceKeyQueryProduction];
    
    return dictionary;
}

@end
