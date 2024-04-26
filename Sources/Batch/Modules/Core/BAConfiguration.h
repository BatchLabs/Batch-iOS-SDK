//
//  BAConfiguration.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BatchCore.h>

extern NSString *_Nonnull const kBATConfigurationChangedNotification;

@protocol BatchLoggerDelegate;

/*!
 @class BAConfiguration
 @abstract General configuration parameters of the library.
 @discussion Access of all the running configuration parameters of the library.
 */
@interface BAConfiguration : NSObject

/*!
 @method setDevelopperKey:
 @abstract Keep and check the developper key value.
 @param key :   The application developper private key.
 @return An NSError with the reason or nil.
 */
- (nullable NSError *)setDevelopperKey:(nullable NSString *)key __attribute__((warn_unused_result));

/*!
 @method developperKey
 @abstract Gives the keept developper key.
 @return The developper key string, nil otherwise.
 */
- (nullable NSString *)developperKey __attribute__((warn_unused_result));

/*!
 @method setLoggerDelegate:
 @abstract Change the logger delegate.
 @param _loggerDelegate    :   Logger delegate, can be nil
 */
- (void)setLoggerDelegate:(nullable id<BatchLoggerDelegate>)_loggerDelegate;

/*!
 @method loggerDelegate
 @abstract Get the user-set logger delegate.
 @return Logger delegate, can be nil
 */
- (nullable id<BatchLoggerDelegate>)loggerDelegate __attribute__((warn_unused_result));

/*!
 @method setAssociatedDomains
 @abstract Set the associated domains
 */
- (void)setAssociatedDomains:(nonnull NSArray<NSString *> *)domains;

/*!
 @method associatedDomains
 @abstract Get the associated domains
 */
- (nullable NSArray<NSString *> *)associatedDomains;

/**
 Developer's deeplink delegate
 */
@property (weak, nonatomic, nullable) id<BatchDeeplinkDelegate> deeplinkDelegate;

/*!
 @method setDisabledMigrations
 @abstract Set profile's data migration to disable
 */
- (void)setDisabledMigrations:(BatchMigration)migrations;

/*!
 @method isMigrationDisabledFor
 @abstract Whether the given migration is disabled
 */
- (Boolean)isMigrationDisabledFor:(BatchMigration)migration;

@end
