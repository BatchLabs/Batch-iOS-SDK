//
//  BAReachabilityHelper.h
//  Core
//
//  Copyright (c) 2012 Batch SDK. All rights reserved.
//
#import <Foundation/Foundation.h>

#import <Batch/BAReachability.h>

/*
 typedef enum {
 NotReachable = 0,
 ReachableViaWiFi,
 ReachableViaWWAN
 } BANetworkStatus;
 */

/*!
 @class BAReachabilityHelper
 @abstract Singleton reachability class.
 @discussion Avoid miltiples feedback from Reachability instances.
 */
@interface BAReachabilityHelper : NSObject

/*!
 @method startNotifierWithHostName:
 @abstract Start the network observing for an host name.
 @param hostName : The URL string of an host.
 */
+ (void)startNotifierWithHostName:(NSString *)hostName;

/*!
 @method reachabilityForInternetConnection
 @abstract Start the standard network observing.
 */
+ (void)reachabilityForInternetConnection;

/*!
 @method updateStatus
 @abstract Ask for a network status update.
 */
+ (void)updateStatus;

/*!
 @method currentReachabilityStatus
 @abstract Return the status of the Reachability.
 @return NetworkStatus
 */
+ (BANetworkStatus)currentReachabilityStatus;

/*!
 @method isInternetReachable
 @abstract Method that will check if the internet is reachable or not.
 @return BOOL
 */
+ (BOOL)isInternetReachable;

/*!
 @method addObserver:selector:
 @abstract Add an observer in the observers list.
 @param observer : The object to call on network changes.
 @param selector : The method to perform on network changes.
 */
+ (void)addObserver:(id)observer selector:(SEL)selector;

/*!
 @method removeObserver:
 @abstract Remove an observer from the observers list.
 @param observer : The registred object.
 */
+ (void)removeObserver:(id)observer;

@end
