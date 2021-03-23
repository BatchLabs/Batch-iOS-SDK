//
//  BAWebserviceMetrics.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAWebserviceMetrics.h>

@interface BAWebserviceMetrics ()
{
    NSMutableDictionary *_metrics;
}

@end

@implementation BAWebserviceMetrics

+ (BAWebserviceMetrics *)sharedInstance
{
    static BAWebserviceMetrics *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BAWebserviceMetrics new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _metrics = [NSMutableDictionary new];
    }
    return self;
}

- (NSArray *)popMetricsAsDictionaries
{
    @synchronized(_metrics)
    {
        NSMutableArray *poppedMetrics = [NSMutableArray new];
        
        for (BAWebserviceMetric *metric in [_metrics allValues])
        {
            if ([metric isFinished])
            {
                [poppedMetrics addObject:[metric dictionaryRepresentation]];
                [_metrics removeObjectForKey:[metric shortName]];
            }
        }
        
        return poppedMetrics;
    }
}

- (void)webserviceStarted:(NSString*)shortName
{
    if (!shortName)
    {
        return;
    }
    
    @synchronized(_metrics)
    {
        [_metrics setObject:[[BAWebserviceMetric alloc] initWithShortname:shortName] forKey:shortName];
    }
}

- (void)webserviceFinished:(NSString*)shortName success:(BOOL)success
{
    if (!shortName)
    {
        return;
    }
    
    @synchronized(_metrics)
    {
        [[_metrics objectForKey:shortName] finishWithResult:success];
    }
}

@end

@implementation BAWebserviceMetric

- (instancetype)initWithShortname:(NSString*)shortName
{
    self = [super init];
    if (self)
    {
        _shortName = shortName;
        _startDate = [NSDate date];
        _endDate = nil;
        _success = NO;
    }
    return self;
}

- (BOOL)isFinished
{
    return self.endDate != nil;
}

- (NSDictionary*)dictionaryRepresentation;
{
    if (!_shortName || !_startDate || !_endDate)
    {
        return @{};
    }
    
    return @{@"u": self.shortName,
             @"s": [NSNumber numberWithBool:self.success],
             @"t": [NSNumber numberWithInt:(int)([self.endDate timeIntervalSinceDate:self.startDate] * 1000)]};
}

- (void)finishWithResult:(BOOL)success
{
    _success = success;
    _endDate = [NSDate date];
}

@end
