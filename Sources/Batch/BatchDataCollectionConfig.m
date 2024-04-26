//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import "BatchDataCollectionConfig.h"

@interface BatchDataCollectionConfig () {
    NSNumber *_geoIPEnabled;
    NSNumber *_deviceModelEnabled;
}
@end

@implementation BatchDataCollectionConfig

- (instancetype)init {
    self = [super init];
    _geoIPEnabled = nil;
    _deviceModelEnabled = nil;
    return self;
}

- (NSNumber *_Nullable)geoIPEnabled {
    return _geoIPEnabled;
}

- (void)setGeoIPEnabled:(BOOL)geoIPEnabled {
    _geoIPEnabled = [NSNumber numberWithBool:geoIPEnabled];
}

- (NSNumber *_Nullable)deviceModelEnabled {
    return _deviceModelEnabled;
}

- (void)setDeviceModelEnabled:(BOOL)deviceModelEnabled {
    _deviceModelEnabled = [NSNumber numberWithBool:deviceModelEnabled];
}
@end
