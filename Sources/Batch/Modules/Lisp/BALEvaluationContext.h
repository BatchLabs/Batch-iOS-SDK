//
//  EvaluationContext.h
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Batch/BALValues.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BALEvaluationContext <NSObject>

- (nullable BALValue*)resolveVariableNamed:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
