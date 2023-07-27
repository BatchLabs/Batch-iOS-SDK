//
//  BAWebserviceURLBuilder.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAWebserviceURLBuilder : NSObject

+ (nullable NSURL *)webserviceURLForShortname:(nonnull NSString *)shortname;

+ (nullable NSURL *)webserviceURLForShortname:(nonnull NSString *)shortname apiKey:(nonnull NSString *)apiKey;

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host shortname:(nonnull NSString *)shortname;

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host;

+ (nullable NSURL *)webserviceURLForHost:(nonnull NSString *)host
                               shortname:(nonnull NSString *)shortname
                                  apiKey:(nonnull NSString *)apiKey;

@end

NS_ASSUME_NONNULL_END
