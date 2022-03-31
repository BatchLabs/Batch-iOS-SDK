//
//  BADisplayReceiptCenter.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BADisplayReceipt.h>
#import <Batch/BADisplayReceiptCache.h>
#import <Batch/BADisplayReceiptCenter.h>
#import <Batch/BADisplayReceiptWebserviceClient.h>
#import <Batch/BAInjection.h>
#import <Batch/BALogger.h>
#import <Batch/BAOptOut.h>
#import <Batch/BAWebserviceClientExecutor.h>
#import <Batch/BAWebserviceURLBuilder.h>

#define LOGGER_DOMAIN @"BADisplayReceiptCenter"

@interface BADisplayReceiptCenter () {
    dispatch_queue_t _dispatchQueue;
}

@end

@implementation BADisplayReceiptCenter

- (instancetype)init {
    self = [super init];
    if ([BANullHelper isNull:self]) {
        return self;
    }

    _dispatchQueue = dispatch_queue_create("com.batch.ios.dr", NULL);
    return self;
}

- (void)dealloc {
    // We need to dispatch_release for iOS 5 devices. If we don't set the variable to NULL we crash on iOS 6+ devices.
    if (_dispatchQueue) {
        _dispatchQueue = NULL;
    }
}

/*!
 @method batchDidStart
 @abstract Called after Batch runtime begins its process.
 */
+ (void)batchDidStart {
    [self send];
}

/**
Read receipt from cache and try to send them to Batch server
*/
+ (void)send {
    [[BAInjection injectClass:BADisplayReceiptCenter.class] sendIfNonOptout];
}

/**
Send read receipt if the SDK is non opt-out
*/
- (void)sendIfNonOptout {
    dispatch_async(_dispatchQueue, ^{
      BOOL isOptOut = [[BAOptOut instance] isOptedOut];
      // Save opt out state to shared user defaults
      [BADisplayReceiptCache saveIsOptOut:isOptOut];

      if (!isOptOut) {
          [self send];
      }
    });
}

/**
Read receipt from cache and try to send them to Batch server
*/
- (void)send {
    NSArray<NSURL *> *files = [BADisplayReceiptCache cachedFiles];
    if (files != nil) {
        NSError *receiptError;
        NSMutableArray<BADisplayReceipt *> *receipts = [NSMutableArray array];
        NSMutableArray<NSURL *> __block *filesToDelete = [NSMutableArray array];
        for (NSURL *file in files) {
            NSData *data = [BADisplayReceiptCache readFromFile:file];
            if (data != nil) {
                receiptError = nil;
                BADisplayReceipt *receipt = [BADisplayReceipt unpack:data error:&receiptError];
                if (receipt != nil) {
                    // Update payload before send
                    [receipt setSendAttempt:[receipt sendAttempt] + 1];
                    [receipt setReplay:true];

                    // Resave the receipt
                    if ([BADisplayReceiptCache writeToFile:file data:[receipt pack:&receiptError]]) {
                        [receipts addObject:receipt];
                        [filesToDelete addObject:file];
                    }
                }

                if (receiptError != nil) {
                    [BALogger errorForDomain:LOGGER_DOMAIN
                                     message:@"Could not unpack/pack data from file, deleting invalid receipt: %@.",
                                             [receiptError localizedDescription]];
                    [BADisplayReceiptCache remove:file];
                }
            }
        }

        if ([receipts count] <= 0) {
            // Nothing to send
            return;
        }

        BAWebserviceClient *wsClient =
            [[BADisplayReceiptWebserviceClient alloc] initWithReceipts:receipts
                                                               success:^() {
                                                                 for (NSURL *file in filesToDelete) {
                                                                     [BADisplayReceiptCache remove:file];
                                                                 }
                                                               }
                                                                 error:nil];
        [BAWebserviceClientExecutor.sharedInstance addClient:wsClient];
    }
}

@end
