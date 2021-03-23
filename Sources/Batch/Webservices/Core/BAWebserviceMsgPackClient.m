//
//  BAWebserviceMsgPackClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAWebserviceMsgPackClient.h>

@implementation BAWebserviceMsgPackClient

- (nullable instancetype)initWithMethod:(BAWebserviceClientRequestMethod)method
                                    URL:(nullable NSURL*)url
                               delegate:(nullable id<BAConnectionDelegate>)delegate
{
    return [super initWithMethod:method URL:url contentType:BAConnectionContentTypeMessagePack delegate:delegate];
}

@end
