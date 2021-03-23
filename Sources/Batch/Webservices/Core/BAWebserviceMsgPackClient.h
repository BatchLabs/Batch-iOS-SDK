//
//  BAWebserviceMsgPackClient.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceClient.h>

/*!
 @class BAWebserviceMsgPackClient
 @abstract Abstract class that group common methods for all webservices that handle MsgPack in requests.
 You should override "requestBody" and "requestHeaders" to provide data
 @warning This class is not mean to be instanciated, you should only instanciate childrens.
 */
@interface BAWebserviceMsgPackClient : BAWebserviceClient

- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL*)url
                               delegate:(nullable id<BAConnectionDelegate>)delegate;

@end
