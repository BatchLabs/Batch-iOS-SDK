//
//  BAQueryWebserviceClientDelegate.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWSResponse.h>

@class BAQueryWebserviceClient;

NS_ASSUME_NONNULL_BEGIN

@protocol BAQueryWebserviceClientDelegate <NSObject>

@required

- (void)webserviceClientWillStart:(BAQueryWebserviceClient*)client;

- (void)webserviceClient:(BAQueryWebserviceClient*)client didFailWithError:(NSError *)error;

- (void)webserviceClient:(BAQueryWebserviceClient*)client didSucceedWithResponses:(NSArray<id<BAWSResponse>> *)responses;

@end

NS_ASSUME_NONNULL_END
