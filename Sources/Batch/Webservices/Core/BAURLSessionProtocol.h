//
//  BAURLSessionProtocol.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/**
 Protocol defining expected methods on a NSURLSession-like object to perform network requests

 Production implementations should forward the calls to a configured NSURLSession instance.
 Allows to easily mock NSURLSession
 */
@protocol BAURLSessionProtocol <NSObject>

@required
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *_Nullable data,
                                                        NSURLResponse *_Nullable response,
                                                        NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
