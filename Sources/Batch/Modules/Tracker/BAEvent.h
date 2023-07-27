//
//  BAEvent.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAEventLight;

/*!
 @enum BAEventState
 @abstract Event state
 */
enum {
    BAEventStateAll = -1, // Value not meant to be stored in SQLite
    BAEventStateNew = 0,
    BAEventStateSending = 1,
    BAEventStateSent = 2,
    BAEventStateOld = 3
};

/*!
 @typedef BAEventState
 */
typedef NSInteger BAEventState;

/*!
 @class BAEvent
 @abstract Event representation
 @discussion Represents a event that happened in the application. Immutable.
 */
@interface BAEvent : NSObject

/*!
 @property identifier
 @abstract Event UUID.
 */
@property (strong, nonatomic, readonly) NSString *identifier;

/*!
 @property date
 @abstract Event date.
 */
@property (strong, nonatomic, readonly) NSString *date;

/*!
 @property secureDate
 @abstract Event secure date.
 */
@property (strong, nonatomic, readonly) NSString *secureDate;

/*!
 @property name
 @abstract Event name.
 */
@property (strong, nonatomic, readonly) NSString *name;

/*!
 @property parameters
 @abstract Event parameters. Can be empty or nil.
 */
@property (strong, nonatomic, readonly) NSString *parameters;

/*!
 @property parametersDictionary
 @abstract Event parameters dictionary used during initialization. Can be nil.
 */
@property (strong, nonatomic, readonly) NSDictionary *parametersDictionary;

/*!
 @property parameters
 @abstract Last known server tick when the event happened.
 */
@property (assign, nonatomic, readonly) long long tick;

/*!
 @property session
 @abstract Session ID on which the event happened
 */
@property (strong, nonatomic, readonly) NSString *session;

/*!
 @property parameters
 @abstract Event state.
 */
@property (readonly) BAEventState state;

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method initWithName:
 @abstract Constructor from a name
 @param name        :   Event name
 @return Instance.
 */
- (instancetype)initWithName:(NSString *)name __attribute__((warn_unused_result));

/*!
 @method initWithName:andParameters:
 @abstract Constructor from a name and parameters
 @param name        :   Event name
 @param parameters  :   Event parameters
 @return Instance.
 */
- (instancetype)initWithName:(NSString *)name
               andParameters:(NSDictionary *)parameters __attribute__((warn_unused_result));

/*!
 @method initWithIdentifier:name:date:parameters:state:andTick:
 @abstract Constructor from the SQL representation.
 @return Instance.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                              date:(NSString *)date
                        parameters:(NSString *)parameters
                             state:(BAEventState)state
                           session:(NSString *)session
                           andTick:(long long)tick __attribute__((warn_unused_result));

/*!
 @method initWithIdentifier:name:date:secureDate:parameters:state:andTick:
 @abstract Constructor from the SQL representation.
 @return Instance.
 */
- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                              date:(NSString *)date
                        secureDate:(NSString *)secureDate
                        parameters:(NSString *)parameters
                             state:(BAEventState)state
                           session:(NSString *)session
                           andTick:(long long)tick __attribute__((warn_unused_result));

/*!
 @method eventWithName:
 @abstract Constructor from a name
 @param name        :   Event name
 @return Instance.
 */
+ (instancetype)eventWithName:(NSString *)name __attribute__((warn_unused_result));

/*!
 @method eventWithName:andParameters:
 @abstract Constructor from a name and parameters
 @param name        :   Event name
 @param parameters  :   Event parameters
 @return Instance.
 */
+ (instancetype)eventWithName:(NSString *)name
                andParameters:(NSDictionary *)parameters __attribute__((warn_unused_result));

/*!
 @method eventWithIdentifier:name:date:parameters:state:andTick:
 @abstract Constructor from the SQL representation.
 @return Instance.
 */
+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick __attribute__((warn_unused_result));

/*!
 @method eventWithIdentifier:name:date:secureDate:parameters:state:andTick:
 @abstract Constructor from the SQL representation.
 @return Instance.
 */
+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         secureDate:(NSString *)secureDate
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick __attribute__((warn_unused_result));

/*!
 @method identifiersOfEvents:
 @abstract Build the list of identifiers from the BAEvent list.
 @param events : The list of BAEvent to retrieve identifiers from.
 @return The list of identifiers or empty.
 */
+ (NSArray *)identifiersOfEvents:(NSArray *)events __attribute__((warn_unused_result));

@end

/**
 A collapsable event is an event that only keeps the last occurrence in the database
 */
@interface BACollapsableEvent : BAEvent
@end
