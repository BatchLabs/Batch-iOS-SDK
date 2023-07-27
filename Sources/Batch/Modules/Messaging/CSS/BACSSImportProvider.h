//
//  BACSSImportProvider.h
//  Batch
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BACSSImportProvider <NSObject>

@required
- (NSString *_Nullable)contentForImportNamed:(NSString *_Nonnull)importName;

@end
