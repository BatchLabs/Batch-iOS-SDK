//
//  BAEventSQLiteHelper.m
//  Batch
//
//  Copyright © 2017 Batch. All rights reserved.
//

#import <Batch/BAEvent.h>
#import <Batch/BAEventSQLiteHelper.h>

@implementation BAEventSQLiteHelper

+ (NSArray *)createStatementDescriptions {
    return @[
        @"id text not null", @"name text not null", @"date text not null", @"parameters text",
        @"state integer not null", @"tick integer not null", @"sdate text", @"session text"
    ];
}

+ (NSArray *)insertStatementDescriptions {
    return @[ @"id", @"name", @"date", @"parameters", @"state", @"tick", @"sdate", @"session" ];
}

- (BOOL)bindEvent:(BAEvent *)event withStatement:(sqlite3_stmt **)statement {
    if (!*statement) {
        return NO;
    }

    if (event == nil) {
        return NO;
    }

    sqlite3_bind_text(*statement, 1, [event.identifier cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    sqlite3_bind_text(*statement, 2, [event.name cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    sqlite3_bind_text(*statement, 3, [event.date cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);

    if (event.parameters) {
        sqlite3_bind_text(*statement, 4, [event.parameters cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    } else {
        sqlite3_bind_null(*statement, 4);
    }

    sqlite3_bind_int(*statement, 5, BAEventStateNew);
    sqlite3_bind_int64(*statement, 6, event.tick);

    if (event.secureDate) {
        sqlite3_bind_text(*statement, 7, [event.secureDate cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    } else {
        sqlite3_bind_null(*statement, 7);
    }

    if (event.session) {
        sqlite3_bind_text(*statement, 8, [event.session cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
    } else {
        sqlite3_bind_null(*statement, 8);
    }

    return YES;
}

@end
