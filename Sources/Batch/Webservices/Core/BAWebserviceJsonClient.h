//
//  BAWebserviceJsonClient.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceClient.h>

/*!
 @class BAWebserviceJsonClient
 @abstract Abstract class that group common methods for all webservices that handle JSON in requests.
 @warning This class is not mean to be instanciated, you should only instanciate childrens.
 */
@interface BAWebserviceJsonClient : BAWebserviceClient

- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL*)url
                               delegate:(nullable id<BAConnectionDelegate>)delegate;

/*
Body parameters to add
Unused for GET requests
*/
- (nonnull NSMutableDictionary *)requestBodyDictionary;

@end
