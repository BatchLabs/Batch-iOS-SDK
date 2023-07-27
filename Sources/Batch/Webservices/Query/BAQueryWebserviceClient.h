//
//  BAQueryWebserviceClient.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAConnectionDelegate.h>
#import <Batch/BAWSQuery.h>
#import <Batch/BAWSResponse.h>
#import <Batch/BAWebserviceJsonClient.h>

#import <Batch/BAQueryWebserviceClientDatasource.h>
#import <Batch/BAQueryWebserviceClientDelegate.h>
#import <Batch/BAQueryWebserviceIdentifiersProviding.h>

/*!
 @class BAQueryWebservice
 @abstract The unique webservice consumer.
 @discussion Adaptive webservice object.
 */
@interface BAQueryWebserviceClient : BAWebserviceJsonClient <BAConnectionDelegate>

/*!
 @method init
 @warning Never call this method.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

- (nonnull instancetype)initWithDatasource:(nonnull id<BAQueryWebserviceClientDatasource>)datasource
                                  delegate:(nullable id<BAQueryWebserviceClientDelegate>)delegate;

- (nonnull instancetype)initWithDatasource:(nonnull id<BAQueryWebserviceClientDatasource>)datasource
                                  delegate:(nullable id<BAQueryWebserviceClientDelegate>)delegate
                       identifiersProvider:(nonnull id<BAQueryWebserviceIdentifiersProviding>)identifiersProvider;

@end
