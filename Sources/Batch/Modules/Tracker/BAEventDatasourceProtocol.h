//
//  BAEventDatasourceProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAEvent.h>
#import <Foundation/Foundation.h>

/*!
 @protocol BAEventDatasourceProtocol
 @abstract Protocol defining methods for accessing an event datasource
 */
@protocol BAEventDatasourceProtocol <NSObject>

/*!
 @method close
 @abstract Close the database. You should call this before deallocing it
 */
- (void)close;

/*!
 @method clear
 @abstract Clear the database. Should only be used for tests;
 */
- (void)clear;

/*!
 @method addEvent:
 @abstract Persist an event to the datasource
 @param event    :   The event to persist.
 */
- (BOOL)addEvent:(BAEvent *)event __attribute__((warn_unused_result));

/*!
 @method eventsToSend:
 @abstract Get the specified number of last events that can be sent (State is NEW or OLD)
 @param count    :   The number of events to get. Use 0 to get all the events.
 @return Array of BAEvent
 */
- (NSArray *)eventsToSend:(NSUInteger)count __attribute__((warn_unused_result));

/*!
 @method updateEventsStateFrom:to:
 @abstract Change the state of all events matching a state to a new one
 @param fromState    :   State to update from (Use BAEventStateAll to update all events)
 @param toState      :   State to update to
 */
- (void)updateEventsStateFrom:(BAEventState)fromState to:(BAEventState)toState;

/*!
 @method updateEventsStateTo:forEventsIdentifier:
 @abstract Change the state of all events matching the supplied IDs
 @param state   :   State to update to
 @param events  :   Event IDs to update (NSArray of NSString)
 */
- (void)updateEventsStateTo:(BAEventState)state forEventsIdentifier:(NSArray *)events;

/*!
 @method deleteEvents:
 @abstract Delete the specified events
 @param eventIdentifiers    :   Array containing the IDs of the events to delete
 */
- (void)deleteEvents:(NSArray *)eventIdentifiers;

/*!
 @method hasEventsToSend
 @abstract Wether the database contains events to send or not
 @return YES if the database contains events to send, NO otherwise
 */
- (BOOL)hasEventsToSend __attribute__((warn_unused_result));

/*!
 @method deleteEventsOlderThanTheLast:
 @abstract Try to delete all events reccorded before the number of events set in `eventNumber`
 @param eventNumber : Number of events to keep.
 */
- (void)deleteEventsOlderThanTheLast:(NSUInteger)eventNumber;

@end
