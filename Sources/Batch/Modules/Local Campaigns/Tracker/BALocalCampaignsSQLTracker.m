#import <Batch/BADirectories.h>
#import <Batch/BALocalCampaignCountedEvent.h>
#import <Batch/BALocalCampaignsSQLTracker.h>
#import <Batch/BALocalCampaignsVersion.h>
#import <Batch/BAParameter.h>

#import <sqlite3.h>

#define TRACKER_DATABASE_NAME @"ba_local_campaigns_tracker.db"
#define TABLE_EVENT @"event"
#define COLUMN_DB_ID @"_db_id"
#define COLUMN_NAME_CUSTOM_USER_ID @"custom_user_id"

#define TABLE_VIEW_EVENTS @"view_events"
#define COLUMN_NAME_VE_TIMESTAMP @"timestamp_s"
#define COLUMN_NAME_VE_CAMPAIGN_ID @"campaign_id"
#define TRIGGER_VIEW_EVENTS_NAME @"trigger_clean_view_events"

#define TRACKER_DB_VERSION @3

#define LOGGER_DOMAIN @"LocalCampaignsSQLTracker"

@interface BALocalCampaignsSQLTracker () {
    sqlite3 *_database;

    sqlite3_stmt *_eventInsertStatement;
    sqlite3_stmt *_eventSelectStatement;
    sqlite3_stmt *_eventSelectCEPStatement;
    sqlite3_stmt *_viewEventInsertStatement;
}
@end

@implementation BALocalCampaignsSQLTracker {
    NSObject *_lock;
}

/**
 * Returns the singleton instance of the SQL tracker.
 * Thread-safe implementation using dispatch_once.
 */
+ (BALocalCampaignsSQLTracker *)instance {
    static BALocalCampaignsSQLTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BALocalCampaignsSQLTracker alloc] init];
    });

    return sharedInstance;
}

/**
 * Initializes the SQL tracker instance.
 * Sets up the database connection and prepares SQL statements.
 */
- (instancetype)init {
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

/**
 * Sets up the SQLite database connection and handles migrations.
 * Creates or upgrades the database schema as needed.
 * @return YES if setup was successful, NO otherwise
 */
- (BOOL)setupDatabase {
    [self close];

    NSString *dbPath =
        [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:TRACKER_DATABASE_NAME];

    // Migrations: If the database already exists, check if we need to upgrade it
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersInAppTrackerDBVersion fallback:@-1];
        if ([oldDbVesion isEqualToNumber:@1]) {
            // Opening db to execute migrations
            if (![self openDB:dbPath]) {
                return false;
            }
            [self createViewEventsTable];
            [self createViewEventsTrigger];
            [self saveDBVersion];
            return true;
        } else if ([oldDbVesion isEqualToNumber:@2]) {
            // Migration from version 2 to 3: Add custom_user_id and version columns
            if (![self openDB:dbPath]) {
                return false;
            }
            [self migrateFromVersion2To3];
            [self saveDBVersion];
            return true;
        } else if (![oldDbVesion isEqualToNumber:TRACKER_DB_VERSION]) {
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

/// Migrate database from version 2 to 3
- (void)migrateFromVersion2To3 {
    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Migrating local campaigns database from version 2 to 3"];

    // Create new event table with custom_user_id and version columns
    NSString *createNewEventTable =
        [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_v3 "
                                   @"(campaign_id TEXT NOT NULL, kind INTEGER, count INTEGER, last_occurrence INTEGER, "
                                   @"%@ TEXT, "
                                   @"UNIQUE (campaign_id, kind, %@) ON CONFLICT REPLACE)",
                                   TABLE_EVENT, COLUMN_NAME_CUSTOM_USER_ID, COLUMN_NAME_CUSTOM_USER_ID];

    // Create new view_events table with custom_user_id and version columns
    NSString *createNewViewEventsTable =
        [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@_v3 "
                                   @"(%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT NULL, %@ INTEGER NOT NULL, "
                                   @"%@ TEXT)",
                                   TABLE_VIEW_EVENTS, COLUMN_DB_ID, COLUMN_NAME_VE_CAMPAIGN_ID,
                                   COLUMN_NAME_VE_TIMESTAMP, COLUMN_NAME_CUSTOM_USER_ID];

    // Copy data from old event table to new table with default values for new columns
    NSString *copyEventData =
        [NSString stringWithFormat:@"INSERT INTO %@_v3 (campaign_id, kind, count, last_occurrence, %@) "
                                   @"SELECT campaign_id, kind, count, last_occurrence, '' FROM %@",
                                   TABLE_EVENT, COLUMN_NAME_CUSTOM_USER_ID, TABLE_EVENT];

    // Copy data from old view_events table to new table with default values for new columns
    NSString *copyViewEventsData =
        [NSString stringWithFormat:@"INSERT INTO %@_v3 (%@, %@, %@) "
                                   @"SELECT %@, %@, '' FROM %@",
                                   TABLE_VIEW_EVENTS, COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP,
                                   COLUMN_NAME_CUSTOM_USER_ID, COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP,
                                   TABLE_VIEW_EVENTS];

    // Drop old tables
    NSString *dropOldEventTable = [NSString stringWithFormat:@"DROP TABLE %@", TABLE_EVENT];
    NSString *dropOldViewEventsTable = [NSString stringWithFormat:@"DROP TABLE %@", TABLE_VIEW_EVENTS];

    // Rename new tables
    NSString *renameNewEventTable =
        [NSString stringWithFormat:@"ALTER TABLE %@_v3 RENAME TO %@", TABLE_EVENT, TABLE_EVENT];
    NSString *renameNewViewEventsTable =
        [NSString stringWithFormat:@"ALTER TABLE %@_v3 RENAME TO %@", TABLE_VIEW_EVENTS, TABLE_VIEW_EVENTS];

    // Execute all statements
    if (![self executeSimpleStatement:createNewEventTable] || ![self executeSimpleStatement:createNewViewEventsTable] ||
        ![self executeSimpleStatement:copyEventData] || ![self executeSimpleStatement:copyViewEventsData] ||
        ![self executeSimpleStatement:dropOldEventTable] || ![self executeSimpleStatement:dropOldViewEventsTable] ||
        ![self executeSimpleStatement:renameNewEventTable] || ![self executeSimpleStatement:renameNewViewEventsTable]) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while migrating database tables to version 3"];
        return;
    }

    [BALogger debugForDomain:LOGGER_DOMAIN message:@"Successfully migrated local campaigns database to version 3"];
}

/// Open the database
- (BOOL)openDB:(NSString *)path {
    if (sqlite3_open([path cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while opening sqlite database, In-App campaigns events will not be "
                                 @"persisted/read from disk."];
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
            sqlite3_finalize(_eventSelectCEPStatement);
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
    NSString *createStatement =
        [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ "
                                   @"(campaign_id TEXT NOT NULL, kind INTEGER, count INTEGER, last_occurrence INTEGER, "
                                   @"%@ TEXT DEFAULT '', "
                                   @"UNIQUE (campaign_id, kind, %@) ON CONFLICT REPLACE)",
                                   TABLE_EVENT, COLUMN_NAME_CUSTOM_USER_ID, COLUMN_NAME_CUSTOM_USER_ID];

    BOOL eventTableCreated = [self executeSimpleStatement:createStatement];

    if (!eventTableCreated) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while creating sqlite event table, In-App campaigns events will not be "
                                 @"persisted/read from disk."];
    }
    return eventTableCreated;
}

/// SQL query to create the views events table/
- (BOOL)createViewEventsTable {
    NSString *statement = [NSString
        stringWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT NULL, %@ INTEGER NOT NULL, "
            @"%@ TEXT)",
            TABLE_VIEW_EVENTS, COLUMN_DB_ID, COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP,
            COLUMN_NAME_CUSTOM_USER_ID];

    if (sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating the sqlite views event table."];
        return false;
    }
    return true;
}

/// SQL query to create a trigger when a new row is inserted into the view events table
- (BOOL)createViewEventsTrigger {
    NSString *statement = [NSString
        stringWithFormat:@"CREATE TRIGGER IF NOT EXISTS %@ AFTER INSERT ON %@ BEGIN DELETE FROM %@ WHERE %@=( SELECT "
                         @"min(%@)  FROM %@ ) AND (SELECT count(*) from %@ )>100; END;",
                         TRIGGER_VIEW_EVENTS_NAME, TABLE_VIEW_EVENTS, TABLE_VIEW_EVENTS, COLUMN_NAME_VE_TIMESTAMP,
                         COLUMN_NAME_VE_TIMESTAMP, TABLE_VIEW_EVENTS, TABLE_VIEW_EVENTS];

    if (sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating the sqlite views event trigger."];
        return false;
    }
    return true;
}

/**
 * Prepares all SQL statements for database operations.
 * Creates prepared statements for insert, select, and update operations.
 * @return YES if all statements were prepared successfully, NO otherwise
 */
- (BOOL)prepareStatements {
    _eventInsertStatement = NULL;

    NSString *statement = [NSString
        stringWithFormat:@"INSERT INTO %@ (campaign_id, kind, count, last_occurrence, %@) VALUES (?, ?, ?, ?, ?)",
                         TABLE_EVENT, COLUMN_NAME_CUSTOM_USER_ID];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_eventInsertStatement,
                           NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the event sqlite insert statement, not persisting data."];
        return false;
    }

    statement = [NSString
        stringWithFormat:@"SELECT count, last_occurrence FROM %@ WHERE campaign_id=? AND kind=?", TABLE_EVENT];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_eventSelectStatement,
                           NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the event sqlite select statement, not persisting data."];
        return false;
    }

    statement =
        [NSString stringWithFormat:@"SELECT count, last_occurrence FROM %@ WHERE campaign_id=? AND kind=? AND %@=?",
                                   TABLE_EVENT, COLUMN_NAME_CUSTOM_USER_ID];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1,
                           &_eventSelectCEPStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the event sqlite select statement, not persisting data."];
        return false;
    }

    statement =
        [NSString stringWithFormat:@"INSERT INTO %@ (%@, %@, %@) VALUES (?, ?, ?)", TABLE_VIEW_EVENTS,
                                   COLUMN_NAME_VE_CAMPAIGN_ID, COLUMN_NAME_VE_TIMESTAMP, COLUMN_NAME_CUSTOM_USER_ID];
    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1,
                           &_viewEventInsertStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the view event sqlite insert statement, not persisting data."];
        return false;
    }

    return true;
}

// Executes a simple SQLite (result-less) statement and returns whether it failed or not
// Assumes _database is set and open and statement is a NSString
- (BOOL)executeSimpleStatement:(NSString *)statement {
    if (sqlite3_exec(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while executing simple statement: %@", statement];
        return NO;
    }

    return YES;
}

/// Delete all events
- (BOOL)deleteEvents {
    @synchronized(_lock) {
        NSString *deleteStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_EVENT];
        if (sqlite3_exec(self->_database, [deleteStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL,
                         NULL) != SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error clearing the events table"];
            return false;
        }
        return true;
    }
}

/// Delete all view events
- (BOOL)deleteViewEvents {
    @synchronized(_lock) {
        NSString *deleteStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_VIEW_EVENTS];
        if (sqlite3_exec(self->_database, [deleteStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL,
                         NULL) != SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error clearing the view events table"];
            return false;
        }
        return true;
    }
}

#pragma mark BAInAppTrackerProtocol methods

/**
 * Tracks a campaign event, incrementing its count and updating the last occurrence timestamp.
 * Also records the event in the view_events table for historical tracking.
 * @param campaignID The unique identifier of the campaign
 * @param kind The type of event being tracked
 * @param customUserID Optional custom user identifier for user-specific tracking
 * @return The updated event information, or nil if tracking failed
 */
- (nullable BALocalCampaignCountedEvent *)trackEventForCampaignID:(NSString *)campaignID
                                                             kind:(BALocalCampaignTrackerEventKind)kind
                                                          version:(BALocalCampaignsVersion)version
                                                     customUserID:(nullable NSString *)customUserID {
    if ([BANullHelper isNull:customUserID] || version == BALocalCampaignsVersionMEP) {
        customUserID = @"";
    }

    BALocalCampaignCountedEvent *currentEventInfo = [self eventInformationForCampaignID:campaignID
                                                                                   kind:kind
                                                                                version:version
                                                                           customUserID:customUserID];

    @synchronized(_lock) {
        currentEventInfo.count++;
        currentEventInfo.lastOccurrence = [NSDate date];

        sqlite3_clear_bindings(_eventInsertStatement);

        sqlite3_bind_text(_eventInsertStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_int(_eventInsertStatement, 2, currentEventInfo.kind);
        sqlite3_bind_int64(_eventInsertStatement, 3, currentEventInfo.count);
        sqlite3_bind_double(_eventInsertStatement, 4, [currentEventInfo.lastOccurrence timeIntervalSince1970]);
        sqlite3_bind_text(_eventInsertStatement, 5, [customUserID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);

        int result = sqlite3_step(_eventInsertStatement);
        sqlite3_reset(_eventInsertStatement);

        // Adding new entry in view events table
        sqlite3_clear_bindings(_viewEventInsertStatement);
        sqlite3_bind_text(_viewEventInsertStatement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1,
                          NULL);
        sqlite3_bind_double(_viewEventInsertStatement, 2, [currentEventInfo.lastOccurrence timeIntervalSince1970]);
        sqlite3_bind_text(_viewEventInsertStatement, 3, [customUserID cStringUsingEncoding:NSUTF8StringEncoding], -1,
                          NULL);

        int resultInsertViewEvent = sqlite3_step(_viewEventInsertStatement);
        sqlite3_reset(_viewEventInsertStatement);

        if (result != SQLITE_DONE || resultInsertViewEvent != SQLITE_DONE) {
            [BALogger
                errorForDomain:LOGGER_DOMAIN
                       message:@"An unknown error occurred while tracking an event for the campaign '%@', kind: '%lu'",
                               campaignID, (unsigned long)kind];
            return nil;
        }

        return currentEventInfo;
    }
}

/**
 * Retrieves event information for a specific campaign, event kind, and user.
 * Queries the database for existing event data and returns a populated event object.
 * @param campaignID The unique identifier of the campaign
 * @param kind The type of event to query
 * @param version The campaign version (MEP or CEP)
 * @param customUserID Optional custom user identifier for user-specific queries
 * @return A populated BALocalCampaignCountedEvent with current database values
 */
- (BALocalCampaignCountedEvent *)eventInformationForCampaignID:(NSString *)campaignID
                                                          kind:(BALocalCampaignTrackerEventKind)kind
                                                       version:(BALocalCampaignsVersion)version
                                                  customUserID:(nullable NSString *)customUserID {
    if ([BANullHelper isNull:customUserID]) {
        customUserID = @"";
    }

    @synchronized(_lock) {
        BALocalCampaignCountedEvent *retVal = [BALocalCampaignCountedEvent eventWithCampaignID:campaignID
                                                                                          kind:kind
                                                                                  customUserID:customUserID];

        if (campaignID == nil) {
            return retVal;
        }

        sqlite3_stmt *statement;
        if (version == BALocalCampaignsVersionCEP) {
            statement = _eventSelectCEPStatement;
            sqlite3_bind_text(statement, 3, [customUserID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        } else {
            statement = _eventSelectStatement;
        }

        sqlite3_bind_text(statement, 1, [campaignID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        sqlite3_bind_int(statement, 2, kind);

        if (sqlite3_step(statement) == SQLITE_ROW) {
            retVal.count = sqlite3_column_int64(statement, 0);
            if (retVal.count < 0) {
                retVal.count = 0;
            }

            double lastOccurrenceTS = sqlite3_column_double(statement, 1);
            if (lastOccurrenceTS > 0) {
                retVal.lastOccurrence = [NSDate dateWithTimeIntervalSince1970:lastOccurrenceTS];
            } else {
                retVal.lastOccurrence = nil;
            }
        }

        sqlite3_reset(statement);

        return retVal;
    }
}

/**
 * Counts the number of view events that occurred after a specific timestamp.
 * Used for tracking view frequency and determining campaign eligibility.
 * @param timestamp The timestamp to count events from (as Unix timestamp)
 * @return The number of view events since the timestamp, or nil if query failed
 */
- (nullable NSNumber *)numberOfViewEventsSince:(double)timestamp {
    @synchronized(_lock) {
        sqlite3_stmt *statement;
        NSString *query = [NSString
            stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@ > ?;", TABLE_VIEW_EVENTS, COLUMN_NAME_VE_TIMESTAMP];
        if (sqlite3_prepare_v2(_database, [query cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) !=
            SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN
                             message:@"Error while preparing the view events sqlite select statement."];
            return nil;
        }
        sqlite3_bind_double(statement, 1, timestamp);

        if (sqlite3_step(statement) != SQLITE_ROW) {
            [BALogger errorForDomain:LOGGER_DOMAIN
                             message:@"An unknown error occurred while counting the sqlite view events"];
            return nil;
        }
        NSNumber *count = [NSNumber numberWithInt:sqlite3_column_int(statement, 0)];
        sqlite3_finalize(statement);
        return count;
    }
}

/**
 * Retrieves all view events that occurred after a specific timestamp.
 * Returns detailed event information including campaign ID, custom user ID, and timestamp.
 * @param timestamp The timestamp to retrieve events from (as Unix timestamp)
 * @return An array of dictionaries containing event details, or nil if query failed
 */
- (NSArray<NSDictionary *> *)eventsSince:(double)timestamp {
    @synchronized(_lock) {
        NSMutableArray<NSDictionary *> *events = [NSMutableArray new];

        sqlite3_stmt *statement;
        NSString *query =
            [NSString stringWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE %@ > ?;", COLUMN_NAME_VE_CAMPAIGN_ID,
                                       COLUMN_NAME_CUSTOM_USER_ID, COLUMN_NAME_VE_TIMESTAMP, TABLE_VIEW_EVENTS,
                                       COLUMN_NAME_VE_TIMESTAMP];

        if (sqlite3_prepare_v2(_database, [query cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) !=
            SQLITE_OK) {
            [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while preparing the event sqlite select statement."];
            return nil;
        }

        sqlite3_bind_double(statement, 1, timestamp);

        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *eventDict = [NSMutableDictionary new];

            // Extract and add properties to the dictionary
            const unsigned char *campaignID_c = sqlite3_column_text(statement, 0);
            eventDict[COLUMN_NAME_VE_CAMPAIGN_ID] = [NSString stringWithUTF8String:(const char *)campaignID_c];

            const unsigned char *customUserID_c = sqlite3_column_text(statement, 1);
            if (customUserID_c) {
                eventDict[COLUMN_NAME_CUSTOM_USER_ID] = [NSString stringWithUTF8String:(const char *)customUserID_c];
            } else {
                eventDict[COLUMN_NAME_CUSTOM_USER_ID] = @"";
            }

            double lastOccurrenceTS = sqlite3_column_double(statement, 2);
            if (lastOccurrenceTS > 0) {
                eventDict[COLUMN_NAME_VE_TIMESTAMP] = [NSDate dateWithTimeIntervalSince1970:lastOccurrenceTS];
            } else {
                eventDict[COLUMN_NAME_VE_TIMESTAMP] = [NSNull null];
            }

            [events addObject:eventDict];
        }

        sqlite3_finalize(statement);

        return [events copy];
    }
}

@end
