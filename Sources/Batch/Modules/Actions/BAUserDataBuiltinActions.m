#import <Batch/BAUserDataBuiltinActions.h>
#import <Batch/BAActionsCenter.h>
#import <Batch/BATJsonDictionary.h>

#import <Batch/BALogger.h>

#import <Batch/BatchUser.h>

#define LOCAL_LOG_DOMAIN @"BatchActions"
#define JSON_ERROR_DOMAIN @"com.batch.module.actions.builtin"

@implementation BAUserDataBuiltinActions

+ (BatchUserAction*)tagEditAction
{
    return [BatchUserAction userActionWithIdentifier:[kBAActionsReservedIdentifierPrefix stringByAppendingString:@"user.tag"]
                                         actionBlock:^(NSString * _Nonnull identifier, NSDictionary<NSString *,NSObject*> * _Nonnull arguments, id<BatchUserActionSource> _Nullable source) {
                                             
                                             [BAUserDataBuiltinActions performTagEdit:arguments];
                                             
                                         }];
}

+ (void)performTagEdit:(NSDictionary<NSString *,NSObject*> * _Nonnull)arguments
{
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:arguments errorDomain:JSON_ERROR_DOMAIN];
    
    NSError *err = nil;
    
    NSString *collection = [json objectForKey:@"c" kindOfClass:[NSString class] allowNil:NO error:&err];
    if (collection == nil) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: %@", [err localizedDescription]];
        return;
    }
    
    if ([collection length] == 0) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: collection name is empty"];
        return;
    }
    
    NSString *tag = [json objectForKey:@"t" kindOfClass:[NSString class] allowNil:NO error:&err];
    if (tag == nil) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: %@", [err localizedDescription]];
        return;
    }
    
    if ([tag length] == 0) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: tag name is empty"];
        return;
    }
    
    NSString *action = [json objectForKey:@"a" kindOfClass:[NSString class] allowNil:NO error:&err];
    if (action == nil) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: %@", [err localizedDescription]];
        return;
    }
    
    action = [action lowercaseString];
    
    if ([@"add" isEqualToString:action]) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Adding tag '%@' to collection '%@'", tag, collection];
        BatchUserDataEditor *editor = [BatchUser editor];
        [editor addTag:tag inCollection:collection];
        [editor save];
    } else if ([@"remove" isEqualToString:action]) {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Removing tag '%@' from collection '%@'", tag, collection];
        BatchUserDataEditor *editor = [BatchUser editor];
        [editor removeTag:tag fromCollection:collection];
        [editor save];
    } else {
        [BALogger debugForDomain:LOCAL_LOG_DOMAIN message:@"Could not perform tag edit action: Unknown action '%@'", action];
    }
}

@end
