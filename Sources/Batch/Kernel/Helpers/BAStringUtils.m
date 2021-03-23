//
//  BAStringUtils.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BAStringUtils.h>

#import <CommonCrypto/CommonDigest.h>

@implementation BAStringUtils

// Generate the hexadeciaml value of the data.
+ (NSString *)hexStringValueForData:(NSData*)data
{
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([data length] * 2)];
    
    const unsigned char *dataBuffer = [data bytes];
    int i;
    
    for (i = 0; i < [data length]; ++i)
    {
        [stringBuffer appendFormat:@"%02x", (unsigned int)dataBuffer[i]];
    }
    
    return [stringBuffer copy];
}

@end
