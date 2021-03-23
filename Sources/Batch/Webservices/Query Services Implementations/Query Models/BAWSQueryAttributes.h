//
//  BAWebserviceQueryAttributes.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>

/*!
 @class BAWebserviceQueryAttributes
 @abstract Query that send attributes to the server.
 */
@interface BAWSQueryAttributes : BAWSQuery <BAWSQuery>

/*!
 @method init
 @warning Never call this method.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/*!
 @abstract Standard constructor.
 @param version     :   Data version
 @param attributes  :   Attributes(Array of BAUserAttribute)
 @param tags        :   Tags : Dictionary of string arrays with string keys
 @return Instance or nil.
 */
- (nonnull instancetype)initWithVersion:(long long)version
                             attributes:(nonnull NSDictionary *)attributes
                                andTags:(nonnull NSDictionary< NSString*, NSSet< NSString* >* >*)tags;

@end
