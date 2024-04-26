//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAInjectionRegistrar.h"
#import <Batch/Batch-Swift.h>
#import "BADisplayReceiptCenter.h"
#import "BAEventDispatcherCenter.h"
#import "BAInboxSQLiteDatasource.h"
#import "BAInboxSQLiteHelper.h"
#import "BAInjection.h"
#import "BAInstallDataEditor.h"
#import "BALocalCampaignsFilePersistence.h"
#import "BAMessagingAnalyticsDeduplicatingDelegate.h"
#import "BAMessagingCenter.h"
#import "BAMetricManager.h"
#import "BAMetricRegistry.h"
#import "BAPushSystemHelper.h"
#import "BATrackerCenter.h"
#import "BAUserSQLiteDatasource.h"

@implementation BAInjectionRegistrar

+ (void)registerInjectables {
    // Register BAProfileCenter
    [BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BAProfileCenter sharedInstance]]
                        forProtocol:@protocol(BAProfileCenterProtocol)];

    // Register BATEventTrackerProtocol
    [BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BATrackerCenter instance]]
                        forProtocol:@protocol(BATEventTrackerProtocol)];

    // Register BADisplayReceiptCenter
    [BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BADisplayReceiptCenter new]]
                           forClass:BADisplayReceiptCenter.class];

    // Register BAEventDispatcherCenter
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   static id singleInstance = nil;
                   static dispatch_once_t once;
                   dispatch_once(&once, ^{
                     singleInstance = [BAEventDispatcherCenter new];
                   });
                   return singleInstance;
                 }]
                           forClass:BAEventDispatcherCenter.class];

    // Register BALocalCampaignsFilePersistence
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BALocalCampaignsFilePersistence new];
                 }]
                        forProtocol:@protocol(BALocalCampaignsPersisting)];

    // Register BAPushSystemHelper
    [BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BAPushSystemHelper new]]
                        forProtocol:@protocol(BAPushSystemHelperProtocol)];

    // Register BAMessagingCenter
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BAMessagingCenter instance];
                 }]
                           forClass:BAMessagingCenter.class];

    // Register BAMessagingAnalyticsDeduplicatingDelegate
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [[BAMessagingAnalyticsDeduplicatingDelegate alloc]
                       initWithWrappedDelegate:[BAInjection injectClass:BAMessagingCenter.class]];
                 }]
                        forProtocol:@protocol(BAMessagingAnalyticsDelegate)];

    // Register BAUserSQLiteDatasource
    [BAInjection registerInjectable:[BAInjectable injectableWithInstance:[BAUserSQLiteDatasource instance]]
                        forProtocol:@protocol(BAUserDatasourceProtocol)];

    // Register BAUserDataEditor
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BAInstallDataEditor new];
                 }]
                           forClass:BAInstallDataEditor.class];

    // Register BAProfileEditor
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BATProfileEditor new];
                 }]
                           forClass:BATProfileEditor.class];

    // Register BAInboxSQLiteDatasource
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   static id singleInstance = nil;
                   static dispatch_once_t once;
                   dispatch_once(&once, ^{
                     singleInstance = [[BAInboxSQLiteDatasource alloc] initWithFilename:@"ba_in.db"
                                                                            forDBHelper:[BAInboxSQLiteHelper new]];
                   });
                   return singleInstance;
                 }]
                        forProtocol:@protocol(BAInboxDatasourceProtocol)];

    // Register MetricManager
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BAMetricManager sharedInstance];
                 }]
                           forClass:BAMetricManager.class];

    // Register MetricRegistry
    [BAInjection registerInjectable:[BAInjectable injectableWithInitializer:^id() {
                   return [BAMetricRegistry instance];
                 }]
                           forClass:BAMetricRegistry.class];
}

@end
