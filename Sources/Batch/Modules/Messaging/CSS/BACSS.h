//
//  BACSS.h
//  CSS Test
//
//  Copyright © 2016 Batch. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BACSSDeclaration;
@class BACSSRuleset;

@interface BACSSEnvironment : NSObject

@property (assign) CGSize viewSize;
@property (assign) BOOL darkMode;

- (BOOL)environmentMatchesQuery:(NSString *)query;

@end

@interface BACSSDOMNode : NSObject

@property NSString *type;
@property NSString *identifier;
@property NSArray<NSString *> *classes;
@property BACSSDOMNode *parentNode;

- (BOOL)matchesSelector:(NSString *)selector;

@end

@interface BACSSMediaQuery : NSObject

/*!
 @property rule
 @abstract Media query rule. Only screen max width/height are supported
 */
@property NSString *rule;

/*!
 @property rulesets
 @abstract All rulesets contained in the document
 */
@property NSMutableArray<BACSSRuleset *> *rulesets;

@end

@interface BACSSDeclaration : NSObject

@property NSString *name;

@property NSString *value;

@end

@interface BACSSVariable : BACSSDeclaration

@end

@interface BACSSRuleset : NSObject

@property NSString *selector;

@property NSMutableArray<BACSSDeclaration *> *declarations;

@end

@interface BACSSDocument : NSObject

/*!
 @property rulesets
 @abstract All rulesets contained in the document
 */
@property NSMutableArray<BACSSRuleset *> *rulesets;

/*!
 @property mediaQueries
 @abstract All media queries contained in the document
 */
@property NSMutableArray<BACSSMediaQuery *> *mediaQueries;

typedef NSDictionary<NSString *, NSString *> BACSSRules;

- (BACSSRules *)flatRulesForNode:(BACSSDOMNode *)node withEnvironment:(BACSSEnvironment *)environment;

- (NSArray<BACSSDeclaration *> *)rulesForNode:(BACSSDOMNode *)node withEnvironment:(BACSSEnvironment *)environment;

- (BACSSRules *)flatRulesFromCSSDeclarations:(NSArray<BACSSDeclaration *> *)declarations;

@end
