//
//  BAStandardQueryWebserviceIdentifiersProvider.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAStandardQueryWebserviceIdentifiersProvider.h>

#import <Batch/BABundleInfo.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAParameter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/Batch-Swift.h>

@implementation BAStandardQueryWebserviceIdentifiersProvider

+ (instancetype)sharedInstance {
    static BAStandardQueryWebserviceIdentifiersProvider *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [BAStandardQueryWebserviceIdentifiersProvider new];
    });
    return instance;
}

- (NSDictionary<NSString *, NSString *> *)identifiers {
    return [[BATDataCollectionCenter sharedInstance] buildIdsForQuery];
}

@end
