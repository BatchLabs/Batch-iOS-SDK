//
//  BASessionManager.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Notification sent by Batch Push when it gets a remote notification. This includes the one your app is started with (even though it is only sent when Batch starts)
 */
FOUNDATION_EXPORT NSString * _Nonnull const BATNewSessionStartedNotification;

/**
 This class manages a user session.
 
 A new session starts:
  - On a cold app start
  - If an app comes into foreground more than X seconds after the last
    (Where X is defined in a global constant)
 */
@interface BASessionManager : NSObject

@property (nonatomic, readonly, nullable) NSString *sessionID;

@end
