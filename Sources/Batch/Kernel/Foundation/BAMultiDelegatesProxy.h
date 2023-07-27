//
//  BAMultiDelegatesProxy.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class BAMultiDelegatesProxy(NSProxy)
 @abstract Milticast delegation using proxying.
 @discussion The class create an handy multi-delegation using proxy pattern.
 */
@interface BAMultiDelegatesProxy : NSProxy

/*!
@property delegates
@abstract Delegates which receive messages from an object.
*/
@property (nonatomic, strong, readonly) NSArray *delegates;

/*!
 @property mainDelegate
 @abstract Original delegate.
 @discussion Main delegate is like any other delegate but it's used to get the value for method which need something to
 return.
 */
@property (nonatomic, strong, readonly) id mainDelegate;

/*!
 @method newProxyWithMainDelegate:other:
 @abstract Create a new multicast delegate.
 @param mainDelegate    : Original delegate object to proxy on.
 @param delegates       : Array of object that can handle the delegation.
 @return An instance of this object or nil.
 */
+ (id)newProxyWithMainDelegate:(id)mainDelegate other:(NSArray *)delegates;

@end
