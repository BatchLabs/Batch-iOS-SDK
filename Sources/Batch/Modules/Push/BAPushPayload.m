//
//  BAPushMessage.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAPushPayload.h>
#import <Batch/BANullHelper.h>
#import <Batch/BALogger.h>
#import "Defined.h"


@interface BAPushPayload ()
{
    NSDictionary *_data;
}

@end


@implementation BAPushPayload

// Build a valid object according to the given info.
- (instancetype)initWithUserInfo:(NSDictionary *)info
{
    self = [super init];
    if ([BANullHelper isNull:self])
    {
        return self;
    }
    
    if ([BANullHelper isDictionaryEmpty:info])
    {
        return nil;
    }
    
    NSDictionary *parameters = [info objectForKey:kWebserviceKeyPushBatchData];
    if ([BANullHelper isDictionaryEmpty:parameters])
    {
        return nil;
    }
    
    // Build tracking parameters.
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Look for an URL.
    NSString *stringURL = [parameters objectForKey:kWebserviceKeyPushDeeplink];
    if (![BANullHelper isStringEmpty:stringURL])
    {
       _rawDeeplink = stringURL;
    }
    
    // Look for in app deeplink
    NSNumber *openDeeplinkInApp = [parameters objectForKey:kWebserviceKeyDeeplinkOpenInApp];
    if (![BANullHelper isNumberEmpty:openDeeplinkInApp])
    {
        _openDeeplinksInApp = [openDeeplinkInApp boolValue];
    }
    
    // Add other parameters.
    for (NSString *key in parameters)
    {
        if (![BANullHelper isNull:[parameters valueForKey:key]])
        {
            [params setValue:[parameters valueForKey:key] forKey:key];
        }
    }
    
    _data = [NSDictionary dictionaryWithDictionary:params];
    
    return self;
}

// Getter to return nil when there is no data.
- (NSDictionary *)data
{
    if ([BANullHelper isDictionaryEmpty:_data])
    {
        return nil;
    }

    return [NSDictionary dictionaryWithDictionary:_data];
}

- (NSDictionary *)openEventData
{
    if ([BANullHelper isDictionaryEmpty:_data])
    {
        return nil;
    }
    
    NSArray *keysToCopy = @[kWebserviceKeyPushId,
                            kWebserviceKeyPushOpenEventData,
                            kWebserviceKeyPushExperiment,
                            kWebserviceKeyPushVariant,
                            kWebserviceKeyPushType];
    
    NSMutableDictionary *openEventDataDict = [NSMutableDictionary new];
    
    for (NSString* keyToCopy in keysToCopy)
    {
        NSObject *value = [_data objectForKey:keyToCopy];
        if (value)
        {
            [openEventDataDict setObject:value forKey:keyToCopy];
        }
    }
    
    return openEventDataDict;
}

- (BOOL)requiresReadReceipt
{
    NSNumber *value = self.data[@"r"];
    if ([value isKindOfClass:NSNumber.class]) {
        return value.boolValue;
    }
    return false;
}

@end
