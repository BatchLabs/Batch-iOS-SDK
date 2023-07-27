//
//  BACSSParser.h
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Batch/BACSS.h>
#import <Batch/BACSSImportProvider.h>
#import <Foundation/Foundation.h>

@interface BACSSParser : NSObject

+ (instancetype)parserWithString:(NSString *)cssString andImportProvider:(id<BACSSImportProvider>)importProvider;
- (instancetype)initWithString:(NSString *)cssString andImportProvider:(id<BACSSImportProvider>)importProvider;

- (BACSSDocument *)parseWithError:(NSError **)error;

@end
