//
//  BASecureDateProvider.m
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BASecureDateProvider.h>

#import <Batch/BASecureDate.h>

@interface BASecureDateProvider ()
{
    BASecureDate *_secureDate;
}
@end

@implementation BASecureDateProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _secureDate = [BASecureDate instance];
    }

    return self;
}

- (NSDate*)currentDate {
    NSDate *date = [_secureDate date];
    return date != nil ? date : [super currentDate];
}

@end
