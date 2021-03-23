//
//  BAWSQueryTracking.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class BAWSQueryTracking
 @abstract Query that send events to the server.
 @discussion Used to send the events from the tracker
 */
@interface BAWSQueryTracking : BAWSQuery <BAWSQuery>

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @abstract Standard constructor.
 @param events      :   Events to send.
 */
- (instancetype)initWithEvents:(nonnull NSArray *)events;

@end

NS_ASSUME_NONNULL_END
