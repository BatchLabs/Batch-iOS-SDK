#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Batch/BALocalCampaignCountedEvent.h>
#import <Batch/BADirectories.h>
#import <Batch/BAParameter.h>

#import <sqlite3.h>

#define TRACKER_DATABASE_NAME    @"ba_local_campaigns_tracker.db"
#define TABLE_EVENT              @"event"
#define COLUMN_DB_ID             @"_db_id"

#define TRACKER_DB_VERSION       @1

#define LOGGER_DOMAIN         @"LocalCampaignsSQLTracker"

@interface BALocalCampaignsSQLTracker ()
{
    sqlite3 *_database;

    sqlite3_stmt *_eventInsertStatement;
    sqlite3_stmt *_eventSelectStatement;
}
@end

@implementation BALocalCampaignsSQLTracker

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
        self.lock = [NSObject new];
        
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

    // If the database already exists, check if we need to upgrade it
    // Future migration code goes here
    /*if( [[NSFileManager defaultManager] fileExistsAtPath:dbPath] )
    {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersUserProfileDBVersion fallback:@-1];
    }
    */

    if (sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while opening sqlite database, In-App campaigns events will not be persisted/read from disk."];
        return false;
    }

    BOOL eventTableCreated = [self executeSimpleStatement:[NSString stringWithFormat:@"create table if not exists %@"
            "(campaign_id text not null, kind integer, count integer, last_occurrence integer, unique (campaign_id, kind) on conflict replace);", TABLE_EVENT]];

    if (!eventTableCreated) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating sqlite event table, In-App campaigns events will not be persisted/read from disk."];
        return false;
    }

    [BAParameter setValue:TRACKER_DB_VERSION forKey:kParametersInAppTrackerDBVersion saved:YES];
    
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

#pragma mark BAInAppTrackerProtocol methods

- (BALocalCampaignCountedEvent*)trackEventForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    BALocalCampaignCountedEvent *currentEventInfo = [self eventInformationForCampaignID:campaignID kind:kind];

    @synchronized(self.lock) {
    
        currentEventInfo.count++;
        currentEventInfo.lastOccurrence = [NSDate date];

        sqlite3_clear_bindings(_eventInsertStatement);

        sqlite3_bind_text(_eventInsertStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_int(_eventInsertStatement, 2, currentEventInfo.kind);
        sqlite3_bind_int64(_eventInsertStatement, 3, currentEventInfo.count);
        sqlite3_bind_double(_eventInsertStatement, 4, [currentEventInfo.lastOccurrence timeIntervalSince1970]);

        int result = sqlite3_step(_eventInsertStatement);
        sqlite3_reset(_eventInsertStatement);

        if (result != SQLITE_DONE) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"An unknown error occurred while tracking an event for the campaign '%@', kind: '%lu'", campaignID, (unsigned long)kind];
            return nil;
        }

        return currentEventInfo;
        
    }
}

- (BALocalCampaignCountedEvent*)eventInformationForCampaignID:(NSString*)campaignID kind:(BALocalCampaignTrackerEventKind)kind {
    
    @synchronized(self.lock) {
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

@end
