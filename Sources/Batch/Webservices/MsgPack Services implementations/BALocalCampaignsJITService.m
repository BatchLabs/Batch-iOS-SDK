//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BALocalCampaignsJITService.h"
#import <Batch/BAErrorHelper.h>
#import <Batch/BALocalCampaign.h>
#import <Batch/BAWebserviceURLBuilder.h>

#import <Batch/BALocalCampaignCountedEvent.h>

#import <Batch/BAPushCenter.h>
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BATrackerCenter.h>

#import <Batch/BAInjection.h>
#import <Batch/BAJson.h>
#import <Batch/BALocalCampaignsVersion.h>
#import <Batch/BAMetricRegistry.h>
#import <Batch/BANullHelper.h>
#import <Batch/BAParameter.h>
#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/Batch-Swift.h>

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

    BALocalCampaignsVersion _version;
}

/**
 * Initializes the JIT service with campaigns to verify and handlers for success/error.
 * Automatically selects the appropriate webservice endpoint based on the campaign version.
 * @param campaigns Array of campaigns to verify eligibility for
 * @param viewTracker Tracker for getting campaign view counts
 * @param version Campaign version (MEP or CEP) determining endpoint and features
 * @param successHandler Block called with eligible campaign IDs on success
 * @param errorHandler Block called with error and optional retry delay on failure
 * @return Initialized service instance or nil if initialization failed
 */
- (nullable instancetype)initWithLocalCampaigns:(NSArray *)campaigns
                                    viewTracker:(id<BALocalCampaignTrackerProtocol>)viewTracker
                                        version:(BALocalCampaignsVersion)version
                                        success:(void (^)(NSArray *eligibleCampaignIds))successHandler
                                          error:(void (^)(NSError *error, NSNumber *retryAfter))errorHandler;
{
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceWeb
                                                                        overrideWithOriginal:FALSE];
    NSURL *url = nil;
    if (version == BALocalCampaignsVersionCEP) {
        url = [BAWebserviceURLBuilder webserviceURLForHost:host
                                                 shortname:kParametersLocalCEPCampaignsJITWebserviceShortname];
    } else {
        url = [BAWebserviceURLBuilder webserviceURLForHost:host
                                                 shortname:kParametersLocalMEPCampaignsJITWebserviceShortname];
    }

    // We now call the designated initializer of our superclass, BAWebserviceJsonClient
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost URL:url delegate:nil];
    if (self) {
        _campaigns = campaigns;
        _viewTracker = viewTracker;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
        _metricRegistry = [BAInjection injectClass:BAMetricRegistry.class];
        _version = version;

        // Overriding default timeout
        [self setTimeout:LOCAL_CAMPAIGNS_JIT_TIMEOUT];
    }
    return self;
}

/**
 * Builds the request body dictionary for the JIT webservice call.
 * Includes campaign IDs, view counts, and system identifiers with customer user ID support.
 * Overrides the superclass method to provide campaign-specific request data.
 * @return Dictionary containing the request body data
 */
- (nonnull NSMutableDictionary *)requestBodyDictionary {
    if ([_campaigns count] <= 0) {
        return [NSMutableDictionary new];
    }

    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    NSMutableDictionary *identifiers = [NSMutableDictionary new];
    NSMutableArray *campaignIds = [NSMutableArray array];
    NSMutableDictionary *views = [NSMutableDictionary dictionary];

    body[@"ids"] = identifiers;
    body[@"campaigns"] = campaignIds;
    body[@"views"] = views;

    [identifiers addEntriesFromDictionary:[[BAStandardQueryWebserviceIdentifiersProvider sharedInstance] identifiers]];
    NSString *customUserID = [BAParameter objectForKey:kParametersCustomUserIDKey fallback:nil];

    // Add campaign ids to check and views count
    for (BALocalCampaign *campaign in _campaigns) {
        [campaignIds addObject:campaign.campaignID];
        BALocalCampaignCountedEvent *eventData =
            [_viewTracker eventInformationForCampaignID:campaign.campaignID
                                                   kind:BALocalCampaignTrackerEventKindView
                                                version:_version
                                           customUserID:customUserID];
        [views setObject:@{@"count" : @(eventData.count)} forKey:campaign.campaignID];
    }

    // Add user attributes
    if (_version != BALocalCampaignsVersionCEP) {
        id<BAUserDatasourceProtocol> database = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
        if (database != nil) {
            body[@"attributes"] = [BAUserAttribute serverJsonRepresentationForAttributes:[database attributes]];
        }
    }

    return body;
}

- (void)connectionWillStart {
    [super connectionWillStart];

    // Start observing metric
    [[_metricRegistry localCampaignsJITResponseTime] startTimer];
}

// This method now parses JSON instead of MessagePack
- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [super connectionDidFinishLoadingWithData:data];

    // Metrics
    [[_metricRegistry localCampaignsJITResponseTime] observeDuration];
    NSArray<NSString *> *labels = [[NSArray alloc] initWithObjects:@"OK", nil];
    [[[_metricRegistry localCampaignsJITCount] labels:labels] increment];

    if (_successHandler == nil) {
        return;
    }

    @try {
        // Check data.
        if ([BANullHelper isNull:data]) {
            [[NSException exceptionWithName:@"Empty content."
                                     reason:[NSString stringWithFormat:@"Response is NULL or empty."]
                                   userInfo:nil] raise];
            return;
        }

        NSDictionary *startDict = [BAJson deserializeDataAsDictionary:data error:nil];

        if (![BANullHelper isNull:startDict]) {
            [self handleResponse:startDict];
        } else {
            [[NSException exceptionWithName:@"Invalid content."
                                     reason:[NSString stringWithFormat:@"Response is NULL or empty."]
                                   userInfo:nil] raise];
        }
    } @catch (NSException *exception) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Error webservice: %@", [exception description]];
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setValue:exception.name forKey:@"ExceptionName"];
        [info setValue:exception.reason forKey:@"ExceptionReason"];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];

        NSError *error = [[NSError alloc] initWithDomain:LOGGER_DOMAIN code:500 userInfo:info];
        _errorHandler(error, [self retryAfter:error]);
    }
}

- (NSNumber *)retryAfter:(NSError *)error {
    NSNumber *retryAfter = DEFAULT_RETRY_AFTER;
    if (error.userInfo != nil) {
        retryAfter = error.userInfo[@"retryAfter"];
        if (retryAfter == nil) {
            return DEFAULT_RETRY_AFTER;
        }

        return retryAfter;
    }

    return retryAfter;
}

- (void)handleResponse:(NSDictionary *)response {
    // Unpacking response using NSJSONSerialization
    NSError *err = nil;
    // Unpack list of campaign id
    BATJsonDictionary *dictionary = [[BATJsonDictionary alloc] initWithDictionary:response errorDomain:LOGGER_DOMAIN];

    id eligibleCampaignsObject = [dictionary objectForKey:@"eligibleCampaigns"
                                              kindOfClass:[NSArray class]
                                                 allowNil:NO
                                                    error:&err];
    if (eligibleCampaignsObject == nil || err != nil) {
        [BALogger debugForDomain:LOGGER_DOMAIN
                         message:@"Could not fetch eligibleCampaigns: %@", [err localizedDescription]];

        // Check if server respond with RetryAfter
        _errorHandler(err, [self retryAfter:err]);
        return;
    }

    _successHandler(eligibleCampaignsObject);
}

- (void)connectionFailedWithError:(NSError *)error {
    [super connectionFailedWithError:error];

    // Metrics
    [[_metricRegistry localCampaignsJITResponseTime] observeDuration];

    NSArray<NSString *> *labels = [[NSArray alloc] initWithObjects:@"KO", nil];
    [[[_metricRegistry localCampaignsJITCount] labels:labels] increment];

    if (error == nil || _errorHandler == nil) {
        return;
    }
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Failure - %@", [error localizedDescription]];

    _errorHandler(error, [self retryAfter:error]);
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
