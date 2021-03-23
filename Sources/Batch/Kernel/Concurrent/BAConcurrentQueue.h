//
//  BAConcurrentQueue.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAConcurrentQueue
 @abstract Thread-safe queue
 @discussion This very basic queue implementation is made for MPSC (Multi-producer single-consumer).
 @discussion libdispatch handles push/poll thread safety behind the curtains.
 */
@interface BAConcurrentQueue : NSObject

/*!
 @method push:
 @abstract Push an object to the tail of the queue
 @param object         :   The object to push. Cannot be nil.
 */
- (void)push:(NSObject *)object;

/*!
 @method poll
 @abstract Retrieves and removes the head of this queue, or returns nil if this queue is empty.
 @return the head of this queue, or nil if this queue is empty.
 */
- (NSObject *)poll;

/*!
 @method poll
 @abstract Retrieves and removes the head the entirety of this queue, or returns an empty array if this queue is empty.
 @return array representation of this queue
 */
- (NSArray *)pollAll;

/*!
 @method empty
 @abstract Returns if this queue contains no elements.
 @return YES if this queue has no elements, NO otherwise.
 */
- (BOOL)empty;

/*!
 @method clear
 @abstract Remove all objects in the queue
 */
- (void)clear;

/*!
 @method count
 @abstract Returns the number of objects currently in the array.
 @return The number of objects currently in the array.
 */
- (NSUInteger)count;

@end
