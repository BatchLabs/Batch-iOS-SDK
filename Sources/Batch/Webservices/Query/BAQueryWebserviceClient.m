//
//  BAQueryWebserviceClient.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAQueryWebserviceClient.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAWebserviceMetrics.h>

#import <Batch/BAJson.h>
#import <Batch/BAParameter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BAUserProfile.h>

#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>

#import <Batch/BAErrorHelper.h>

#import <Batch/BAHTTPHeaders.h>
#import <Batch/BANotificationAuthorization.h>
#import <Batch/BAPushCenter.h>
#import <Batch/BATrackerCenter.h>

#import <Batch/BABundleInfo.h>
#import <Batch/BAQueryWebserviceIdentifiersProviding.h>

#define LOCAL_ERROR_DOMAIN @"BatchQueryWebservice"

@interface BAQueryWebserviceClient ()

@property id<BAQueryWebserviceClientDatasource> datasource;
@property (strong) id<BAQueryWebserviceClientDelegate> delegate;

@property id<BAQueryWebserviceIdentifiersProviding> identifiersProvider;

@property NSString *shortIdentifier;

@property NSArray<id<BAWSQuery>> *sentQueries;

@end

@implementation BAQueryWebserviceClient

// Standard webservice constructor.
- (instancetype)initWithDatasource:(id<BAQueryWebserviceClientDatasource>)datasource
                          delegate:(id<BAQueryWebserviceClientDelegate>)delegate {
    return [self initWithDatasource:datasource
                           delegate:delegate
                identifiersProvider:[BAStandardQueryWebserviceIdentifiersProvider sharedInstance]];
}

- (nonnull instancetype)initWithDatasource:(nonnull id<BAQueryWebserviceClientDatasource>)datasource
                                  delegate:(nullable id<BAQueryWebserviceClientDelegate>)delegate
                       identifiersProvider:(nonnull id<BAQueryWebserviceIdentifiersProviding>)identifiersProvider {
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost URL:[datasource requestURL] delegate:nil];
    if (self) {
        _datasource = datasource;
        _delegate = delegate;
        _identifiersProvider = identifiersProvider;

        _shortIdentifier = [datasource requestShortIdentifier];
    }

    return self;
}

#pragma mark -
#pragma mark Private methods

- (void)handleResponse:(NSDictionary *)response {
    // Check response and handle common functions, return if not valid.
    NSError *re = [BAResponseHelper checkResponse:response];
    if (![BANullHelper isNull:re]) {
        [BALogger errorForDomain:@"Webservice"
                         message:@"Query Webservice returned an invalid response: %@", [re description]];
        [self.delegate webserviceClient:self didFailWithError:re];
        return;
    }

    // Treat query responses.
    NSArray *webserviceResponses = [self webserviceResponsesFromResponse:response];

    if ([BANullHelper isArrayEmpty:webserviceResponses]) {
        [self.delegate webserviceClient:self didFailWithError:[BAErrorHelper webserviceError]];
    } else {
        [self.delegate webserviceClient:self didSucceedWithResponses:webserviceResponses];
    }
}

// Response parser.
- (NSArray *)webserviceResponsesFromResponse:(NSDictionary *)rawResponse {
    // Look for the body.
    NSDictionary *body = [rawResponse objectForKey:@"body"];
    if ([BANullHelper isDictionaryEmpty:body] == YES) {
        return nil;
    }

    // Look for parameters.
    NSMutableArray *webserviceResponses = [[NSMutableArray alloc] initWithArray:[body objectForKey:@"queries"]];
    if ([BANullHelper isArrayEmpty:webserviceResponses] == YES) {
        return nil;
    }

    // Browse asked queries.
    NSMutableArray *responses = [[NSMutableArray alloc] init];
    NSString *queryIdentifier;
    NSDictionary *rawResponseContent;
    NSString *responseIdentifier;
    BAWSResponse *webserviceResponse;

    for (id<BAWSQuery> query in self.sentQueries) {
        queryIdentifier = [query identifier];

        // Look for the corresponding response.
        rawResponseContent = nil;
        for (NSDictionary *response in webserviceResponses) {
            if (![BANullHelper isDictionaryEmpty:response]) {
                responseIdentifier = [response objectForKey:kWebserviceKeyQueryIdentifier];
                if (![BANullHelper isStringEmpty:responseIdentifier] &&
                    [queryIdentifier isEqualToString:responseIdentifier]) {
                    rawResponseContent = response;
                    break;
                }
            }
        }

        // Failure when the response is not found.
        if (![rawResponseContent isKindOfClass:[NSDictionary class]]) {
            return nil;
        }

        // Call delegate.
        webserviceResponse = [self.datasource responseForQuery:query content:rawResponseContent];

        /// Failure when a response mismatch the asked query type.
        if (webserviceResponse == nil) {
            return nil;
        }

        // Collect the webservice resmonse.
        [responses addObject:webserviceResponse];
        [webserviceResponses removeObject:rawResponseContent];
    }

    if ([BANullHelper isArrayEmpty:responses]) {
        return nil;
    }

    return responses;
}

- (void)updateMetricWithSuccess:(BOOL)success {
    [[BAWebserviceMetrics sharedInstance] webserviceFinished:self.shortIdentifier success:success];
}

#pragma mark -
#pragma mark BAWebserviceClient overrides

- (NSMutableDictionary *)requestBodyDictionary {
    NSMutableDictionary *postParameters = [super requestBodyDictionary];

    NSArray *queriesToSend = [self.datasource queriesToSend];
    self.sentQueries = queriesToSend;

    if (![BANullHelper isArrayEmpty:queriesToSend]) {
        NSMutableArray *serializedQueries = [[NSMutableArray alloc] initWithCapacity:queriesToSend.count];
        for (id<BAWSQuery> query in queriesToSend) {
            [serializedQueries addObject:[query objectToSend]];
        }
        postParameters[@"queries"] = serializedQueries;
    } else {
        [BALogger errorForDomain:LOCAL_ERROR_DOMAIN
                         message:@"Query WS will be send without any query. URL: %@", self.url];
    }

    NSMutableDictionary *identifiers = [NSMutableDictionary new];
    postParameters[@"ids"] = identifiers;

    // Modules
    NSNumber *trackerState = [NSNumber numberWithInteger:[BATrackerCenter currentMode]];
    identifiers[@"m_e"] = trackerState;
    NSNumber *pushState = [[BAPushCenter instance] swizzled] ? @1 : @0;
    identifiers[@"m_p"] = pushState;

    // Add common identifiers
    [identifiers addEntriesFromDictionary:[_identifiersProvider identifiers]];

    // Add user profile.
    postParameters[@"upr"] = [[BAUserProfile defaultUserProfile] dictionaryRepresentation];

    // Add notification authorization
    NSDictionary *notificationAuthorization = [[[[[BACoreCenter instance] status] notificationAuthorization]
        currentSettings] optionalDictionaryRepresentation];
    if (notificationAuthorization) {
        postParameters[@"nath"] = notificationAuthorization;
    }

    // NSLog(@"DebugOptin: ts: %@ dty: %@ nath: %@", [NSDate new], [BAPropertiesCenter valueForShortName:@"nty"],
    // [[notificationAuthorization description] stringByReplacingOccurrencesOfString:@"\n" withString:@""]);

    @try {
        // Add the webservice metrics
        NSArray *metrics = [[BAWebserviceMetrics sharedInstance] popMetricsAsDictionaries];
        if ([metrics count] > 0) {
            postParameters[@"metrics"] = metrics;
        }
    } @catch (NSException *metricException) {
        [BALogger errorForDomain:@"BatchWebserviceMetrics"
                         message:@"Error while adding metrics to webservice: %@", [metricException description]];
    }

    return postParameters;
}

- (nonnull NSMutableDictionary<NSString *, NSString *> *)requestHeaders {
    NSMutableDictionary *headers = [super requestHeaders];
    headers[@"User-Agent"] = [BAHTTPHeaders userAgent];
    return headers;
}

#pragma mark -
#pragma mark BAConnectionProtocol

- (void)connectionWillStart {
    [super connectionWillStart];
    if ([self.delegate respondsToSelector:@selector(webserviceClientWillStart:)]) {
        [self.delegate webserviceClientWillStart:self];
    }
    [[BAWebserviceMetrics sharedInstance] webserviceStarted:self.shortIdentifier];
}

- (void)connectionFailedWithError:(NSError *)error {
    [super connectionFailedWithError:error];
    [self updateMetricWithSuccess:false];

    [BALogger
        errorForDomain:LOCAL_ERROR_DOMAIN
               message:@"%@ webservice return an error: %@", self.datasource.requestIdentifier, [error description]];

    NSError *publicError;

    BAConnectionErrorCause cause = [BAConnection errorCauseForError:error];
    if (cause == BAConnectionErrorCauseServerError) {
        publicError = [BAErrorHelper serverError];
    } else if (cause == BAConnectionErrorCauseOptedOut) {
        publicError = [BAErrorHelper optedOutError];
    } else {
        publicError = [BAErrorHelper webserviceError];
    }

    [self.delegate webserviceClient:self didFailWithError:publicError];
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [super connectionDidFinishLoadingWithData:data];
    // Check data.
    if ([BANullHelper isNull:data]) {
        [self updateMetricWithSuccess:false];
        [BALogger errorForDomain:LOCAL_ERROR_DOMAIN
                         message:@"%@ webservice return a NULL or empty data.", self.datasource.requestIdentifier];
        [self.delegate webserviceClient:self didFailWithError:[BAErrorHelper webserviceError]];
        return;
    }

    @try {
        // NSLog(@"Query reply dump: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSDictionary *startDict = [BAJson deserializeDataAsDictionary:data error:nil];

        if (![BANullHelper isNull:startDict]) {
            [self updateMetricWithSuccess:true];
            [self handleResponse:startDict];
        } else {
            [[NSException exceptionWithName:@"Invalid content."
                                     reason:[NSString stringWithFormat:@"%@ response is NULL or empty.",
                                                                       self.datasource.requestIdentifier]
                                   userInfo:nil] raise];
        }
    } @catch (NSException *exception) {
        [self updateMetricWithSuccess:false];
        [BALogger
            errorForDomain:LOCAL_ERROR_DOMAIN
                   message:@"Error %@ webservice: %@", self.datasource.requestIdentifier, [exception description]];
        [self.delegate webserviceClient:self didFailWithError:[BAErrorHelper webserviceError]];
    }
}

@end
