//
//  BAMSGAction.h
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BAMSGAction : NSObject

@property (nullable) NSString *actionIdentifier;
@property (nonnull) NSDictionary<NSString*, NSObject*> *actionArguments;

- (BOOL)isDismissAction;

@end
