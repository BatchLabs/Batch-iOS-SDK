#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Batch/BALocalCampaignCountedEvent.h>
#import <Batch/BADirectories.h>
#import <Batch/BAParameter.h>

#import <sqlite3.h>

#define TRACKER_DATABASE_NAME    @"ba_local_campaigns_tracker.db"
#define TABLE_EVENT              @"event"
#define COLUMN_DB_ID             @"_db_id"

#define TABLE_VIEW_EVENTS             @"view_events"
#define COLUMN_NAME_VE_TIMESTAMP      @"timestamp_s"
#define COLUMN_NAME_VE_CAMPAIGN_ID    @"campaign_id"
#define TRIGGER_VIEW_EVENTS_NAME      @"trigger_clean_view_events"

#define TRACKER_DB_VERSION @2

#define LOGGER_DOMAIN @"LocalCampaignsSQLTracker"

@interface BALocalCampaignsSQLTracker ()
{
    sqlite3 *_database;

    sqlite3_stmt *_eventInsertStatement;
    sqlite3_stmt *_eventSelectStatement;
    sqlite3_stmt *_viewEventInsertStatement;

}
@end

@implementation BALocalCampaignsSQLTracker {
    NSObject *_lock;
}

+ (BALocalCampaignsSQLTracker*)instance {
    static BALocalCampaignsSQLTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BALocalCampaignsSQLTracker alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [NSObject new];
        
        if (![self setupDatabase]) {
            return nil;
        }
        if (![self prepareStatements]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)setupDatabase {
    _database = NULL;

    NSString *dbPath = [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:TRACKER_DATABASE_NAME];

    // Migrations: If the database already exists, check if we need to upgrade it
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersUserProfileDBVersion fallback:@-1];
        if ([oldDbVesion isEqualToNumber:@1]) {
            // Opening db to execute migrations
            if (![self openDB:dbPath]) {
                return false;
            }
            [self createViewEventsTable];
            [self createViewEventsTrigger];
            [self saveDBVersion];
            return true;
        }
        else if (![oldDbVesion isEqualToNumber:TRACKER_DB_VERSION]) {
            // Wipe the SQLite file and recreate it if no old version (or too new) found. Safest way.
            if (![[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil]) {
                [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while upgrading sqlite database."];
                return nil;
            }
        }
    }
    
    if (![self openDB:dbPath]) {
        return false;
    }
    [self createEventTable];
    [self createViewEventsTable];
    [self createViewEventsTrigger];
    
    [self saveDBVersion];

    return true;
}

/// Save the current database version in parameters
- (void)saveDBVersion {
    [BAParameter setValue:TRACKER_DB_VERSION forKey:kParametersInAppTrackerDBVersion saved:YES];
}


/// Open the database
- (BOOL)openDB:(NSString*)path {
    if (sqlite3_open([path cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while opening sqlite database, In-App campaigns events will not be persisted/read from disk."];
        return false;
    }
    return true;
}

/// Close the database
- (void)close {
    @synchronized(_lock) {
        if (_database) {
            sqlite3_finalize(_eventInsertStatement);
            sqlite3_finalize(_eventSelectStatement);
            sqlite3_finalize(_viewEventInsertStatement);
            sqlite3_close(_database);
            _database = NULL;
        }
    }
}

/// Clear all data without destroying tables
- (void)clear {
    [self deleteEvents];
    [self deleteViewEvents];
}

/// SQL query to create the event table
- (BOOL)createEventTable {
    BOOL eventTableCreated = [self executeSimpleStatement:[NSString stringWithFormat:@"create table if not exists %@"
            "(campaign_id text not null, kind integer, count integer, last_occurrence integer, unique (campaign_id, kind) on conflict replace);", TABLE_EVENT]];

    if (!eventTableCreated) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating sqlite event table, In-App campaigns events will not be persisted/read from disk."];
    }
    return eventTableCreated;
}

/// SQL query to create the views events table/
- (BOOL)createViewEventsTable {
    NSString *statement = [NSString stringWithFormat:@"create table if not exists %@ (%@ integer primary key autoincrement, %@ text null, %@ integer not null);", TABLE_VIEW_EVENTS, COLUMN_DB_ID, COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP];

    if (sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK ) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating the sqlite views event table."];
        return false;
    }
    return true;
}

/// SQL query to create a trigger when a new row is inserted into the view events table
- (BOOL)createViewEventsTrigger {
    NSString *statement = [NSString stringWithFormat:@"CREATE TRIGGER IF NOT EXISTS %@ AFTER INSERT ON %@ BEGIN DELETE FROM %@ WHERE %@=( SELECT min(%@)  FROM %@ ) AND (SELECT count(*) from %@ )>100; END;", TRIGGER_VIEW_EVENTS_NAME, TABLE_VIEW_EVENTS, TABLE_VIEW_EVENTS, COLUMN_NAME_VE_TIMESTAMP, COLUMN_NAME_VE_TIMESTAMP, TABLE_VIEW_EVENTS, TABLE_VIEW_EVENTS ];

    if (sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK ) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating the sqlite views event trigger."];
        return false;
    }
    return true;
}

- (BOOL)prepareStatements {
    _eventInsertStatement = NULL;

    NSString *statement = [NSString stringWithFormat:@"INSERT INTO %@ (campaign_id, kind, count, last_occurrence) VALUES (?, ?, ?, ?)", TABLE_EVENT];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_eventInsertStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while preparing the event sqlite insert statement, not persisting data."];
        return false;
    }
    
    statement = [NSString stringWithFormat:@"SELECT count, last_occurrence FROM %@ WHERE campaign_id=? AND kind=?", TABLE_EVENT];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_eventSelectStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while preparing the event sqlite select statement, not persisting data."];
        return false;
    }
    
    statement = [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@) VALUES (?, ?)", TABLE_VIEW_EVENTS, COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_viewEventInsertStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while preparing the view event sqlite insert statement, not persisting data."];
        return false;
    }
    
    return true;
}

// Executes a simple SQLite (result-less) statement and returns whether it failed or not
// Assumes _database is set and open and statement is a NSString
- (BOOL)executeSimpleStatement:(NSString*)statement
{
    if( sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while executing simple statement: %@", statement];
        return NO;
    }

    return YES;
}

/// Delete all events
- (BOOL)deleteEvents {
    @synchronized (_lock) {
        NSString *deleteStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_EVENT];
        if (sqlite3_exec(self->_database, [deleteStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error clearing the events table"];
            return false;
        }
        return true;
    }
}

/// Delete all view events
- (BOOL)deleteViewEvents {
    @synchronized (_lock) {
        NSString *deleteStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_VIEW_EVENTS];
        if (sqlite3_exec(self->_database, [deleteStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error clearing the view events table"];
            return false;
        }
        return true;
    }
}

#pragma mark BAInAppTrackerProtocol methods

- (BALocalCampaignCountedEvent*)trackEventForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    BALocalCampaignCountedEvent *currentEventInfo = [self eventInformationForCampaignID:campaignID kind:kind];

    @synchronized(_lock) {
    
        currentEventInfo.count++;
        currentEventInfo.lastOccurrence = [NSDate date];

        sqlite3_clear_bindings(_eventInsertStatement);

        sqlite3_bind_text(_eventInsertStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_int(_eventInsertStatement, 2, currentEventInfo.kind);
        sqlite3_bind_int64(_eventInsertStatement, 3, currentEventInfo.count);
        sqlite3_bind_double(_eventInsertStatement, 4, [currentEventInfo.lastOccurrence timeIntervalSince1970]);

        int result = sqlite3_step(_eventInsertStatement);
        sqlite3_reset(_eventInsertStatement);
        
        // Adding new entry in view events table
        sqlite3_clear_bindings(_viewEventInsertStatement);
        sqlite3_bind_text(_viewEventInsertStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_double(_viewEventInsertStatement, 2, [currentEventInfo.lastOccurrence timeIntervalSince1970]);
        
        int resultInsertViewEvent = sqlite3_step(_viewEventInsertStatement);
        sqlite3_reset(_viewEventInsertStatement);
        
        if (result != SQLITE_DONE || resultInsertViewEvent != SQLITE_DONE) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"An unknown error occurred while tracking an event for the campaign '%@', kind: '%lu'", campaignID, (unsigned long)kind];
            return nil;
        }
        
        return currentEventInfo;
        
    }
}

- (BALocalCampaignCountedEvent*)eventInformationForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    
    @synchronized(_lock) {
        BALocalCampaignCountedEvent *retVal = [BALocalCampaignCountedEvent eventWithCampaignID:campaignID kind:kind];
        
        if (campaignID == nil) {
            return retVal;
        }

        sqlite3_bind_text(_eventSelectStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_int(_eventSelectStatement, 2, kind);

        if (sqlite3_step(_eventSelectStatement) == SQLITE_ROW) {
            retVal.count = sqlite3_column_int64(_eventSelectStatement, 0);
            if (retVal.count < 0) {
                retVal.count = 0;
            }
            
            double lastOccurrenceTS = sqlite3_column_double(_eventSelectStatement, 1);
            if (lastOccurrenceTS > 0) {
                retVal.lastOccurrence = [NSDate dateWithTimeIntervalSince1970:lastOccurrenceTS];
            } else {
                retVal.lastOccurrence = nil;
            }
        }

        sqlite3_reset(_eventSelectStatement);

        return retVal;
    }
}

- (nullable NSNumber*)numberOfViewEventsSince:(double)timestamp {
    
    @synchronized(_lock) {
        sqlite3_stmt *statement;
        NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ > ?;", TABLE_VIEW_EVENTS, COLUMN_NAME_VE_TIMESTAMP];
        if (sqlite3_prepare_v2(_database, [query cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) != SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while preparing the view events sqlite select statement."];
            return nil;
        }
        sqlite3_bind_double(statement, 1, timestamp);
        
        if (sqlite3_step(statement) != SQLITE_ROW) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"An unknown error occurred while counting the sqlite view events"];
            return nil;
        }
        NSNumber *count = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
        sqlite3_finalize(statement);
        return count;
    }
}

@end
