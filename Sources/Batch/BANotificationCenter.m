//
//  AGEventNotificationCenter.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BANotificationCenter.h>

@implementation BANotificationCenter

#pragma mark -
#pragma mark Public methods

// Instance management.
+ (instancetype)defaultCenter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

@end
