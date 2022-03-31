//
//  BAUserDataManager.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAUserDataManager.h>

#import <Batch/BAInjection.h>
#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/BAUserSQLiteDatasource.h>

#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BAUserDataServices.h>
#import <Batch/BAWebserviceClientExecutor.h>

@implementation BAUserDataManager

static NSLock *baUserDataManagerCheckScheduledLock;
static BOOL baUserDataManagerCheckScheduled = NO;

+ (void)load {
    baUserDataManagerCheckScheduledLock = [NSLock new];
}

+ (dispatch_queue_t)sharedQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      queue = dispatch_queue_create("com.batch.userprofile.queue", NULL);
    });

    return queue;
}

+ (void)startAttributesSendWSWithDelay:(long long)delay {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), [BAUserDataManager sharedQueue], ^{
          id<BAUserDatasourceProtocol> database = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];

          if (database == nil) {
              [BALogger errorForDomain:@"BAUserDataManager"
                               message:@"Could not send attributes to backend, missing database."];
              return;
          }

          NSNumber *changeset = [BAParameter objectForKey:kParametersUserProfileDataVersionKey fallback:@(1)];
          // Sanity
          if (![changeset isKindOfClass:[NSNumber class]]) {
              changeset = @(1);
              [BAParameter setValue:changeset forKey:kParametersUserProfileDataVersionKey saved:YES];
          }

          NSDictionary *attributes = [BAUserAttribute serverJsonRepresentationForAttributes:[database attributes]];

          BAUserDataSendServiceDatasource *wsDatasource;
          wsDatasource = [[BAUserDataSendServiceDatasource alloc] initWithVersion:[changeset longLongValue]
                                                                       attributes:attributes
                                                                          andTags:[database tagCollections]];

          BAQueryWebserviceClient *ws =
              [[BAQueryWebserviceClient alloc] initWithDatasource:wsDatasource
                                                         delegate:[BAUserDataSendServiceDelegate new]];

          [BAWebserviceClientExecutor.sharedInstance addClient:ws];
        });
}

+ (void)startAttributesCheckWSWithDelay:(long long)delay {
    [baUserDataManagerCheckScheduledLock lock];
    baUserDataManagerCheckScheduled = YES;
    [baUserDataManagerCheckScheduledLock unlock];

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC)), [BAUserDataManager sharedQueue], ^{
          BOOL shouldStop = NO;

          [baUserDataManagerCheckScheduledLock lock];
          // Stop if a check wasn't scheduled (meaning it was already done by another scheduled check)
          // No need to spam with checks!
          shouldStop = !baUserDataManagerCheckScheduled;
          baUserDataManagerCheckScheduled = NO;
          [baUserDataManagerCheckScheduledLock unlock];

          if (shouldStop) {
              return;
          }

          NSNumber *changeset = [BAParameter objectForKey:kParametersUserProfileDataVersionKey fallback:@(0)];

          NSString *trid = [BAParameter objectForKey:kParametersUserProfileTransactionIDKey fallback:nil];
          if (![trid isKindOfClass:[NSString class]] || [trid length] == 0) {
              // No need to send a check if we don't have a transaction ID.
              // If we do have a valid data version though, send the data.

              if ([changeset isKindOfClass:[NSNumber class]] && [changeset longLongValue] > 0) {
                  [BAUserDataManager startAttributesSendWSWithDelay:0];
              }

              return;
          }

          // Check if our changeset is okay before proceeding
          if (![changeset isKindOfClass:[NSNumber class]] || [changeset longLongValue] <= 0) {
              changeset = @(1);
              [BAParameter setValue:changeset forKey:kParametersUserProfileDataVersionKey saved:YES];
          }

          BAUserDataCheckServiceDatasource *wsDatasource;
          wsDatasource = [[BAUserDataCheckServiceDatasource alloc] initWithVersion:[changeset longLongValue]
                                                                     transactionID:trid];

          BAQueryWebserviceClient *ws =
              [[BAQueryWebserviceClient alloc] initWithDatasource:wsDatasource
                                                         delegate:[BAUserDataCheckServiceDelegate new]];

          [BAWebserviceClientExecutor.sharedInstance addClient:ws];
        });
}

+ (void)storeTransactionID:(NSString *)transaction forVersion:(NSNumber *)version {
    if (![transaction isKindOfClass:[NSString class]] || ![version isKindOfClass:[NSNumber class]]) {
        return;
    }

    dispatch_async([BAUserDataManager sharedQueue], ^{
      NSNumber *changeset = [BAParameter objectForKey:kParametersUserProfileDataVersionKey fallback:@(0)];
      if (![changeset isKindOfClass:[NSNumber class]]) {
          changeset = @(0);
      }

      if ([version isEqualToNumber:changeset]) {
          [BAParameter setValue:transaction forKey:kParametersUserProfileTransactionIDKey saved:YES];

          [BALogger debugForDomain:@"BAUserDataManager" message:@"Send successful, checking in 15s (%@)", transaction];
          // Check in 15s
          [BAUserDataManager startAttributesCheckWSWithDelay:15000];
      } else {
          [BALogger debugForDomain:@"BAUserDataManager"
                           message:@"Wrong changeset (ours: %@, server %@), resending", changeset, version];
          // Send in 15s
          [BAUserDataManager startAttributesSendWSWithDelay:15000];
      }
    });
}

+ (void)updateWithServerDataVersion:(long long)serverVersion {
    dispatch_async([BAUserDataManager sharedQueue], ^{
      NSNumber *changeset = [BAParameter objectForKey:kParametersUserProfileDataVersionKey fallback:@(0)];
      if (![changeset isKindOfClass:[NSNumber class]]) {
          changeset = @(0);
      }

      long long targetVersion = serverVersion + 1;

      if ([changeset longLongValue] < targetVersion) {
          [BAParameter setValue:@(targetVersion) forKey:kParametersUserProfileDataVersionKey saved:YES];
          [BAParameter removeObjectForKey:kParametersUserProfileTransactionIDKey];
          [BAUserDataManager startAttributesSendWSWithDelay:0];
      } else {
          // We probably corrected this already
      }
    });
}

+ (void)printDebugInformation {
    dispatch_async([BAUserDataManager sharedQueue], ^{
      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      [datasource printDebugDump];
    });
}

+ (void)clearData {
    [baUserDataManagerCheckScheduledLock lock];
    baUserDataManagerCheckScheduled = NO;
    [baUserDataManagerCheckScheduledLock unlock];

    dispatch_async([BAUserDataManager sharedQueue], ^{
      [BAParameter removeObjectForKey:kParametersUserProfileDataVersionKey];
      [BAParameter removeObjectForKey:kParametersUserProfileTransactionIDKey];

      id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
      [datasource clear];
    });
}

@end
