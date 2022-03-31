//
//  BATZAwareDate.m
//  Batch
//

#import <Batch/BATZAwareDate.h>

@implementation BATZAwareDate {
    NSDate *_date;
    NSTimeZone *_localTZ;
}

+ (instancetype)date {
    return [[BATZAwareDate alloc] initWithDate:[NSDate date] relativeToUserTZ:false];
}

+ (instancetype)dateWithDate:(NSDate *)date relativeToUserTZ:(BOOL)useLocalTZ {
    return [[BATZAwareDate alloc] initWithDate:date relativeToUserTZ:useLocalTZ];
}

- (instancetype)initWithDate:(NSDate *)date relativeToUserTZ:(BOOL)useLocalTZ {
    self = [super init];
    if (self) {
        _date = date;
        if (useLocalTZ) {
            _localTZ = [NSTimeZone localTimeZone];
        } else {
            _localTZ = nil;
        }
    }
    return self;
}

- (NSTimeInterval)offsettedTimeIntervalSince1970 {
    if (_localTZ != nil) {
        return _date.timeIntervalSince1970 - [_localTZ secondsFromGMTForDate:_date];
    }
    return _date.timeIntervalSince1970;
}

- (BOOL)isAfter:(BATZAwareDate *)date {
    return [self offsettedTimeIntervalSince1970] > [date offsettedTimeIntervalSince1970];
}

- (BOOL)isBefore:(BATZAwareDate *)date {
    return [self offsettedTimeIntervalSince1970] < [date offsettedTimeIntervalSince1970];
}

- (BOOL)isEqualToDate:(BATZAwareDate *)date {
    return [self offsettedTimeIntervalSince1970] == [date offsettedTimeIntervalSince1970];
}

@end
