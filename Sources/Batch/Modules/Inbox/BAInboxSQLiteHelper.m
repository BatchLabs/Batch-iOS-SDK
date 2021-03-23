//
//  BAInboxSQLiteHelper.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInboxSQLiteHelper.h>
#import <Batch/BAInbox.h>
#import <Batch/BAJson.h>

@implementation BAInboxSQLiteHelper

+ (NSArray *)insertNotificationStatementDescriptions
{
    return @[@"notification_id",@"send_id",@"unread",@"date",@"payload"];
}

- (BOOL)bindNotification:(BAInboxNotificationContent*)notification withStatement:(sqlite3_stmt **)statement
{
    if (!*statement)
    {
        return NO;
    }
    
    if (notification == nil)
    {
        return NO;
    }
    
    sqlite3_bind_text(*statement, 1, [notification.identifiers.identifier cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    sqlite3_bind_text(*statement, 2, [notification.identifiers.sendID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    
    int isUnread = notification.isUnread ? 1 : 0;
    sqlite3_bind_int(*statement, 3, isUnread);
    sqlite3_bind_int64(*statement, 4, (long long) [notification.date timeIntervalSince1970]);
    
    NSString *json = [BAJson serialize:notification.payload error:nil];
    if (json)
    {
        sqlite3_bind_text(*statement, 5, [json cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    }
    else
    {
        return NO;
    }
    
    return YES;
}

+ (NSArray *)insertFetcherStatementDescriptions
{
    return @[@"fetcher_id",@"notification_id",@"install_id",@"custom_id"];
}


- (BOOL)bindFetcherNotification:(BAInboxNotificationContent*)notification withFetcherId:(long long)fetcherId statement:(sqlite3_stmt **)statement
{
    NSParameterAssert(notification.identifiers);
    sqlite3_bind_int64(*statement, 1, fetcherId);
    sqlite3_bind_text(*statement, 2, [notification.identifiers.identifier cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    
    const char *installId = [notification.identifiers.installID cStringUsingEncoding:NSUTF8StringEncoding];
    if (installId)
    {
        sqlite3_bind_text(*statement, 3, installId, -1, NULL);
    }
    else
    {
        sqlite3_bind_null(*statement, 3);
    }
    
    const char *customId = [notification.identifiers.customID cStringUsingEncoding:NSUTF8StringEncoding];
    if (customId)
    {
        sqlite3_bind_text(*statement, 4, customId, -1, NULL);
    }
    else
    {
        sqlite3_bind_null(*statement, 4);
    }
    
    return YES;
}


@end
