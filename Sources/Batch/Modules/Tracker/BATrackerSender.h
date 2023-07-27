//
//  BATrackerSender.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BATrackerSender
 @abstract Treat the tracker webservice execution.
 @discussion This object is responsible for finding the right events to send, send them when asked, and handle their
 state.
 */
@interface BATrackerSender : NSObject

/*!
 @method send
 @abstract Send the events to the server
 @return YES if the webservice has been started by calling this method or the webservice was already running, NO if no
 events were available to send or sending is disabled.
 */
- (BOOL)send __attribute__((warn_unused_result));

/*!
 @method trackingWebserviceDidFinish:forEvents:
 @abstract Inform the scheduler that the tracking webservice finished for the specified events
 */
- (void)trackingWebserviceDidFinish:(BOOL)success forEvents:(NSArray *)array;

@end
