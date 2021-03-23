//
//  BALogger.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALoggerProtocol.h>

#pragma mark -
#pragma mark BALoggerLevel

/*!
 @enum BALoggerLevel
 @abstract Log level.
 @discussion Types that will be used to log.
 */
enum
{
    BALoggerLevelNone      = 1 << 0,
    BALoggerLevelPublic    = 1 << 1,
    BALoggerLevelError     = 1 << 2,
    BALoggerLevelWarning   = 1 << 3,
    BALoggerLevelDebug     = 1 << 4,
    BALoggerLevelAll       = BALoggerLevelPublic | BALoggerLevelError | BALoggerLevelWarning | BALoggerLevelDebug
};
/*!
 @typedef BALoggerLevel
 */
typedef NSUInteger BALoggerLevel;


#pragma mark -
#pragma mark BALogger

NS_ASSUME_NONNULL_BEGIN

/*!
 @class BALogger
 @abstract Logger helper.
 @discussion Control logs.
 */
@interface BALogger : NSObject

/// Call this method on SDK initialization
+ (void)setup;

@property (class) BOOL internalLogsEnabled;

/*!
 @method init
 @warning Never call this method.
 */
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method publicForDomain:message:…
 @abstract Log the message using a public tag.
 @param name            :   Domain to show.
 @param formatstring    :   Formated string and it's optional arguments.
 @param ...             :   Formated string parameters.
 */
+ (void)publicForDomain:(nullable NSString *)name message:(NSString *)formatstring,... NS_FORMAT_FUNCTION(2,3);

/*!
 @method errorForDomain:message:…
 @abstract Log the message using an error tag.
 @param name            :   Domain to show.
 @param formatstring    :   Formated string and it's optional arguments.
 @param ...             :   Formated string parameters.
 */
+ (void)errorForDomain:(nullable NSString *)name message:(NSString *)formatstring,... NS_FORMAT_FUNCTION(2,3);

/*!
 @method warningForDomain:message:…
 @abstract Log the message using a warning tag.
 @param name            :   Domain to show.
 @param formatstring    :   Formated string and it's optional arguments.
 @param ...             :   Formated string parameters.
 */
+ (void)warningForDomain:(nullable NSString *)name message:(NSString *)formatstring,... NS_FORMAT_FUNCTION(2,3);

/*!
 @method debugForDomain:message:…
 @abstract Log the message using a debug tag.
 @param name            :   Domain to show.
 @param formatstring    :   Formated string and it's optional arguments.
 @param ...             :   Formated string parameters.
 */
+ (void)debugForDomain:(nullable NSString *)name message:(NSString *)formatstring,... NS_FORMAT_FUNCTION(2,3);

/** delegateSource is weak-referenced, make sure you hold a strong reference to it. */
+ (void)setLoggerDelegateSource:(id <BALoggerDelegateSource> _Nullable)delegateSource;

#pragma mark - Swift only methods

/// See publicForDomain:message:
+ (void)__SWIFT_publicForDomain:(nullable NSString *)domain message:(NSString *)message NS_SWIFT_NAME(public(domain:message:));

/// See errorForDomain:message:
+ (void)__SWIFT_errorForDomain:(nullable NSString *)domain message:(NSString *)message NS_SWIFT_NAME(error(domain:message:));

/// See warningForDomain:message:
+ (void)__SWIFT_warningForDomain:(nullable NSString *)domain message:(NSString *)message NS_SWIFT_NAME(warning(domain:message:));

/// See debugForDomain:message:
+ (void)__SWIFT_debugForDomain:(nullable NSString *)domain message:(NSString *)message NS_SWIFT_NAME(debug(domain:message:));

@end

NS_ASSUME_NONNULL_END
