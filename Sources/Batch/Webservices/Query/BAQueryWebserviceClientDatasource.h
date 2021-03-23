//
//  BAQueryWebserviceClientDatasource.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAWSQuery.h>
#import <Batch/BAWSResponse.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A protocol that objects adopt to provide all of the data a QueryWebservice needs to operate
 */
@protocol BAQueryWebserviceClientDatasource <NSObject>

@required

/**
 URL to send the request to
 */
@property (nullable, readonly) NSURL* requestURL;

/**
 Long identifier for this kind of request. Used for logging & deubgging
 Ex: start, attributesSend, localCampaigns
 */
@property (readonly) NSString* requestIdentifier;

/**
 Short identifier for this kind of request. Often matches the url fragment that designated this ws
 Ex: start, ats, ev
 
 Will be used for metrics too
 */
@property (readonly) NSString* requestShortIdentifier;

/**
 Queries to send to the webservice
 */
@property (readonly) NSArray<id<BAWSQuery>>* queriesToSend;

/**
 Should return the query response for the given source query and response data
 Returning nil makes the complete request fail
 */
- (nullable BAWSResponse *)responseForQuery:(BAWSQuery *)query
                                    content:(NSDictionary *)content;

@end

NS_ASSUME_NONNULL_END
