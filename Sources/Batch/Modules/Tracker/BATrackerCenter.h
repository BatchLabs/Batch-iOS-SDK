//
//  BATrackerCenter.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BAEvent.h>
#import <Batch/BAEventDatasourceProtocol.h>
#import <Batch/BATrackerScheduler.h>

#define BA_PUBLIC_EVENT_KEY_LABEL @"label"
#define BA_PUBLIC_EVENT_KEY_DATA @"data"
#define BA_PUBLIC_EVENT_KEY_AMOUNT @"amount"

@class BatchEventData;

/*!
 @class BATrackerCenter
 @abstract Central control point of Batch event tracking services.
 @discussion Used for managing all tracking features.
 */
@interface BATrackerCenter : NSObject <BACenterProtocol>

/*!
 @method instance
 @abstract Instance method.
 @return BATrackerCenter singleton.
 */
+ (BATrackerCenter *_Nonnull)instance __attribute__((warn_unused_result));

/*!
 @method batchWillStart
 @abstract Called before Batch runtime begins its process.
 @discussion Implements anything that deserve it before all the process starts, like subscribing to events or watever.
 */
+ (void)batchWillStart;

/*!
 Track an uncollapsable private event with parameters
 */
+ (void)trackPrivateEvent:(nonnull NSString *)name parameters:(nullable NSDictionary *)parameters;

/*!
 Track a private event with parameters, optionally collapsable (meaning that only one instance of the event will be
 stored)
 */
+ (void)trackPrivateEvent:(nonnull NSString *)name
               parameters:(nullable NSDictionary *)parameters
              collapsable:(BOOL)collapsable;

/*!
 Track an already existing private event. Use case: BAEvent is created from an old BAEventLight instance.
 */
+ (void)trackManualPrivateEvent:(nonnull BAEvent *)event;

/*!
 @method datasource
 @abstract Return the backing datasource
 @return The backing datasource
 */
+ (nonnull id<BAEventDatasourceProtocol>)datasource __attribute__((warn_unused_result));

/*!
 @method scheduler
 @abstract Return the backing scheduler
 @return The backing scheduler
 */
+ (nonnull BATrackerScheduler *)scheduler __attribute__((warn_unused_result));

@end
