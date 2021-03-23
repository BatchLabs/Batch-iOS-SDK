//
//  BAOSHelper.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAOSHelper : NSObject

/*!
 @method deviceCode
 @abstract Get the device code string.
 @return The current standard code.
 */
+ (nonnull NSString *)deviceCode;

/// Parse an integer representation of an iOS version
/// Format is XXXYYYZZZ, where XXX is major, YYY minor, ZZZ patch.
/// @param outVersion NSOperatingSystemVersion to write to. Must not be NULL or the method will return false.
/// @return true on success, false on failure. outVersion will only be written to on success.
+ (BOOL)parseIntegerSystemVersion:(NSInteger)intSystemVersion out:(NSOperatingSystemVersion* _Nonnull)outVersion;

@end
