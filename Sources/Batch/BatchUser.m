//
//  BatchUser.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAInjectable.h>
#import <Batch/BAInstallDataEditor.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserProfile.h>
#import <Batch/BAUserSQLiteDatasource.h>
#import <Batch/BatchEventAttributesPrivate.h>
#import <Batch/BatchUser.h>
#import <Batch/BatchUserAttribute.h>
#import <Batch/BatchUserAttributePrivate.h>

#define EVENT_NAME_REGEXP @"^[a-zA-Z0-9_]{1,30}$"

NSString *const BatchEventTrackerFinishedNotification = @"BatchEventTrackerFinishedNotification";

NSString *const BatchEventTrackerFinishedWithSuccessKey = @"BatchEventTrackerFinishedWithSuccessKey";

@implementation BatchUser

+ (nullable NSString *)installationID {
    return [[BAPropertiesCenter valueForShortName:@"di"] uppercaseString];
}

+ (nonnull NSString *)language {
    NSString *savedLanguage = [[BAUserProfile defaultUserProfile] language];
    return savedLanguage;
}

+ (nonnull NSString *)region {
    NSString *savedRegion = [[BAUserProfile defaultUserProfile] region];
    return savedRegion;
}

+ (nullable NSString *)identifier {
    return [[BAUserProfile defaultUserProfile] customIdentifier];
}

+ (void)fetchAttributes:(void (^)(NSDictionary<NSString *, BatchUserAttribute *> *_Nullable))completionHandler {
    dispatch_async([BAUserDataManager sharedQueue], ^{
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      NSDictionary<NSString *, BAUserAttribute *> *privateAttributes = [datasource attributes];
      NSMutableDictionary<NSString *, BatchUserAttribute *> *publicAttributes = [NSMutableDictionary new];
      for (NSString *key in privateAttributes) {
          BAUserAttribute *privateAttribute = privateAttributes[key];

          BatchUserAttributeType publicType;
          switch (privateAttribute.type) {
              case BAUserAttributeTypeBool:
                  publicType = BatchUserAttributeTypeBool;
                  break;
              case BAUserAttributeTypeDate:
                  publicType = BatchUserAttributeTypeDate;
                  break;
              case BAUserAttributeTypeString:
                  publicType = BatchUserAttributeTypeString;
                  break;
              case BAUserAttributeTypeLongLong:
                  publicType = BatchUserAttributeTypeLongLong;
                  break;
              case BAUserAttributeTypeDouble:
                  publicType = BatchUserAttributeTypeDouble;
                  break;
              case BAUserAttributeTypeURL:
                  publicType = BatchUserAttributeTypeURL;
                  break;
              default:
                  continue; // We skip attributes whose type is not dealt with above.
                  break;
          }

          BatchUserAttribute *publicAttribute = [[BatchUserAttribute alloc] initWithValue:privateAttribute.value
                                                                                     type:publicType];

          // Clean the key so that it is equal to the one used when setting the attribute.
          NSString *userKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
          publicAttributes[userKey] = publicAttribute;
      }

      dispatch_async(dispatch_get_main_queue(), ^{
        completionHandler([publicAttributes copy]);
      });
    });
}

+ (void)fetchTagCollections:(void (^)(NSDictionary<NSString *, NSSet<NSString *> *> *_Nullable))completionHandler {
    dispatch_async([BAUserDataManager sharedQueue], ^{
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      NSDictionary<NSString *, NSSet<NSString *> *> *tagCollections = [datasource tagCollections];
      dispatch_async(dispatch_get_main_queue(), ^{
        completionHandler(tagCollections);
      });
    });
}

+ (void)clearInstallationData {
    [BAUserDataManager clearRemoteInstallationDataWithCompletion:nil];
}

@end
