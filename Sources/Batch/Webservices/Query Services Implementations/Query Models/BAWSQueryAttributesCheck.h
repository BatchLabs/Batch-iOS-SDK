//
//  BAWSQueryAttributesCheck.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWSQuery.h>

/*!
 @class BAWSQueryAttributesCheck
 @abstract Query that send attributes to the server.
 */
@interface BAWSQueryAttributesCheck : BAWSQuery <BAWSQuery>

/*!
 @method init
 @warning Never call this method.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/*!
 @abstract Standard constructor.
 @param transaction :   The transaction ID
 @param version     :   Database version
 @return Instance or nil.
 */
- (nonnull instancetype)initWithTransactionID:(nonnull NSString *)transaction
                                   andVersion:(long long)version;

@end
