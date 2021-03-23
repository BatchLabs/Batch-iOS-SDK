//
//  Parser.h
//  BatchObjLisp
//
//  Copyright © 2018 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Batch/BALSExpression.h>
#import <Batch/BALValues.h>
#import <Batch/BALOperators.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Simple LISP parser that errors out whenever anything unexpected happens, or ignores it.
 
 Not really robust, but will do the job as we control both ends.
 
 This parser also only supports parsing one list at a time, and nothing else.
 
 Note: This parser is NOT thread-safe, and can only be used once.
 */
@interface BALispParser : NSObject

/**
 Initialize the parser with for the given LISP S-Expression
 It should start with ( and end with )
 */
- (instancetype)initWithExpression:(NSString*)expression;

/**
 Parse.
 
 @return A S-Expression (which implements BALReducable), or an ErrorValue
 */
- (BALValue*)parse;

@end

NS_ASSUME_NONNULL_END
