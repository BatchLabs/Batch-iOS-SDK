//
//  BAWebserviceQuery.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol BAWebserviceQuery
 @abstract Commom implementation for all queries.
 @discussion Usage of all queries.
 */
@protocol BAWSQuery <NSObject>

@required

- (nonnull NSString *)identifier;

- (nonnull NSString *)type;

/*!
 @method objectToSend
 @abstract Build the basic object to send to the server as a query.
 @return Query dictionary representation.
 */
- (nonnull NSDictionary *)objectToSend;

@end

/*!
 @class BAWebserviceQuery
 @abstract Common queries implementation.
 @discussion Do not instantiate this class directly, use one of the typed queries.
 */
@interface BAWSQuery : NSObject <BAWSQuery>

/*!
 @property identifier
 @abstract Unique query identifier string.
 */
@property (strong, readonly, nonnull) NSString *identifier;

/*!
 @property type
 @abstract Query type
 */
@property (strong, readonly, nonnull) NSString *type;

/*!
 @method objectToSend
 @abstract Build the basic object to send to the server as a query.
 @return Query dictionary representation.
 */
- (nonnull NSMutableDictionary *)objectToSend;

- (nonnull instancetype)initWithType:(nonnull NSString *)string;

@end
