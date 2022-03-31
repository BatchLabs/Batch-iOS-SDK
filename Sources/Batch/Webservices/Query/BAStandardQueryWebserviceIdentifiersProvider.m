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
    NSMutableDictionary *ids = [[NSMutableDictionary alloc] init];
    // Always add the installation id
    NSString *di = [BAPropertiesCenter valueForShortName:@"di"];
    if (![BANullHelper isStringEmpty:di]) {
        ids[@"di"] = di;
    }

    // Grab the identifiers list.
    NSString *idsList = [BAParameter objectForKey:kParametersIDsPatternKey fallback:kParametersIDsPatternValue];
    NSArray *baseIds = [idsList componentsSeparatedByString:@","];

    NSString *advancedIdsList = [BAParameter objectForKey:kParametersAdvancedIDsPatternKey
                                                 fallback:kParametersAdvancedIDsPatternValue];
    NSArray *advancedIds = nil;

    if (![BANullHelper isStringEmpty:advancedIdsList] &&
        [[BACoreCenter instance].configuration useAdvancedDeviceInformation]) {
        advancedIds = [advancedIdsList componentsSeparatedByString:@","];
    }

    NSMutableArray<NSString *> *idsToFetch =
        [[NSMutableArray alloc] initWithCapacity:(baseIds.count + advancedIds.count)];
    if (baseIds) {
        [idsToFetch addObjectsFromArray:baseIds];
    }
    if (advancedIds) {
        [idsToFetch addObjectsFromArray:advancedIds];
    }

    // As of 1.17, "idfa" isn't hardcoded in the pattern anymore
    // Add it to the list of IDs to be fetched if we have compile-time support for it
#if BATCH_ENABLE_IDFA
    [idsToFetch addObject:@"idfa"];
#endif

    // Add references.
    for (NSString *idName in idsToFetch) {
        if (![BANullHelper isStringEmpty:idName]) {
            NSString *propertyValue = [BAPropertiesCenter valueForShortName:idName];
            if (![BANullHelper isStringEmpty:propertyValue]) {
                [ids setObject:propertyValue forKey:idName];
            }
        }
    }

    return ids;
}

@end
