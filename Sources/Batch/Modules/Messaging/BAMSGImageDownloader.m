//
//  BAMSGImageDownloader.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BAMSGImageDownloader.h>
#import <Batch/BATGIFFile.h>
#import "BATMessagingCloseErrorCause.h"

@implementation BAMSGImageDownloader

+ (void)downloadImageForURL:(NSURL *_Nonnull)url
            downloadTimeout:(NSTimeInterval)timeout
          completionHandler:(void (^__nonnull)(NSData *_Nullable rawData,
                                               BOOL isGif,
                                               UIImage *_Nullable image,
                                               NSError *_Nullable error))completionHandler;
{
    if (!completionHandler) {
        return;
    }

    if ([url isFileURL]) {
        const char *filesystemRepresentation = url.fileSystemRepresentation;
        if (filesystemRepresentation != NULL && filesystemRepresentation[0] != '\0') {
            // We have a non-empty FS representation string (that is, file:///Applications/... without the file://
            NSString *localImagePath = [NSString stringWithCString:filesystemRepresentation
                                                          encoding:NSUTF8StringEncoding];

            NSData *imageData = [NSData dataWithContentsOfFile:localImagePath];

            if (imageData == nil) {
                completionHandler(
                    nil, false, nil,
                    [NSError
                        errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                   code:-5
                               userInfo:@{NSLocalizedDescriptionKey : @"Unable to create NSData from local file"}]);
                return;
            }

            if ([BATGIFFile isPotentiallyAGif:imageData]) {
                completionHandler(imageData, true, nil, nil);
                return;
            }

            UIImage *image = [UIImage imageWithData:imageData];

            if (image != nil) {
                completionHandler(imageData, false, image, nil);
            } else {
                completionHandler(
                    nil, false, nil,
                    [NSError
                        errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                   code:-6
                               userInfo:@{NSLocalizedDescriptionKey : @"Unable to create UIImage from local file"}]);
            }

            return;
        }
    }

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForResource = timeout;
    // Enforce TLS 1.2
    config.TLSMinimumSupportedProtocolVersion = tls_protocol_version_TLSv12;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];

    NSURLSessionDataTask *task = [session
          dataTaskWithURL:url
        completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error) {
          if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
              if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
                  completionHandler(
                      nil, false, nil,
                      error
                          ? error
                          : [NSError
                                errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                           code:-1
                                       userInfo:@{
                                           NSLocalizedDescriptionKey : [NSString
                                               stringWithFormat:@"Server returned a non successful statuscode (%ld)",
                                                                (long)httpResponse.statusCode],
                                           kBATMessagingCloseErrorCauseKey : @(BATMessagingCloseErrorCauseServerFailure)
                                       }]);
                  return;
              }

              if (!data) {
                  completionHandler(nil, false, nil,
                                    error ? error
                                          : [NSError errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                                                code:-2
                                                            userInfo:@{
                                                                NSLocalizedDescriptionKey : @"Response data is nil",
                                                                kBATMessagingCloseErrorCauseKey :
                                                                    @(BATMessagingCloseErrorCauseInvalidResponse)
                                                            }]);
                  return;
              }

              if ([BATGIFFile isPotentiallyAGif:data]) {
                  completionHandler(data, true, nil, nil);
                  return;
              }

              UIImage *image = [UIImage imageWithData:data];

              if (!image) {
                  completionHandler(
                      nil, false, nil,
                      error ? error
                            : [NSError errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                                  code:-3
                                              userInfo:@{
                                                  NSLocalizedDescriptionKey : @"Unable to create UIImage from data",
                                                  kBATMessagingCloseErrorCauseKey :
                                                      @(BATMessagingCloseErrorCauseInvalidResponse)
                                              }]);
                  return;
              }

              completionHandler(data, false, image, nil);
          } else {
              completionHandler(
                  nil, false, nil,
                  error ? error
                        : [NSError
                              errorWithDomain:@"com.batch.ios.BAMSGImageDownloaderError"
                                         code:-4
                                     userInfo:@{
                                         NSLocalizedDescriptionKey : @"Response was not a NSHTTPURLResponse",
                                         kBATMessagingCloseErrorCauseKey : @(BATMessagingCloseErrorCauseServerFailure)
                                     }]);
              return;
          }
        }];

    [task resume];
}

@end
