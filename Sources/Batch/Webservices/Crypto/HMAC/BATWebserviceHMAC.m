//
//  BATWebserviceHMAC.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BATWebserviceHMAC.h>
#import <Batch/BASHA.h>
#import <CommonCrypto/CommonCrypto.h>

#define DEBUG_DOMAIN @"BatchWebserviceHMAC"

@implementation BATWebserviceHMAC
{
    NSData *_key;
}

- (nullable instancetype)initWithKey:(NSString*)key
{
    self = [super init];
    if (self) {
        if ([BANullHelper isStringEmpty:key]) {
            return nil;
        }
        _key = [key dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (void)appendToMutableRequest:(nonnull NSMutableURLRequest*)request
{
    NSData *requestContent = request.HTTPBody;
    if (![BANullHelper isDataEmpty:requestContent]) {
        NSString *contentHash = [self hashedContent:requestContent];
        
        if (![BANullHelper isStringEmpty:contentHash]) {
            [request setValue:contentHash forHTTPHeaderField:self.contentHashHeaderKey];
        }
    }
    
    NSURL *url = request.URL;
    
    if (url == nil) {
        [BALogger debugForDomain:DEBUG_DOMAIN message:@"Cannot append to request: nil URL"];
        return;
    }
    
    NSString *hmac = [self hmacForMethod:request.HTTPMethod
                             relativeURL:[self _extractRelativeURL:url]
                                 headers:request.allHTTPHeaderFields];
    
    if ([BANullHelper isStringEmpty:hmac]) {
        [BALogger debugForDomain:DEBUG_DOMAIN message:@"Cannot append to request: nil or empty computed hmac"];
        return;
    }
    
    [request setValue:hmac forHTTPHeaderField:self.hmacHeaderKey];
}

- (nonnull NSString*)contentHashHeaderKey
{
    return @"Content-SHA1";
}

- (nullable NSString*)hashedContent:(nonnull NSData*)content
{
    return [[BASHA sha1HashOf:content] base64EncodedStringWithOptions:0];
}

- (nonnull NSString*)hmacHeaderKey
{
    return @"X-Batch-Signature";
}

- (nullable NSString*)hmacForMethod:(nonnull NSString*)method relativeURL:(nonnull NSString*)url headers:(nonnull NSDictionary<NSString*, NSString*>*)headers
{
    NSParameterAssert(method);
    NSParameterAssert(headers);
    
    headers = [self _filteredHeaders:headers];
    
    if ([BANullHelper isStringEmpty:url]) {
        url = @"/";
    }
    
    NSMutableString *hmacHeader = [NSMutableString new];
    
    [hmacHeader appendString:@"SHA256"];
    
    BOOL firstHeader = true;
    for (NSString *headerKey in [self _sortedHeaderKeys:headers]) {
        if (firstHeader) {
            firstHeader = false;
            [hmacHeader appendString:@" "];
        } else {
            [hmacHeader appendString:@","];
        }
        
        [hmacHeader appendString:[headerKey lowercaseString]];
    }
    
    [hmacHeader appendString:@" "];
    
    NSString *requestSummary = [self _requestSummaryForMethod:method relativeURL:url headers:headers];
    NSData *requestSummaryData = [requestSummary dataUsingEncoding:NSUTF8StringEncoding];
    
    [hmacHeader appendString:[[self _sha256HmacOf:requestSummaryData] base64EncodedStringWithOptions:0]];
    
    return hmacHeader;
}

- (nonnull NSString*)_requestSummaryForMethod:(nonnull NSString*)method relativeURL:(nonnull NSString*)url headers:(nonnull NSDictionary<NSString*, NSString*>*)headers
{
    NSMutableString *summary = [NSMutableString new];
    
    [summary appendString:[method uppercaseString]];
    [summary appendString:@" "];
    [summary appendString:url];
    
    NSArray<NSString*> *keys = [headers allKeys];
    // Sort to avoid unexpected behaviour when building the header list
    keys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (NSString *key in [self _sortedHeaderKeys:headers]) {
        [summary appendString:@"\n"];
        [summary appendString:[key lowercaseString]];
        [summary appendString:@": "];
        [summary appendString:headers[key]];
    }
    
    return summary;
}

- (nonnull NSDictionary<NSString*, NSString*>*)_filteredHeaders:(nonnull NSDictionary<NSString*, NSString*>*)headers
{
    // We don't exclude any header for now, but filter out empty ones
    NSMutableDictionary *filteredHeaders = [NSMutableDictionary dictionaryWithCapacity:headers.count];
    
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![BANullHelper isStringEmpty:obj]) {
            filteredHeaders[key] = obj;
        }
    }];
    
    return filteredHeaders;
}

- (nonnull NSData*)_sha256HmacOf:(nonnull NSData*)data
{
    NSParameterAssert(data);
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, _key.bytes, _key.length, data.bytes, (int)data.length, digest);
    
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

- (nonnull NSString*)_extractRelativeURL:(nonnull NSURL*)url
{
    NSParameterAssert(url);
    NSString *relativeURL = url.path;
    
    if ([BANullHelper isStringEmpty:relativeURL]) {
        relativeURL = @"/";
    }
    
    if (![relativeURL hasPrefix:@"/"]) {
        relativeURL = [@"/" stringByAppendingString:relativeURL];
    }
    
    NSString *query = url.query;
    
    if (![BANullHelper isStringEmpty:query]) {
        relativeURL = [NSString stringWithFormat:@"%@?%@", relativeURL, query];
    }
    
    return relativeURL;
}

- (nonnull NSArray<NSString*>*)_sortedHeaderKeys:(nonnull NSDictionary<NSString*, NSString*>*)headers
{
    // Sort to avoid unexpected behaviour when building the header list
    NSArray<NSString*> *keys = [headers allKeys];
    return [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end
