//
//  BAMSGImageDownloader.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAMSGImageDownloader : NSObject

+ (void)downloadImageForURL:(NSURL *_Nonnull)url
            downloadTimeout:(NSTimeInterval)timeout
          completionHandler:(void (^__nonnull)(NSData *_Nullable rawData,
                                               BOOL isGif,
                                               UIImage *_Nullable image,
                                               NSError *_Nullable error))completionHandler;

@end
