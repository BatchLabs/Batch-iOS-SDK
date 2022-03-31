//
//  BADisplayReceiptWebserviceClient.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BADisplayReceipt.h>
#import <Batch/BADisplayReceiptWebserviceClient.h>
#import <Batch/BAErrorHelper.h>
#import <Batch/BAWebserviceURLBuilder.h>

#define LOGGER_DOMAIN @"BADisplayReceiptWebserviceClient"

@implementation BADisplayReceiptWebserviceClient {
    NSArray *_receipts;
    void (^_successHandler)(void);
    void (^_errorHandler)(NSError *_Nonnull error);
}

- (nullable instancetype)initWithReceipts:(NSArray *)receipts
                                  success:(void (^)(void))successHandler
                                    error:(void (^)(NSError *error))errorHandler;
{
    self = [super initWithMethod:BAWebserviceClientRequestMethodPost
                             URL:[BAWebserviceURLBuilder webserviceURLForHost:kParametersDisplayReceiptWebserviceBase]
                        delegate:nil];
    if (self) {
        _receipts = receipts;
        _successHandler = successHandler;
        _errorHandler = errorHandler;
    }
    return self;
}

- (nullable NSData *)requestBody:(NSError **)error {
    if ([_receipts count] <= 0) {
        return nil;
    }

    BATMessagePackWriter *writer = [[BATMessagePackWriter alloc] init];
    if (![writer writeArraySize:[_receipts count] error:error]) {
        return nil;
    }

    for (BADisplayReceipt *receipt in _receipts) {
        if (![receipt packToWriter:writer error:error]) {
            return nil;
        }
    }

    return writer.data;
}

- (void)connectionDidFinishLoadingWithData:(NSData *)data {
    [super connectionDidFinishLoadingWithData:data];

    if (_successHandler != nil) {
        _successHandler();
    }
}

- (void)connectionFailedWithError:(NSError *)error {
    [super connectionFailedWithError:error];
    if ([error.domain isEqualToString:NETWORKING_ERROR_DOMAIN] && error.code == BAConnectionErrorCauseOptedOut) {
        error = [BAErrorHelper optedOutError];
    }

    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Failure - %@", [error localizedDescription]];
    if (error != nil && _errorHandler != nil) {
        _errorHandler(error);
    }
}

@end
