//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMetricWebserviceClient.h>
#import <Batch/BAWebserviceURLBuilder.h>
#import <Batch/BAMetric.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BATMessagePackWriter.h>

#define LOGGER_DOMAIN @"BAMetricsWebserviceClient"

@implementation BAMetricWebserviceClient
{
    NSArray *_metrics;
    void (^_successHandler)(void);
    void (^_errorHandler)(NSError* _Nonnull error);
}

- (nullable instancetype)initWithMetrics:(NSArray *)metrics
                                 success:(void (^)(void))successHandler
                                   error:(void (^)(NSError* error))errorHandler;
{
    NSURL *url = [NSURL URLWithString:kParametersMetricWebserviceBase relativeToURL:nil];
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost URL:url delegate:nil];
    if (self) {
        _metrics = metrics;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
    }
    return self;
}


- (nullable NSData *)requestBody:(NSError **)error
{
    if ([_metrics count] <= 0) {
        return nil;
    }
    
    BATMessagePackWriter *writer = [[BATMessagePackWriter alloc] init];
    if (![writer writeArraySize:[_metrics count] error:error]) {
        return nil;
    }
    
    for (BAMetric *metric in _metrics) {
        if (![metric packToWriter:writer error:error]) {
            return nil;
        }
    }
    return writer.data;
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data
{
    [super connectionDidFinishLoadingWithData:data];
    
    if (_successHandler != nil) {
        _successHandler();
    }
}

- (void)connectionFailedWithError:(NSError *)error
{
    [super connectionFailedWithError:error];
    if ([error.domain isEqualToString:NETWORKING_ERROR_DOMAIN] && error.code == BAConnectionErrorCauseOptedOut) {
        error = [BAErrorHelper optedOutError];
    }
    
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Failure - %@", [error localizedDescription]];
    if (error != nil && _errorHandler != nil) {
        _errorHandler(error);
    }
}

@end

