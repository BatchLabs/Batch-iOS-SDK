//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAErrorHelper.h>
#import <Batch/BAInjection.h>
#import <Batch/BAMetric.h>
#import <Batch/BAMetricWebserviceClient.h>
#import <Batch/BAWebserviceURLBuilder.h>
#import <Batch/Batch-Swift.h>

#define LOGGER_DOMAIN @"BAMetricsWebserviceClient"

@implementation BAMetricWebserviceClient {
    NSArray *_metrics;
    void (^_successHandler)(void);
    void (^_errorHandler)(NSError *_Nonnull error);
}

- (nullable instancetype)initWithMetrics:(NSArray *)metrics
                                 success:(void (^)(void))successHandler
                                   error:(void (^)(NSError *error))errorHandler;
{
    NSString *host = [[BAInjection injectProtocol:@protocol(BADomainManagerProtocol)] urlFor:BADomainServiceMetric
                                                                        overrideWithOriginal:FALSE];
    NSURL *url = [NSURL URLWithString:host relativeToURL:nil];
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost URL:url delegate:nil];
    if (self) {
        _metrics = metrics;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
    }
    return self;
}

- (nullable NSArray *)requestBodyArray {
    if ([_metrics count] <= 0) {
        return nil;
    }

    // Build the metrics array by converting each metric to its dictionary representation
    // Note: We return the array itself, not wrapped in an object, to match the interface.metrics schema
    // Expected format: [{name: "...", type: "...", values: [...], labels: {...}}, ...]
    NSMutableArray *metricsArray = [NSMutableArray arrayWithCapacity:[_metrics count]];
    for (BAMetric *metric in _metrics) {
        [metricsArray addObject:[metric toDictionary]];
    }

    return metricsArray;
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [super connectionDidFinishLoadingWithData:data];

    if (_successHandler != nil) {
        _successHandler();
    }
}

- (void)connectionFailedWithError:(NSError *)error {
    [super connectionFailedWithError:error];

    if (error != nil && _errorHandler != nil) {
        _errorHandler(error);
    }
}

@end
