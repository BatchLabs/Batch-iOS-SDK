//
//  BatchUserProfile.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BatchUserProfile.h>

#import <Batch/BAUserProfile.h>
#import <Batch/BAPropertiesCenter.h>

@interface BatchUserProfile ()

@property BAUserProfile *internal;

@end

@implementation BatchUserProfile

#pragma mark -
#pragma mark Instance methods

- (instancetype)init
{
    self = [super init];
    if ([BANullHelper isNull:self])
    {
        return self;
    }
    
    _internal = [BAUserProfile defaultUserProfile];
    
    return self;
}


#pragma mark -
#pragma mark Properties override methods

/*** Custom Identifier ***/

- (NSString *)customIdentifier
{
    return [self.internal customIdentifier];
}

- (void)setCustomIdentifier:(NSString *)customIdentifier
{
    [self.internal setCustomIdentifier:customIdentifier];
}

/*** Language ***/

- (NSString *)language
{
    NSString *value = [self.internal language];
    if (value == nil) {
        value = [BAPropertiesCenter valueForShortName:@"dla"];
    }
    return value;
}

- (void)setLanguage:(NSString *)language
{
    [self.internal setLanguage:language];
}

/*** Region ***/

- (NSString *)region
{
    NSString *value = [self.internal region];
    if (value == nil) {
        value = [BAPropertiesCenter valueForShortName:@"dre"];
    }
    return value;
}

- (void)setRegion:(NSString *)region
{
    [self.internal setRegion:region];
}

@end
