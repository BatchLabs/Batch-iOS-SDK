//
//  BATWebserviceHMAC.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BATWebserviceHMACProtocol

/**
 Automatically appends the Content hash and HMAC headers
 */
- (void)appendToMutableRequest:(nonnull NSMutableURLRequest*)request;

/**
 Get the header name of the content hash

 Returns "Content-<algorithm>"
 Example: "Content-SHA1"
 */
- (nonnull NSString*)contentHashHeaderKey;

/**
 Get the body's hashed value that should be put in the headers
 See -contentHashHeaderKey for the HTTP header name

 Returns the hash in its base64 form.

 nil if an error occured
 */
- (nullable NSString*)hashedContent:(nonnull NSData*)content;

/**
 Get the header name for the HMAC
 */
- (nonnull NSString*)hmacHeaderKey;

/**
 Get the HMAC

 This doesn't add the content hash. If you wish to sign your content, use -contentHashHeaderKey and -hashedContent: to append the hash to the headers.
 This method should be called once your headers are final.
 */
- (nullable NSString*)hmacForMethod:(nonnull NSString*)method relativeURL:(nonnull NSString*)url headers:(nonnull NSDictionary<NSString*, NSString*>*)headers;

/**
 Returns the summary string that is signed using hmac
 For testing only
 */
- (nonnull NSString*)_requestSummaryForMethod:(nonnull NSString*)method relativeURL:(nonnull NSString*)url headers:(nonnull NSDictionary<NSString*, NSString*>*)headers;

/**
 Returns the filtered headers according to the allowlist
 For testing only
 */
- (nonnull NSDictionary<NSString*, NSString*>*)_filteredHeaders:(nonnull NSDictionary<NSString*, NSString*>*)headers;

/**
 Computes the SHA-256 hmac of the given data
 For testing only
 */
- (nonnull NSData*)_sha256HmacOf:(nonnull NSData*)data;

/**
 Extracts the relative URL string from a URL
 
 Example: https://batch.com/foo/bar?query=param returns /foo/bar?query=param
 For testing only
 */
- (nonnull NSString*)_extractRelativeURL:(nonnull NSURL*)url;

/**
 Extracts the header keys and sorts them
 We need to do that since we enumerate the keys in two different methods, and
 the order needs to be predictable so that we don't have a desync
 
 For testing only
 */
- (nonnull NSArray<NSString*>*)_sortedHeaderKeys:(nonnull NSDictionary<NSString*, NSString*>*)headers;

@end

/**
HMAC Implementation
Uses SHA 256 for the signature
SHA 1 for content checksum

Outputs them as Base64
 
Note: while this class exposes all methods needed to manually add HMAC in your NSURLRequest,
 you probably want to use -appendToMutableRequest: that handles everything.
*/
@interface BATWebserviceHMAC : NSObject <BATWebserviceHMACProtocol>

- (nonnull instancetype)init NS_UNAVAILABLE;

- (nullable instancetype)initWithKey:(nonnull NSString*)key NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
