//
//  BAPartialApplicationDelegate.h
//  Batch
//
//  Created by arnaud on 15/09/2020.
//  Copyright © 2020 Batch.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Partial representation of UIApplicationDelegate, only implementing what we need
@protocol BAPartialApplicationDelegate <NSObject>

@required
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
