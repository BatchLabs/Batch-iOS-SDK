//
//  BAResponseHelper.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAResponseHelper.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAParameter.h>
#import <Batch/BAErrorHelper.h>

#import <Batch/BASecureDate.h>

@implementation BAResponseHelper

// Check the validity of the response.
+ (NSError *)checkResponse:(NSDictionary *)response
{
    // Check response object.
    if ([BANullHelper isDictionaryEmpty:response] == YES)
    {
        return [BAErrorHelper serverError];
    }
    
    // Look for the header.
    NSDictionary *header = [response objectForKey:kWebserviceKeyMainHeader];
    if ([BANullHelper isDictionaryEmpty:header] == YES)
    {
        return [BAErrorHelper serverError];
    }
   
    // Look for the status.
    NSString *status = [header objectForKey:kWebserviceKeyMainStatus];
    if ([BANullHelper isStringEmpty:status] == YES)
    {
        return [BAErrorHelper serverError];
    }
    
    NSNumber *timestamp = [header objectForKey:kWebserviceKeyTimestamp];
    if (timestamp != nil)
    {
        [[BASecureDate instance] updateServerDate:timestamp];
        [BAParameter setValue:timestamp forKey:kParametersServerTimestamp saved:YES];
    }
    
    if([@"OK" isEqualToString:status] == NO)
    {
        if([@"INVALID_APIKEY" isEqualToString:status] == YES)
        {
            return [BAErrorHelper errorInvalidAPIKey];
        }
        else
        {
            return [BAErrorHelper serverError];
        }
    }

    
    // Look for the header. Can be empty.
    NSDictionary *body = [response objectForKey:kWebserviceKeyMainBody];
    if ([BANullHelper isNull:body] == YES)
    {
        return [BAErrorHelper serverError];
    }
    
    return nil;
}

@end
