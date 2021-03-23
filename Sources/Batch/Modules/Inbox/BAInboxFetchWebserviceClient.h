//
//  BAInboxFetchWebserviceClient.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BAInboxWebserviceClientType.h>
#import <Batch/BAGETWebserviceClient.h>
#import <Batch/BAInboxWebserviceResponse.h>

@interface BAInboxFetchWebserviceClient : BAGETWebserviceClient <BAConnectionDelegate>

- (nullable instancetype)initWithIdentifier:(nonnull NSString*)identifier
                                       type:(BAInboxWebserviceClientType)type
                          authenticationKey:(nullable NSString*)authKey
                                      limit:(NSUInteger)limit
                                  fetcherId:(long long)fetcherId
                                  fromToken:(nullable NSString*)from
                                    success:(void (^ _Nullable)(BAInboxWebserviceResponse* _Nonnull response))successHandler
                                      error:(void (^ _Nullable)(NSError* _Nonnull error))errorHandler;

+ (nullable BAInboxNotificationContent *)parseRawNotification:(nonnull NSDictionary*)dictionary error:(NSError*_Nonnull*_Nullable)outErr;

@end
