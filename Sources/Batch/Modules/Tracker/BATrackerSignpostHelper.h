//
//  BATrackerSignpostHelper.h
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BATrackerSignpostHelperProtocol <NSObject>

- (void)trackEvent:(NSString *)event withParameters:(NSDictionary *)parameters collapsable:(BOOL)collapsable;

@end

/**
 Signpost helper for Batch's event tracker
 Allows easier event debugging in instruments

 Do not instanciate on versions iOS < 12
 */
API_AVAILABLE(ios(12.0))
@interface BATrackerSignpostHelper : NSObject <BATrackerSignpostHelperProtocol>

@end

NS_ASSUME_NONNULL_END
