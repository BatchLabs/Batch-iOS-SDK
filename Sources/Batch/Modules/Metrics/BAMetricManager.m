//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAMetricManager.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/BAMetricWebserviceClient.h>
#import <Batch/BAMetric.h>
#import <Batch/BACounter.h>
#import <Batch/BAObservation.h>
#import <Batch/BASecureDateProvider.h>


#define LOGGER_DOMAIN @"BAMetricManager"

#define DELAY_BEFORE_SENDING 1///sec

/// Default retry after in fail case (in seconds)
#define DEFAULT_RETRY_AFTER @60

@implementation BAMetricManager
{
    
    /// Metrics registered
    NSMutableArray<BAMetric*> *_metrics;
    
    /// Flag indicating whether we are stacking metrics before sending them
    BOOL _isSending;
    
    /// Dispatch queue
    dispatch_queue_t _dispatchQueue;
    
    /// Timestamp to wait before metric service be available again.
    NSTimeInterval _nextAvailableMetricServiceTimestamp;
    
    /// Date provider
    id<BADateProviderProtocol> _dateProvider;

}

#pragma mark  - Instance setup

+ (BAMetricManager *)sharedInstance
{
    static BAMetricManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BAMetricManager new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isSending = NO;
        _metrics = [NSMutableArray array];
        _dateProvider = [BASecureDateProvider new];
        _dispatchQueue = dispatch_queue_create("com.batch.ios.metrics", NULL);
    }
    return self;
}
#pragma mark - Public methods

- (void)addMetric:(BAMetric*)metric
{
    [_metrics addObject:metric];
}

- (void)sendMetrics
{
    //We are stacking metrics before sending
    if (_isSending) {
        return;
    }
    
    if (![self isMetricServiceAvailable]) {
        [BALogger debugForDomain:LOGGER_DOMAIN message:@"Metric webservice not available. Retrying later."];
        return;
    }
    
    self->_isSending = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DELAY_BEFORE_SENDING * NSEC_PER_SEC)), _dispatchQueue, ^{
                
        NSArray *metrics = [self getMetricsToSend];
        
        if ([metrics count] <= 0) {
            return;
        }
        
        BAWebserviceClient *wsClient = [[BAMetricWebserviceClient alloc] initWithMetrics:metrics success:^() {
            self->_isSending = NO;
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Metrics sent with success"];
        } error:^(NSError* error) {
            [BALogger debugForDomain:LOGGER_DOMAIN message:@"Fail sending metrics."];
            // Check if server respond with RetryAfter
            NSNumber *retryAfter = DEFAULT_RETRY_AFTER;
            if (error.userInfo != nil) {
                retryAfter = error.userInfo[@"retryAfter"];
                if (retryAfter == nil) {
                    retryAfter = DEFAULT_RETRY_AFTER;
                }
            }
            self->_nextAvailableMetricServiceTimestamp = [[self->_dateProvider currentDate] timeIntervalSince1970] + retryAfter.doubleValue;
            self->_isSending = NO;
        }];
        [BAWebserviceClientExecutor.sharedInstance addClient:wsClient];
    });
}

#pragma mark - Private methods
- (NSArray*)getMetricsToSend
{
    NSMutableArray* metricsToSend = [NSMutableArray array];
    for (BAMetric* metric in _metrics) {
        if ([metric hasChildren]) {
            [metric.children enumerateKeysAndObjectsUsingBlock:^(id labels, id child, BOOL *stop) {
                BAMetric* childMetric = (BAMetric*) child;
                if ([childMetric hasChanged]) {
                    [metricsToSend addObject:[childMetric copy]];
                    [childMetric reset];
                }
            }];
        } else {
            if ([metric hasChanged]) {
                [metricsToSend addObject:[metric copy]];
                [metric reset];
            }
        }
    }
    return [metricsToSend copy];
}

- (BOOL)isMetricServiceAvailable {
    return ([[_dateProvider currentDate] timeIntervalSince1970] >= _nextAvailableMetricServiceTimestamp);
}

@end
