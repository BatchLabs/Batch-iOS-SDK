//
//  BAMessagingAnalyticsDeduplicatingDelegate.h
//  Batch
//

#import <Foundation/Foundation.h>

#import <Batch/BAMessagingAnalyticsDelegate.h>
#import <Batch/BAInjection.h>

NS_ASSUME_NONNULL_BEGIN

///  Class that proxies the analytics call to an analytics delegate but ensures stuff like triggers only
///  occurring once.
///  It handles special cases such as In-App messages tracking an occurrence
///
///  Also makes it easily mockable
///
///  This class is the one that gets injected for the BAMessagingAnalyticsDelegate protocol
@interface BAMessagingAnalyticsDeduplicatingDelegate : NSObject <BAMessagingAnalyticsDelegate>

- (instancetype)initWithWrappedDelegate:(nonnull id<BAMessagingAnalyticsDelegate>)delegate BATCH_USE_INJECTION_OUTSIDE_TESTS;

@end

NS_ASSUME_NONNULL_END
