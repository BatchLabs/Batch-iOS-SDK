//
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Object holding the configuration parameters for the automatic data collect.
@interface BatchDataCollectionConfig : NSObject

/// Whether Batch can resolve the user's region/location from the ip address.
/// This is for Batch internal use only since you will get a new instance each time you call
/// ``Batch/BatchSDK/updateAutomaticDataCollection:`` .
- (NSNumber *_Nullable)geoIPEnabled;

/// Set whether Batch can resolve the user's region/location from the ip address.
///
/// - Parameter geoIPEnabled: Whether Batch can resolve the GeoIP on server side. Default: false
- (void)setGeoIPEnabled:(BOOL)geoIPEnabled;

/// Whether Batch can send the device model information.
/// This is for Batch internal use only since you will get a new instance each time you call
/// ``Batch/BatchSDK/updateAutomaticDataCollection:`` .
- (NSNumber *_Nullable)deviceModelEnabled;

/// Set whether Batch can send the device model information.
///
/// - Parameter deviceModelEnabled: Whether Batch can send the device model information. Default: false
- (void)setDeviceModelEnabled:(BOOL)deviceModelEnabled;

@end

/// Typed  block that will be called with an instance of the automatic data collection configuration as a parameter.
typedef void (^BatchDataCollectionConfigEditor)(BatchDataCollectionConfig *);

NS_ASSUME_NONNULL_END
