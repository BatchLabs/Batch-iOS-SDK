//
//  BatchProfileEditor.h
//  Batch
//
//  https://batch.com
//  Copyright (c) Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Enum defining the state of an email subscription
typedef NS_ENUM(NSUInteger, BatchEmailSubscriptionState) {
    BatchEmailSubscriptionStateSubscribed = 0,
    BatchEmailSubscriptionStateUnsubscribed = 1,
};

/// Enum defining the state of an SMS subscription
typedef NS_ENUM(NSUInteger, BatchSMSSubscriptionState) {
    BatchSMSSubscriptionStateSubscribed = 0,
    BatchSMSSubscriptionStateUnsubscribed = 1,
};

/// Provides profile attribute edition methods.
///
/// Once save() has been called once (or implicitly when using the editor block), you will
/// not be able to set any attribute and must get a new instance.
///
/// # Setting an attribute
/// ```swift
/// // Get a new editor instance.
/// // You need to save this in a local variable until you call save
/// // Editor instances don't share changes, and calling save on an empty editor will do nothing
/// let editor = BatchProfile.editor()
/// // Set an attribute. try? allows a potential error to be silently ignored
/// // This example is a valid key/attribute pair, and will not throw an error.
/// try? editor.set(attribute: 26, forKey:"age")
/// do {
///    // Invalid attribute name, $ is a forbidden character
///    try editor.set(attribute: "patricia", forKey: "fir$t_name")
/// } catch {
///    // Handle the error here.
///    // Error is of type BatchProfileError if you want to specifically
///    // handle it.
/// }
/// editor.save() // Don't forget to save the changes
/// ```
///
/// # Removing an attribute
/// ```swift
/// // Get a new editor instance.
/// // You need to save this in a local variable until you call save
/// // Editor instances don't share changes, and calling save on an empty editor will do nothing
/// let editor = BatchProfile.editor()
/// try? editor.removeAttribute(forKey: "age") // Remove an attribute
/// editor.save() // Don't forget to save the changes
/// ```
///
/// # Managing array attributes
/// ```swift
/// let editor = BatchProfile.editor()
/// try? editor.set(attribute: ["apple_pay"], forKey: "payment_methods")
/// // Modify an existing array
/// try? editor.addToStringArray(value: ["carte_bleue"], forKey: "payment_methods")
/// try? editor.removeFromStringArray(value: ["carte_bleue"], forKey: "payment_methods")
/// editor.save(); // Don't forget to save the changes
/// ```
///
/// # Closure syntax
/// Another way to use the editor is by giving it a closure. Once the closure returns, the profile data is saved.
/// Making the instance escape the closure is not supported: you might lose changes if you set data once the closure has
/// returned.
/// ```swift
/// BatchProfile.editor { editor in
///     try editor.set(attribute: 26, forKey: "age")
///     // No need to call .save(), this is done automatically
/// }
/// ```
@interface BatchProfileEditor : NSObject

/// You cannot instantiate this class directly, please use `BatchProfile`
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Set a device language on a profile, overriding the detected one.
///
/// - Parameter language: Lowercase, ISO 639 formatted string. nil to reset.
/// - Returns:  A boolean indicating whether the attribute passed validation or not.
- (BOOL)setLanguage:(nullable NSString *)language error:(NSError *_Nullable *_Nullable)error;

/// Set a device region on a profile, overriding the detected one.
///
/// - Parameter region: Region override: uppercase, ISO 3166 formatted string. nil to reset.
/// - Returns:  A boolean indicating whether the attribute passed validation or not.
- (BOOL)setRegion:(nullable NSString *)region error:(NSError *_Nullable *_Nullable)error;

/// Set the user email.
///
/// - Important: This method requires to already have a registered identifier for the user
/// or to call ``BatchProfile/identify`` method before this one.
/// - Parameters:
///    - email: User email.
///    - error Pointer to an error describing. Note that the error is only about validation  and doesn't
///    mean the value has been sent to the server yet.
/// - Returns:  A boolean indicating whether the attribute passed validation or not.
- (BOOL)setEmailAddress:(nullable NSString *)email error:(NSError *_Nullable *_Nullable)error;

/// Set the user email subscription state.
///
/// Note that profile's subscription status is automatically set to unsubscribed when a user click an unsubscribe link.
/// - Parameters:
///    - state: Subscription state
- (void)setEmailMarketingSubscriptionState:(BatchEmailSubscriptionState)state;

/// Set the profile phone number.
///
/// - Important: This method requires to already have a registered identifier for the user
/// or to call ``BatchProfile/identify:`` method before this one.
/// - Parameters:
///    - phoneNumber: A valid [E.164](https://en.wikipedia.org/wiki/E.164) formatted string.   Must start with a "+" and
///    not be longer than 15 digits without special characters (eg: "+33123456789"). nil to reset.
///    - error Pointer to an error describing. Note that the error is only about validation  and doesn't mean the value
///    has been sent to the server yet.
/// - Returns:  A boolean indicating whether the attribute passed validation or not.
///
/// ## Examples:
/// ```swift
///     BatchProfile.identify("my_custom_user_id")
///     let editor = BatchProfile.editor()
///     try? editor.setPhoneNumber("+33123456789").save()
/// ```
/// ```objc
///     [BatchProfile identify: @"my_custom_user_id"];
///     BatchProfileEditor *editor = [BatchProfile editor];
///     [editor setPhoneNumber:@"+33123456789" error:nil];
/// ```
- (BOOL)setPhoneNumber:(nullable NSString *)phoneNumber error:(NSError *_Nullable *_Nullable)error;

/// Set the profile SMS marketing subscription state.
///
/// Note that profile's subscription status is automatically set to unsubscribed when a user send a STOP message.
/// - Parameters:
///    - state: State of the subscription
- (void)setSMSMarketingSubscriptionState:(BatchSMSSubscriptionState)state;

/// Set a boolean profile attribute for a key.
///
/// - Parameters:
///   - attribute: The attribute value.
///   - name:  The attribute name. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setBooleanAttribute:(BOOL)attribute
                     forKey:(nonnull NSString *)key
                      error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set a date profile attribute for a key.
///
/// - Note: Since timezones are not supported, this will typically represent UTC dates.
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setDateAttribute:(nonnull NSDate *)attribute
                  forKey:(nonnull NSString *)key
                   error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set a string profile attribute for a key.
///
/// Must not be longer than 300 characters. Can be empty.
/// For better results, you should make them upper/lowercase and trim the whitespaces.
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setStringAttribute:(nonnull NSString *)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set a string array profile attribute for a key.
/// Can be empty.
///
/// - Parameters:
///   - attribute: The attribute value. Cannot have more than 25 items.
///     Individual items cannot be longer than 300 characters.
///     For better results, you should make them upper/lowercase and trim the whitespaces.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setStringArrayAttribute:(nonnull NSArray<NSString *> *)attribute
                         forKey:(nonnull NSString *)key
                          error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Add a value to a string array.
/// Can be empty.
///
/// If the attribute has been set to another type, it will be overwritten with a String array.
/// If the attribute does not exist, it will be created.
///
/// - Parameters:
///   - attribute: The attribute value. Cannot have more than 25 operations pending on an array attribute.
///     Individual items cannot be longer than 300 characters.
///     For better results, you should make them upper/lowercase and trim the whitespaces.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)addItemToStringArrayAttribute:(nonnull NSString *)attribute
                               forKey:(nonnull NSString *)key
                                error:(NSError *_Nullable *_Nullable)error
    NS_SWIFT_NAME(addToStringArray(item:forKey:));

/// Remove a value from a string array.
/// Can be empty.
///
/// If the attribute has been set to another type, it will be deleted.
///
/// - Parameters:
///   - attribute: The attribute value. Cannot have more than 25 operations pending on an array attribute.
///     Individual items cannot be longer than 300 characters.
///     For better results, you should make them upper/lowercase and trim the whitespaces.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)removeItemFromStringArrayAttribute:(nonnull NSString *)attribute
                                    forKey:(nonnull NSString *)key
                                     error:(NSError *_Nullable *_Nullable)error
    NS_SWIFT_NAME(removeFromStringArray(item:forKey:));

/// Set an `NSInteger/Int` profile attribute for a key.
///
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setIntegerAttribute:(NSInteger)attribute
                     forKey:(nonnull NSString *)key
                      error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set an `long long/Int64` profile attribute for a key.
///
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setLongLongAttribute:(long long)attribute
                      forKey:(nonnull NSString *)key
                       error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set an float profile attribute for a key.
///
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setFloatAttribute:(float)attribute
                   forKey:(nonnull NSString *)key
                    error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set an double profile attribute for a key.
///
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setDoubleAttribute:(double)attribute
                    forKey:(nonnull NSString *)key
                     error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Set an url profile attribute for a key.
///
/// Must not be longer than 2048 characters. Can't be empty or nil.
/// Must follow the format `scheme://[authority][path][?query][#fragment]`.
/// - Parameters:
///   - attribute: The attribute value.
///   - key: The attribute key. Can't be nil. It should be made of letters, numbers or underscores (`[a-z0-9_]`) and
///     can't be longer than 30 characters.
///   - error: Pointer to an error describing. Note that the error is only about key/value validation, and doesn't
///     mean the value has been sent to the server yet.
/// - Returns: A boolean indicating whether the attribute passed validation or not.
- (BOOL)setURLAttribute:(nonnull NSURL *)attribute
                 forKey:(nonnull NSString *)key
                  error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(set(attribute:forKey:));

/// Removes an attribute for the specified key.
///
/// - Parameter key: The attribute key. Can't be nil.
- (BOOL)removeAttributeForKey:(nonnull NSString *)key
                        error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(removeAttribute(key:));

/// Save all of the pending changes made in that editor.
///
/// - Important:This action cannot be undone.
- (void)save;

@end
