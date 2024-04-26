//
//  BAEvent.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BACoreCenter.h>
#import <Batch/BADateFormatting.h>
#import <Batch/BAEvent.h>
#import <Batch/BAJson.h>
#import <Batch/BAParameter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BASecureDate.h>

@implementation BAEvent

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name andParameters:nil];
}

- (instancetype)initWithName:(NSString *)name andParameters:(NSDictionary *)parameters {
    // The event name is mandatory.
    if ([BANullHelper isStringEmpty:name]) {
        return nil;
    }

    // Build instance.
    self = [super init];

    if ([BANullHelper isNull:self]) {
        return nil;
    }

    // Generate the identifier using an UUID.
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    _identifier = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);

    // Ensure to have a good identifier.
    if ([BANullHelper isStringEmpty:_identifier]) {
        return nil;
    }

    _date = [BAPropertiesCenter valueForShortName:@"da"];

    _secureDate = [[BASecureDate instance] formattedString];

    // Keep the name.
    _name = [NSString stringWithString:name];

    _parametersDictionary = parameters.copy;

    _session = [BACoreCenter instance].status.sessionManager.sessionID;

    if (parameters) {
        _parameters = [BAJson serialize:parameters error:nil];
    }

    NSNumber *ts = [BAParameter objectForKey:kParametersServerTimestamp fallback:@(0)];
    if (ts && [ts respondsToSelector:@selector(longLongValue)]) {
        _tick = [ts longLongValue];
    } else {
        _tick = 0L;
    }

    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                              date:(NSString *)date
                        parameters:(NSString *)parameters
                             state:(BAEventState)state
                           session:(NSString *)session
                           andTick:(long long)tick {
    // Identifier and date are mandatory. Name will be tested later.
    if ([BANullHelper isStringEmpty:identifier]) {
        return nil;
    }

    if ([BANullHelper isStringEmpty:date]) {
        return nil;
    }

    // Build instance.
    self = [self initWithName:name andParameters:nil];

    if ([BANullHelper isNull:self]) {
        return nil;
    }

    _identifier = [NSString stringWithString:identifier];

    _date = [NSString stringWithString:date];

    if (parameters) {
        _parameters = [NSString stringWithString:parameters];
    }

    _state = state;

    _tick = tick;

    _session = session;

    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                              date:(NSString *)date
                        secureDate:(NSString *)secureDate
                        parameters:(NSString *)parameters
                             state:(BAEventState)state
                           session:(NSString *)session
                           andTick:(long long)tick {
    self = [self initWithIdentifier:identifier
                               name:name
                               date:date
                         parameters:parameters
                              state:state
                            session:session
                            andTick:tick];
    if ([BANullHelper isNull:self]) {
        return self;
    }

    _secureDate = secureDate;

    return self;
}

+ (instancetype)eventWithName:(NSString *)name {
    return [[BAEvent alloc] initWithName:name];
}

+ (instancetype)eventWithName:(NSString *)name andParameters:(NSDictionary *)parameters {
    return [[BAEvent alloc] initWithName:name andParameters:parameters];
}

+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick {
    return [[BAEvent alloc] initWithIdentifier:identifier
                                          name:name
                                          date:date
                                    parameters:parameters
                                         state:state
                                       session:session
                                       andTick:tick];
}

+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         secureDate:(NSString *)secureDate
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick {
    return [[BAEvent alloc] initWithIdentifier:identifier
                                          name:name
                                          date:date
                                    secureDate:secureDate
                                    parameters:parameters
                                         state:state
                                       session:session
                                       andTick:tick];
}

// Build the list of identifiers from the BAEvent list.
+ (NSArray *)identifiersOfEvents:(NSArray *)events {
    NSMutableArray *eventIDs = [[NSMutableArray alloc] initWithCapacity:[events count]];
    for (BAEvent *event in events) {
        [eventIDs addObject:event.identifier];
    }

    return [NSArray arrayWithArray:eventIDs];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"BAEvent(name: '%@', parameters count: %lu)", self.name,
                                      (unsigned long)self.parametersDictionary.count];
}

@end

@implementation BACollapsableEvent

+ (instancetype)eventWithName:(NSString *)name {
    return [[BACollapsableEvent alloc] initWithName:name];
}

+ (instancetype)eventWithName:(NSString *)name andParameters:(NSDictionary *)parameters {
    return [[BACollapsableEvent alloc] initWithName:name andParameters:parameters];
}

+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick {
    return [[BACollapsableEvent alloc] initWithIdentifier:identifier
                                                     name:name
                                                     date:date
                                               parameters:parameters
                                                    state:state
                                                  session:session
                                                  andTick:tick];
}

+ (instancetype)eventWithIdentifier:(NSString *)identifier
                               name:(NSString *)name
                               date:(NSString *)date
                         secureDate:(NSString *)secureDate
                         parameters:(NSString *)parameters
                              state:(BAEventState)state
                            session:(NSString *)session
                            andTick:(long long)tick {
    return [[BACollapsableEvent alloc] initWithIdentifier:identifier
                                                     name:name
                                                     date:date
                                               secureDate:secureDate
                                               parameters:parameters
                                                    state:state
                                                  session:session
                                                  andTick:tick];
}

@end
