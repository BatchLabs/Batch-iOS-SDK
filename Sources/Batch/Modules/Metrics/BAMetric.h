//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//
#import <Batch/BAMetricProtocol.h>
#import <Foundation/Foundation.h>

@interface BAMetric : NSObject <BAMetricProtocol, NSCopying>

/// Metric name
@property (atomic, assign, readonly, nonnull) NSString *name;

/// Metric type (observation | counter )
@property (atomic, assign, readonly, nonnull) NSString *type;

/// Metric values
@property (atomic, strong, readonly, nullable) NSMutableArray<NSNumber *> *values;

/// Metric label names (eg: method / code)
@property (atomic, strong, readwrite, nullable) NSMutableArray<NSString *> *labelNames;

/// Metric label values  (eg: post / 200)
@property (atomic, strong, readwrite, nullable) NSMutableArray<NSString *> *labelValues;

/// Metric children (meaning every label values association is a child)
@property (atomic, strong, readonly, nullable) NSMutableDictionary *children;

- (nonnull instancetype)initWithName:(nonnull NSString *)name;

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                       andLabelNames:(nonnull NSString *)firstLabel, ... NS_REQUIRES_NIL_TERMINATION;

- (nonnull instancetype)initWithName:(nonnull NSString *)name
                   andLabelNamesList:(nonnull NSArray<NSString *> *)labelNames;

/// Get or create a child from labels values
- (nonnull id)labels:(nonnull NSArray<NSString *> *)args;

/// Register this metric to the BAMetricManager instance
- (nonnull id)registerMetric;

/// Flag indicating whether this metric has children
- (BOOL)hasChildren;

/// Flag indicating whether the metric values has changed
- (BOOL)hasChanged;

/// Convert metric to dictionary for serialization
- (nonnull NSDictionary *)toDictionary;

@end
