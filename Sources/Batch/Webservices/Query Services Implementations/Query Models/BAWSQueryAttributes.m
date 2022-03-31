//
//  BAWebserviceQueryAttributes.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAWSQueryAttributes.h>

@interface BAWSQueryAttributes () {
    NSDictionary *_attributes;
    NSDictionary<NSString *, NSSet<NSString *> *> *_tags;
    long long _version;
}
@end

@implementation BAWSQueryAttributes

// Standard constructor.
- (id<BAWSQuery>)initWithVersion:(long long)version
                      attributes:(nonnull NSDictionary *)attributes
                         andTags:(nonnull NSDictionary<NSString *, NSSet<NSString *> *> *)tags {
    self = [super initWithType:kQueryWebserviceTypeAttributes];
    if (self) {
        _attributes = attributes;
        _tags = tags;
        _version = version;
    }

    return self;
}

// Build the basic object to send to the server as a query.
- (NSMutableDictionary *)objectToSend;
{
    NSMutableDictionary *dictionary = [super objectToSend];

    [dictionary setObject:@(_version) forKey:@"ver"];

    // NSSet isn't JSON serializable
    NSMutableDictionary *transformedTags = [NSMutableDictionary dictionaryWithCapacity:_tags.count];
    for (NSString *key in _tags.allKeys) {
        transformedTags[key] = [_tags[key] allObjects];
    }

    [dictionary setObject:transformedTags forKey:@"tags"];
    [dictionary setObject:_attributes forKey:@"attrs"];

    return dictionary;
}

@end
