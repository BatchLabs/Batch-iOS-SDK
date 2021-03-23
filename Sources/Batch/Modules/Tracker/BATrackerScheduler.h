//
//  BATrackerScheduler.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BATrackerScheduler
 @abstract Treat the tracker webservice scheduling.
 @discussion This object is responsible for detecting when it's appropriate to execute the tracking webservice
 */
@interface BATrackerScheduler : NSObject

/*!
 @method newEventsAvailable
 @abstract Inform the scheduler that new events are available
 */
- (void)newEventsAvailable;

/*!
 @method trackingWebserviceDidSucceedForEvents:
 @abstract Inform the scheduler that the tracking webservice finished for the specified events
 */
- (void)trackingWebserviceDidSucceedForEvents:(NSArray *)array;

/*!
 @method trackingWebserviceDidFail:forEvents:
 @abstract Inform the scheduler that the tracking webservice finished for the specified events
 */
- (void)trackingWebserviceDidFail:(NSError *)error forEvents:(NSArray *)array;

@end
