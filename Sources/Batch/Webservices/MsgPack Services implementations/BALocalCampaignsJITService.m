//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BALocalCampaignsJITService.h"
#import <Batch/BAErrorHelper.h>
#import <Batch/BALocalCampaign.h>
#import <Batch/BATMessagePackReader.h>
#import <Batch/BATMessagePackWriter.h>
#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BAPushCenter.h>
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BATrackerCenter.h>

#import <Batch/BAInjection.h>
#import <Batch/BAMetricRegistry.h>
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BAUserDatasourceProtocol.h>

#define LOGGER_DOMAIN @"BALocalCampaignsJITService"

/// Timeout for the local campaign jit webservice (in seconds)
#define LOCAL_CAMPAIGNS_JIT_TIMEOUT 1

/// Default retry after in fail case (in seconds)
#define DEFAULT_RETRY_AFTER @60

@implementation BALocalCampaignsJITService {
    /// Campaigns to sync
    NSArray *_campaigns;

    /// View tracker to get campaign views count
    id<BALocalCampaignTrackerProtocol> _viewTracker;

    /// Identifier provider to get system ids
    id<BAQueryWebserviceIdentifiersProviding> _identifiersProvider;

    /// Success callback returning eligible campaigns
    void (^_successHandler)(NSArray *_Nullable eligibleCampaignIds);

    /// Error callback
    void (^_errorHandler)(NSError *_Nonnull error, NSNumber *_Nullable retryAfter);

    /// Metric Registry
    BAMetricRegistry *_metricRegistry;
}

- (nullable instancetype)initWithLocalCampaigns:(NSArray *)campaigns
                                    viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker
                                        success:(void (^)(NSArray *eligibleCampaignIds))successHandler
                                          error:(void (^)(NSError *error, NSNumber *retryAfter))errorHandler;
{
    NSURL *url = [BAWebserviceURLBuilder webserviceURLForShortname:kParametersLocalCampaignsJITWebserviceShortname];
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost URL:url delegate:nil];
    if (self) {
        _campaigns = campaigns;
        _viewTracker = viewTracker;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
        _metricRegistry = [BAInjection injectClass:BAMetricRegistry.class];

        // Overriding default timeout
        [self setTimeout:LOCAL_CAMPAIGNS_JIT_TIMEOUT];
    }
    return self;
}

- (nullable NSData *)requestBody:(NSError **)error {
    if ([_campaigns count] <= 0) {
        return nil;
    }

    BATMessagePackWriter *writer = [[BATMessagePackWriter alloc] init];
    NSError *writerError;

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    NSMutableDictionary *identifiers = [NSMutableDictionary new];
    NSMutableArray *campaignIds = [NSMutableArray array];
    NSMutableDictionary *views = [NSMutableDictionary dictionary];

    body[@"ids"] = identifiers;
    body[@"campaigns"] = campaignIds;
    body[@"views"] = views;

    [identifiers addEntriesFromDictionary:[[BAStandardQueryWebserviceIdentifiersProvider sharedInstance] identifiers]];

    // Add campaign ids to check and views count
    for (BALocalCampaign *campaign in _campaigns) {
        [campaignIds addObject:campaign.campaignID];
        BALocalCampaignCountedEvent *eventData =
            [_viewTracker eventInformationForCampaignID:campaign.campaignID kind:BALocalCampaignTrackerEventKindView];
        [views setObject:@{@"count" : @(eventData.count)} forKey:campaign.campaignID];
    }

    // Add user attributes
    id<BAUserDatasourceProtocol> database = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
    if (database != nil) {
        body[@"attributes"] = [BAUserAttribute serverJsonRepresentationForAttributes:[database attributes]];
    }

    [writer writeDictionary:body error:&writerError];
    if (writerError != nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Could not pack local campaigns jit body"];
        if (error != nil) {
            *error = writerError;
        }
        return false;
    }
    return writer.data;
}

- (void)connectionWillStart {
    [super connectionWillStart];

    // Start observing metric
    [[_metricRegistry localCampaignsJITResponseTime] startTimer];
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [super connectionDidFinishLoadingWithData:data];

    // Metrics
    [[_metricRegistry localCampaignsJITResponseTime] observeDuration];
    [[[_metricRegistry localCampaignsJITCount] labels:@"OK", nil] increment];

    if (_successHandler == nil) {
        return;
    }

    // Unpacking response
    BATMessagePackReader *reader = [[BATMessagePackReader alloc] initWithData:data];

    NSError *readerError;

    // Unpack root map header
    [reader readDictionaryHeaderWithError:&readerError];
    if ([self checkError:readerError]) {
        _successHandler(@[]);
        return;
    }

    // Unpack "eligibleCampaigns" key
    NSString *key = [reader readStringAllowingNil:false error:&readerError];
    if ([self checkError:readerError]) {
        _successHandler(@[]);
        return;
    }
    // Unpack list of campaign id
    NSArray *eligibleCampaigns = [NSArray array];
    if ([@"eligibleCampaigns" isEqual:key]) {
        eligibleCampaigns = [reader readArrayAllowingNil:false error:&readerError];
        if ([self checkError:readerError]) {
            _successHandler(@[]);
            return;
        }
        // Ensure array item type string not nil
        for (id item in eligibleCampaigns) {
            if ([BANullHelper isStringEmpty:item]) {
                [BALogger errorForDomain:LOGGER_DOMAIN message:@"Unpacked JIT response is invalid."];
                _successHandler(@[]);
                return;
            }
        }
    } else {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Missing 'eligibleCampaigns' key in JIT response."];
    }
    _successHandler(eligibleCampaigns);
}

- (void)connectionFailedWithError:(NSError *)error {
    [super connectionFailedWithError:error];

    // Metrics
    [[_metricRegistry localCampaignsJITResponseTime] observeDuration];
    [[[_metricRegistry localCampaignsJITCount] labels:@"KO", nil] increment];

    if (error == nil || _errorHandler == nil) {
        return;
    }
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Failure - %@", [error localizedDescription]];

    // Check if server respond with RetryAfter
    NSNumber *retryAfter = DEFAULT_RETRY_AFTER;
    if (error.userInfo != nil) {
        retryAfter = error.userInfo[@"retryAfter"];
        if (retryAfter == nil) {
            retryAfter = DEFAULT_RETRY_AFTER;
        }
    }
    _errorHandler(error, retryAfter);
}

- (BOOL)checkError:(NSError *)error {
    if (error != nil) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Failed unpacking JIT response: %@", error.localizedDescription];
        return true;
    }
    return false;
}

@end
