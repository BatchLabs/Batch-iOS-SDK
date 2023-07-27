//
//  BAUserDataOperation.h
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Foundation/Foundation.h>

// Inspired by NSBlockOperation, but supports returning a value
@interface BAUserDataOperation : NSObject {
    BOOL (^_operationBlock)(void);
}

- (instancetype)initWithBlock:(BOOL (^)(void))block;

- (BOOL)run;

@end
