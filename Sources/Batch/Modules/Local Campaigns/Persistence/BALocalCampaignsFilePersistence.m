//
//  BALocalCampaignsFilePersistence.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BALocalCampaignsFilePersistence.h>
#import <Batch/BADirectories.h>
#import <Batch/BAJson.h>
#import <Batch/BALogger.h>

#define LOGGER_DOMAIN @"Local Campaigns - File Persistence"
#define LOCAL_ERROR_DOMAIN @"com.batch.module.localcampaigns.filepersistence"

#define FILE_VERSION 1

@implementation BALocalCampaignsFilePersistence

- (void)persistCampaigns:(nonnull NSDictionary*)rawCampaignsData
{
    NSDictionary *campaigns = @{
                                @"version": @(FILE_VERSION),
                                @"data": rawCampaignsData ? rawCampaignsData : @{}
                                };
    
    @try
    {
        NSURL *filePath = [self filePath];
        NSData *json = [BAJson serializeData:campaigns error:nil];
        if ([json writeToURL:filePath atomically:YES]) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Successfully wrote local campaigns to file: %@", filePath.path];
        } else {
            [BALogger errorForDomain:LOCAL_ERROR_DOMAIN message:@"Failed to write local campaigns to file: %@", filePath];
        }
    }
    @catch (NSException *exception)
    {
        [BALogger errorForDomain:LOCAL_ERROR_DOMAIN message:@"Could not serialize local campaigns to JSON: %@", exception.reason];
    }
}

- (nullable NSDictionary*)loadCampaignsWithError:(NSError**)error
{
    @try
    {
        NSData *campaignsRawData = [NSData dataWithContentsOfURL:[self filePath]];
        if (campaignsRawData == nil) {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-10
                                         userInfo:@{NSLocalizedDescriptionKey: @"File read error: The file does not exist or could not have been read"}];
            }
            return nil;
        }
        
        NSDictionary *campaigns = [BAJson deserializeDataAsDictionary:campaignsRawData error:nil];
        if (campaigns == nil) {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-20
                                         userInfo:@{NSLocalizedDescriptionKey: @"File read error: Could not deserialize JSON"}];
            }
            return nil;
        }
        
        if (![campaigns isKindOfClass:[NSDictionary class]])
        {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-30
                                         userInfo:@{NSLocalizedDescriptionKey: @"File read error: Consistency error. Root object is not a dictionary."}];
            }
            return nil;
        }
        
        NSNumber *version = campaigns[@"version"];
        if (![version isKindOfClass:[NSNumber class]] || ![version isEqualToNumber:@(FILE_VERSION)])
        {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-40
                                         userInfo:@{NSLocalizedDescriptionKey: @"Consistency error: Invalid or incompatible version."}];
            }
            return nil;
        }
        
        if (![campaigns[@"data"] isKindOfClass:[NSDictionary class]])
        {
            if (error) {
                *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                             code:-50
                                         userInfo:@{NSLocalizedDescriptionKey: @"Consistency error: 'data' is not a dictionary."}];
            }
            return nil;
        }
        
        return campaigns[@"data"];
    }
    @catch (NSException *exception)
    {
        if (error) {
            *error = [NSError errorWithDomain:LOCAL_ERROR_DOMAIN
                                         code:-60
                                     userInfo:@{NSLocalizedDescriptionKey: @"Could not deserialize persisted JSON"}];
        }
        [self deleteCampaigns];
        return nil;
    }
}

- (void)deleteCampaigns
{
    @try
    {
        [[NSFileManager defaultManager] removeItemAtURL:[self filePath] error:nil];
    }
    @catch (NSException *exception)
    {
        [BALogger errorForDomain:LOCAL_ERROR_DOMAIN message:@"Could not delete local campaigns JSON: %@", exception.reason];
    }
}

- (NSURL*)filePath
{
    return [NSURL fileURLWithPathComponents:@[[BADirectories pathForBatchAppSupportDirectory], @"local_campaigns.json"]];
}

@end
