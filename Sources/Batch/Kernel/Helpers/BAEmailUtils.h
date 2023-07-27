//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Email max length
#define EMAIL_MAX_LENGTH 128

NS_ASSUME_NONNULL_BEGIN

@interface BAEmailUtils : NSObject

/// Check wether email is valid
+ (BOOL)isValidEmail:(nonnull NSString *)email;

/// Check wether email is too long
+ (BOOL)isEmailTooLong:(nonnull NSString *)email;

@end

NS_ASSUME_NONNULL_END
