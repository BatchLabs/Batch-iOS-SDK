//
//  BatchActions.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark Action sources

/// Represents an action source.
///
/// Can be used to get more information about the context of the action, such as the full push payload, if coming from a
/// push.
@protocol BatchUserActionSource <NSObject>

@end

/// Source that's only set when an action was manually triggered by
/// ``BatchActions/performActionIdentifiedBy:withArguments:``
@interface BatchManualUserActionSource : NSObject <BatchUserActionSource>

@end

#pragma mark Action model

typedef void (^BatchUserActionBlock)(NSString *_Nonnull identifier,
                                     NSDictionary<NSString *, id> *_Nonnull arguments,
                                     id<BatchUserActionSource> _Nullable source);

/// Represents an action that can be triggered by the user from anywhere.
@interface BatchUserAction : NSObject

/// Create a new ``BatchUserAction`` object with the following parameters.
///
/// - Important: Be careful, as the action block can be invoked on any thread. You should never make any assumption
/// about which thread you're on when this is called.
/// - Parameters:
///   - identifier: The unique action identifier. Should be unique in your app (not case-sensitive).
///   - actionBlock: The action block that will be invoked when Batch wants to execute your action. Can be called from
///   any thread: never make any assumption about which thread you're on when this is called.
/// - Returns: A ``BatchUserAction`` instance constructed from the given parameters.
+ (nonnull instancetype)userActionWithIdentifier:(nonnull NSString *)identifier
                                     actionBlock:(nonnull BatchUserActionBlock)actionBlock;

/// Action identifier. Should be unique in your app.
@property (readonly, nonnull) NSString *identifier;

/// Action block to invoke when Batch wants to perform your action.
///
/// - Important: Be careful, as it can be invoked on any thread. You should never make any assumption about which thread
/// you're on when this is called.
@property (readonly, nonnull) BatchUserActionBlock actionBlock;

@end

#pragma mark Action module

/// Batch's Actions module
@interface BatchActions : NSObject

/// Register an action with Batch.
///
/// If an action already exists for that identifier, it will be replaced. Identifiers are not case-sensitive.
/// - Note: The action identifier cannot start with "batch.", as they are reserved by the SDK. Trying to register such
/// an action will throw an error.
/// - Parameter action: The action to register
+ (nullable NSError *)registerAction:(nonnull BatchUserAction *)action;

/// Unregister an action from Batch.
///
/// - Note: Trying to unregister an action that has not be registered or to unregister an action that starts with
/// "batch."  will silently fail.
/// - Parameter actionIdentifier: The action's identifier. Not case-sensitive.
+ (void)unregisterActionIdentifier:(nonnull NSString *)actionIdentifier NS_SWIFT_NAME(unregister(actionIdentifier:));

/// Perform an action registered with Batch.
///
/// - Note: Manually trying to trigger builtin actions (prefixed by "batch.") will not work.
/// - Parameters:
///   - identifier: The action identifier. Case-unsensitive. Cannot be nil.
///   - args: A dictionary containing the action arguments. Cannot be nil.
/// - Returns: YES if the action was performed, NO if no action was found or another error occurred
+ (BOOL)performActionIdentifiedBy:(nonnull NSString *)identifier
                    withArguments:(nonnull NSDictionary<NSString *, id> *)args
    NS_SWIFT_NAME(perform(actionIdentifier:arguments:));

@end

/// BatchActions error code constants.
typedef NS_ENUM(NSInteger, BatchActionError) {

    /// Internal error
    BatchActionErrorUnknown = -1001,

    /// Can be multiple things: nil action, nil or empty identifier string, nil action block
    BatchActionErrorInvalidArgument = -1002,

    /// This action identifier is reserved and cannot be used. Note that actions cannot begin by "batch."
    BatchActionErrorReservedIdentifier = -1003
};
