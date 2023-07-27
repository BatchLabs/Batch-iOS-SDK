//
//  BAWebserviceMetrics.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAWebserviceMetrics
 @abstract Manages the Webservice metrics.
 */
@interface BAWebserviceMetrics : NSObject

/*!
 @method sharedInstance
 @return Returns the Webservice Metrics singleton
 */
+ (BAWebserviceMetrics *)sharedInstance;

/*!
 @method popMetrics
 @return Get the metrics for a webservice as an array of dictionaries and remove them from the cache
 */
- (NSArray *)popMetricsAsDictionaries;

/*!
 @method webserviceStarted:
 @abstract Starts tracking a webservice duration
 @param shortName The webservice's short name
 */
- (void)webserviceStarted:(NSString *)shortName;

/*!
 @method webserviceFinished:success:
 @abstract Marks the end of a webservice's execution
 @param shortName The webservice's short name
 @param success Whether the WS succeeded or not
 */
- (void)webserviceFinished:(NSString *)shortName success:(BOOL)success;

@end

/*!
 @class BAWebserviceMetric
 @abstract A Webservice metric representation
 */
@interface BAWebserviceMetric : NSObject

- (instancetype)initWithShortname:(NSString *)shortName;

@property (readonly, nonatomic) NSString *shortName;

@property (readonly, nonatomic) NSDate *startDate;

@property (readonly, nonatomic) NSDate *endDate;

@property (readonly, nonatomic) BOOL success;

- (BOOL)isFinished;

- (NSDictionary *)dictionaryRepresentation;

- (void)finishWithResult:(BOOL)success;

@end