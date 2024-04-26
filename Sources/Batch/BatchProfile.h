//
//  BatchProfile.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Batch/BatchEventAttributes.h>
#import <Batch/BatchProfileEditor.h>
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Error domain of `BatchProfile` related errors
FOUNDATION_EXPORT NSErrorDomain const _Nonnull BatchProfileErrorDomain;

typedef NS_ERROR_ENUM(BatchProfileErrorDomain, BatchProfileError){
    /// Unknown internal error
    BatchProfileErrorUnknown = -10,

    /// The event attributes failed to validate
    /// See localizedDescription for more info
    BatchProfileErrorInvalidEventAttributes = -21,

    /// The attribute key is invalid
    /// See localizedDescription for more info
    BatchProfileErrorEditorInvalidKey = -31,

    /// The value is invalid
    /// See localizedDescription for more info
    BatchProfileErrorEditorInvalidValue = -32,

    /// The editor has been consumed. Use a new instance to set attributes again.
    /// See localizedDescription for more info
    BatchProfileErrorEditorConsumed = -33,
};

/// Batch's Profile Module
@interface BatchProfile : NSObject

/// Identifies this device with a profile using a Custom User ID
/// - Parameter customID: Custom user ID of the profile you want to identify against. If a profile already exists, this
/// device will be attached to it. Must not be longer than 1024 characters.
+ (void)identify:(nullable NSString *)customID;

/// Track an event.
///
/// You can call this method from any thread. Batch must be started at some point, or events won't be sent to the
/// server.
///
/// - Parameters:
///   - eventName: The event name. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and can't be
///   longer than 30 characters.
+ (void)trackEventWithName:(nonnull NSString *)eventName NS_SWIFT_NAME(trackEvent(name:));

/// Track an event.
///
/// You can call this method from any thread. Batch must be started at some point, or events won't be sent to the
/// server.
///
/// - Parameters:
///   - eventName: The event name. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and can't be
///   longer than 30 characters.
///   - attributes: The event attributes (optional).
+ (void)trackEventWithName:(nonnull NSString *)eventName
                attributes:(nullable BatchEventAttributes *)attributes NS_SWIFT_NAME(trackEvent(name:attributes:));

/// Track a geolocation update.
///
/// You can call this method from any thread. Batch must be started at some point, or location updates won't be sent to
/// the server. You'll usually call this method in your `CLLocationManagerDelegate` implementation
/// - Parameter location: The user's location in the form of a `CLLocation` object, ideally the one provided by the
/// system to your delegate.
+ (void)trackLocation:(nonnull CLLocation *)location;

/// Get the profile editor.
///
/// There are two ways to use the editor:
///
/// # As a closure
/// Call this method with a closure: you will get an instance of `BatchProfileEditor` as its parameters.
/// Once the closure returns, the profile data is saved.
/// Making the instance escape the closure is not supported: you might lose changes if you set data once the closure has
/// returned.
/// ```swift
/// BatchProfile.edit { editor in
///     try? editor.set(attribute: 26, forKey: "age")
///     // No need to call .save(), this is done automatically
/// }
/// ```
///
/// # Storing it in a local variable
/// Get an editor instance that you then call methods on. Handy for situations where you might need to wait on an async
/// function to get an attribute's value. Do not forget to call save once you're done changing the attributes, or they
/// will not be applied.
/// ```swift
/// // Get a new editor instance.
/// // You need to save this in a local variable until you call save
/// // Editor instances don't share changes, and calling save on an empty editor will do nothing
/// let editor = BatchProfile.editor()
/// // Set an attribute. try? allows a potential error to be silently ignored
/// // This example is a valid key/attribute pair, and will not throw an error.
/// try? editor.set(attribute: 26, forKey:"age")
/// editor.save() // Don't forget to save the changes
/// ```
///
/// Once save() has been called once (or implicitly when using the editor block), you will
/// not be able to set any attribute and must get a new instance.
///
/// - Returns: A ``BatchProfileEditor`` instance
+ (nonnull BatchProfileEditor *)editor;

/// Edit a profile.
///
/// There are two ways to use `BatchProfileEditor`:
/// # As a closure
/// Call this method with a closure: you will get an instance of `BatchProfileEditor` as its parameters.
/// Once the closure returns, the profile data is saved.
/// Making the instance escape the closure is not supported: you might lose changes if you set data once the closure has
/// returned.
/// ```swift
/// BatchProfile.edit { editor in
///     try? editor.set(attribute: 26, forKey: "age")
///     // No need to call .save(), this is done automatically
/// }
/// ```
///
/// # Storing it in a local variable
/// Get an editor instance that you then call methods on. Handy for situations where you might need to wait on an async
/// function to get an attribute's value. Do not forget to call save once you're done changing the attributes, or they
/// will not be applied.
/// ```swift
/// // Get a new editor instance.
/// // You need to save this in a local variable until you call save
/// // Editor instances don't share changes, and calling save on an empty editor will do nothing
/// let editor = BatchProfile.editor()
/// // Set an attribute. try? allows a potential error to be silently ignored
/// // This example is a valid key/attribute pair, and will not throw an error.
/// try? editor.set(attribute: 26, forKey:"age")
/// editor.save() // Don't forget to save the changes
/// ```
+ (void)editWithBlock:(void (^)(BatchProfileEditor *))editorClosure NS_SWIFT_NAME(editor(_:));

@end

NS_ASSUME_NONNULL_END
