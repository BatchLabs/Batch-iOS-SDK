//
//  BATGZIP.h
//  Batch
//
//  Copyright © 2020 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BATGZIP: NSObject

// Gzip data. If the data is already Gzipped, this returns the original data
+ (nullable NSData *)dataByGzipping:(nullable NSData *)data;

// Gunzip data. If the data isn't Gzipped, this returns the original data
+ (nullable NSData *)dataByGunzipping:(nullable NSData *)data;

@end
