//
//  BAUserDataManager.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BAUserDataManager.h>

#import <Batch/BACoreCenter.h>
#import <Batch/BAInjection.h>
#import <Batch/BALogger.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAParameter.h>
#import <Batch/BAQueryWebserviceClient.h>
#import <Batch/BATrackerCenter.h>
#import <Batch/BAUserDataDiff.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserDataServices.h>
#import <Batch/BAUserDatasourceProtocol.h>
#import <Batch/BAUserSQLiteDatasource.h>
#import <Batch/BAWebserviceClientExecutor.h>

#define PUBLIC_DOMAIN @"BatchUser - Manager"
#define DEBUG_DOMAIN @"UserDataManager"

/// Waiting time before operations are submitted (in ms)
#define DISPATCH_QUEUE_TIMER 500

@implementation BAUserDataManager

static NSLock *baUserDataManagerCheckScheduledLock;
static BOOL baUserDataManagerCheckScheduled = NO;
static NSMutableArray<NSArray<BOOL (^)(void)> *> *operationsQueues;

+ (void)load {
    baUserDataManagerCheckScheduledLock = [NSLock new];
    operationsQueues = [NSMutableArray new];
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

+ (void)clearRemoteInstallationDataWithCompletion:(void (^)(void))completion {
    // addOperationQueueAndSubmit is not thread safe, we need to use the queue
    dispatch_async([BAUserDataManager sharedQueue], ^{
      if (![self canSave]) {
          if (completion != nil) {
              completion();
          }
          return;
      }
      [BAUserDataManager _performClearRemoteInstallationDataWithCompletion:completion];
    });
}

/// Thread unsafe method that performs the clear without any checks
/// The only reason this exists is to write tests as BAUserDataManager is not easily testable at all
+ (void)_performClearRemoteInstallationDataWithCompletion:(void (^)(void))completion {
    NSArray<BOOL (^)(void)> *applyQueue = @[
        ^BOOL {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource clearTags];
        },
        ^BOOL {
          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          return [datasource clearAttributes];
        }
    ];
    [BAUserDataManager addOperationQueueAndSubmit:applyQueue withCompletion:completion];
}

+ (BOOL)canSave {
    if (![[[BACoreCenter instance] status] isRunning]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Batch must be started before changes to user data can be saved. The changes you've "
                                  @"just tried to save have been discarded."];
        return false;
    }

    if ([[BAOptOut instance] isOptedOut]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"Batch is Opted-Out from: BatchUserDataEditor changes cannot be saved"];
        return false;
    }

    return true;
}

+ (BOOL)writeChangesToDatasource:(NSArray<BOOL (^)(void)> *)applyQueue changeset:(long long)changeset {
    id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];

    if (![datasource acquireTransactionLockWithChangeset:changeset]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"An internal error occurred while applying the changes. (Error code 35)"];
        return false;
    }

    for (BOOL (^operation)(void) in applyQueue) {
        if (!operation()) {
            [datasource rollbackTransaction];
            [BALogger errorForDomain:DEBUG_DOMAIN message:@"Operation returned false"];
            [BALogger publicForDomain:PUBLIC_DOMAIN
                              message:@"An internal error occurred while applying the changes. (Error code 36)"];
            return false;
        }
    }

    if (![datasource commitTransaction]) {
        [BALogger publicForDomain:PUBLIC_DOMAIN
                          message:@"An internal error occurred while applying the changes. (Error code 37)"];
        return false;
    }

    return true;
}

/// Add an editor's operations queue to the queue
/// - Parameters:
///   - queue: editor's queue to add
///   - completion: completion triggered when operations are submited
/// - Warning: We are not synchronizing here because we are on the shared queue, so this method is NOT thread-safe.
+ (void)addOperationQueueAndSubmit:(NSArray<BOOL (^)(void)> *)queue withCompletion:(void (^_Nullable)(void))completion {
    [operationsQueues addObject:queue];
    [BAUserDataManager submitWithCompletion:completion];
}

+ (void)submitWithCompletion:(void (^_Nullable)(void))completion {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(DISPATCH_QUEUE_TIMER * NSEC_PER_MSEC)),
        [BAUserDataManager sharedQueue], ^{
          if ([operationsQueues count] == 0) {
              if (completion != nil) {
                  completion();
              }
              return;
          }

          NSMutableArray<BOOL (^)(void)> *applyQueue = [NSMutableArray array];
          for (NSArray<BOOL (^)(void)> *queue in operationsQueues) {
              [applyQueue addObjectsFromArray:queue];
          }
          [operationsQueues removeAllObjects];

          id<BAUserDatasourceProtocol> datasource = [BAInjection injectProtocol:@protocol(BAUserDatasourceProtocol)];
          NSNumber *changeset = [BAParameter objectForKey:kParametersUserProfileDataVersionKey fallback:@(0)];
          // Sanity
          if (![changeset isKindOfClass:[NSNumber class]]) {
              [BAParameter setValue:@(0) forKey:kParametersUserProfileDataVersionKey saved:YES];
              changeset = @(0);
          }

          BAUserAttributes *oldAttributes = [datasource attributes];
          BAUserTagCollections *oldTagCollections = [datasource tagCollections];

          long long newChangeset = [changeset longLongValue] + 1;

          if (![BAUserDataManager writeChangesToDatasource:applyQueue changeset:newChangeset]) {
              if (completion != nil) {
                  completion();
              }
              return;
          }

          BAUserAttributes *newAttributes = [datasource attributes];
          BAUserTagCollections *newTagCollections = [datasource tagCollections];

          BAUserAttributesDiff *attributesDiff = [[BAUserAttributesDiff alloc] initWithNewAttributes:newAttributes
                                                                                            previous:oldAttributes];
          BAUserTagCollectionsDiff *tagCollectionsDiff =
              [[BAUserTagCollectionsDiff alloc] initWithNewTagCollections:newTagCollections previous:oldTagCollections];

          if ([attributesDiff hasChanges] || [tagCollectionsDiff hasChanges]) {
              NSNumber *newChangesetNumber = @(newChangeset);
              [BAParameter setValue:newChangesetNumber forKey:kParametersUserProfileDataVersionKey saved:YES];
              [BAParameter removeObjectForKey:kParametersUserProfileTransactionIDKey];
              [BAUserDataManager startAttributesSendWSWithDelay:0];

              NSDictionary *eventParams = [BAUserDataDiffTransformer eventParametersFromAttributes:attributesDiff
                                                                                    tagCollections:tagCollectionsDiff
                                                                                           version:newChangesetNumber];
              [BATrackerCenter trackPrivateEvent:@"_INSTALL_DATA_CHANGED" parameters:eventParams];

              [BALogger debugForDomain:DEBUG_DOMAIN message:@"Changes in install occurred: YES"];
          } else {
              [BALogger debugForDomain:DEBUG_DOMAIN message:@"Changes in install occurred: NO"];
          }

          if (completion != nil) {
              completion();
          }
        });
}

@end
