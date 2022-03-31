//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BAMutableDateProvider.h"

@implementation BAMutableDateProvider {
    NSDate *_date;
}

- (instancetype)initWithTimestamp:(double)timestamp;
{
    self = [super init];
    if (self) {
        _date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    }
    return self;
}

- (void)setTime:(double)timestamp {
    _date = [NSDate dateWithTimeIntervalSince1970:timestamp];
}

- (NSDate *)currentDate {
    return _date;
}

@end
