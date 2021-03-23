//
//  BAActionsCenter.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BACenterMulticastDelegate.h>
#import <Batch/BatchActions.h>

extern NSString * _Nonnull const kBAActionsReservedIdentifierPrefix;

@interface BAActionsCenter : NSObject <BACenterProtocol>

+ (instancetype _Nonnull)instance;

- (nullable NSError*)registerAction:(nonnull BatchUserAction*)action;

- (void)unregisterActionIdentifier:(nonnull NSString*)identifier;

/*!
 * Perform an action. Private version that allows "batch." actions to be fired
 * @returns YES if an action was found and performed, NO otherwise
 */
- (BOOL)performAction:(nonnull NSString*)identifier withArgs:(nonnull NSDictionary<NSString*, NSObject*>*)args andSource:(nullable id<BatchUserActionSource>)source;

- (BOOL)publicPerformAction:(nonnull NSString*)identifier withArguments:(nonnull NSDictionary<NSString*, NSObject*>*)args;


@end
