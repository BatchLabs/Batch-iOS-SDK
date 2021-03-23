//
//  BAUserDataWebservice.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BAQueryWebserviceClientDatasource.h>
#import <Batch/BAQueryWebserviceClientDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAUserDataSendServiceDatasource : NSObject <BAQueryWebserviceClientDatasource>

- (instancetype)initWithVersion:(long long)version
                     attributes:(nonnull NSDictionary *)attributes
                        andTags:(nonnull NSDictionary< NSString*, NSSet< NSString* >* >*)tags;

@end

@interface BAUserDataSendServiceDelegate : NSObject <BAQueryWebserviceClientDelegate>

@end

@interface BAUserDataCheckServiceDatasource : NSObject <BAQueryWebserviceClientDatasource>

- (instancetype)initWithVersion:(long long)version
                  transactionID:(nonnull NSString*)transactionID;

@end

@interface BAUserDataCheckServiceDelegate : NSObject <BAQueryWebserviceClientDelegate>

@end

NS_ASSUME_NONNULL_END
