//
//  BAConnectionProtocol.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @protocol BAConnectionProtocol
 @abstract Delegate protocol for asynchronous connection.
 @discussion Similar to NSURLConnection delegate.
 */
@protocol BAConnectionDelegate <NSObject>

@required

/*!
 @method connectionWillStart
 @abstract Called when the connection will start. Useful for metrics. Careful, can be called on the main thread.
 */
- (void)connectionWillStart;

/*!
 @method connectionFailedWithError:
 @abstract Called when the connection has failed and uses all the retry policy.
 @param error   : The failure reason.
 */
- (void)connectionFailedWithError:(NSError *)error;

/*!
 @method connectionDidFinishLoadingWithData:
 @abstract Called when the connection has succed, return (uncrypted) data.
 @param data    : The data returned by the connection.
 */
- (void)connectionDidFinishLoadingWithData:(NSData *)data;

/*!
 @method connectionDidFinishSuccessfully:
 @abstract Called when the connection did finish, telling if it succeeded (success is when the SDK managed to decrypt
 the answer, before parsing it). Note that this can be called before or after connectionDidFinishLoadingWithData: no
 guarantees about the order are made
 */
- (void)connectionDidFinishSuccessfully:(BOOL)success;

@end
