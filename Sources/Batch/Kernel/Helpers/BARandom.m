//
//  BARandom.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2016 Batch SDK. All rights reserved.
//

#import <Batch/BARandom.h>

@implementation BARandom

// Generate a random [0-9][a-z][A-Z] string.
+ (NSString *)randomAlphanumericStringWithLength:(int)length {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];

    for (int i = 0; i < length; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
    }

    return randomString;
}

// Generate a random identifier using CFUUIDCreateString() method.
+ (NSString *)generateUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *newID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);

    return newID;
}

@end
