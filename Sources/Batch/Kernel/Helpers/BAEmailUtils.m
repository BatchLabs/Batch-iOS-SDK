//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAEmailUtils.h"

/// Email regexp
#define EMAIL_VALUE_RULE @"^(\\S+@\\S+\\.\\S+)$"

@implementation BAEmailUtils

+ (BOOL)isValidEmail:(nonnull NSString *)email {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:EMAIL_VALUE_RULE
                                                                           options:0
                                                                             error:nil];
    NSRange matchingRange = [regex rangeOfFirstMatchInString:email options:0 range:NSMakeRange(0, email.length)];
    if (matchingRange.location == NSNotFound) {
        return false;
    }
    return true;
}

+ (BOOL)isEmailTooLong:(NSString *)email {
    return [email length] > EMAIL_MAX_LENGTH;
}
@end
