//
//  BAInboxSQLiteDatasource.m
//  Batch
//
//  Copyright © Batch.com. All rights reserved.
//

#import <Batch/BAInboxSQLiteDatasource.h>
#import <sqlite3.h>
#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>
#import <Batch/BADirectories.h>
#import <Batch/BAJson.h>
#import <Batch/BATJsonDictionary.h>
#import <Batch/BAPushPayload.h>

#define LOCAL_ERROR_DOMAIN              @"com.batch.inbox.cache"

#define COLUMN_DB_ID                    @"_db_id"

#define TABLE_FETCHERS                  @"fetchers"
#define COLUMN_FETCHER_TYPE             @"type"
#define COLUMN_FETCHER_IDENTIFIER       @"identifier"

#define TABLE_FETCHERS_NOTIFICATIONS    @"fetcher_notifications"
#define COLUMN_FETCHER_ID               @"fetcher_id"
#define COLUMN_INSTALL_ID               @"install_id"
#define COLUMN_CUSTOM_ID                @"custom_id"

#define TABLE_NOTIFICATIONS             @"notifications"
#define COLUMN_NOTIFICATION_ID          @"notification_id"
#define COLUMN_SEND_ID                  @"send_id"
#define COLUMN_UNREAD                   @"unread"
#define COLUMN_DATE                     @"date"
#define COLUMN_PAYLOAD                  @"payload"

#define DB_VERSION                      @1

@implementation BAInboxSQLiteDatasource

- (instancetype)initWithFilename:(NSString *)name forDBHelper:(id<BAInboxDBHelperProtocol>)inboxDBHelper
{
    self = [super init];
    
    if( [BANullHelper isNull:self] )
    {
        return nil;
    }
    
    self.lock = [NSObject new];
    
    if (!inboxDBHelper) {
        return nil;
    }
    
    self.inboxDBHelper = inboxDBHelper;
    
    _database = NULL;
    _insertNotificationStatement = NULL;
    _insertFetcherStatement = NULL;

    /*** Migration things ***/
    
    NSString *dbPath = [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:name];
    
    // If the database already exists, check if we need to upgrade it
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath])
    {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersInboxDBVersion fallback:@-1];
        if (![oldDbVesion isEqualToNumber:DB_VERSION])
        {
            // Wipe the SQLite file and recreate it if no old version (or too new) found. Safest way.
            if (![[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil])
            {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Error while upgrading sqlite database, not persisting notifications."];
                return nil;
            }
        }
    }
    
    /*** End of migration things ***/

    if( sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while opening sqlite database, not persisting notifications."];
        return nil;
    }
    
     /*** Table fetchers  ***/
    NSString *fecthersUniquenessStatement = [NSString stringWithFormat:@"unique(%@, %@)", COLUMN_FETCHER_TYPE, COLUMN_FETCHER_IDENTIFIER];
    NSString *createFetchersStatement = [NSString stringWithFormat:
                                         @"create table if not exists %@ (%@ integer primary key autoincrement, %@ integer not null, %@ text not null, %@);",
                                         TABLE_FETCHERS, COLUMN_DB_ID, COLUMN_FETCHER_TYPE, COLUMN_FETCHER_IDENTIFIER, fecthersUniquenessStatement];

    if( sqlite3_exec(_database, [createFetchersStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while creating the sqlite fetchers table, not persisting notifications."];
        return nil;
    }
    
    /*** Table notifications  ***/
    NSString *notificationsUniquenessStatement = [NSString stringWithFormat:@"unique(%@, %@)", COLUMN_NOTIFICATION_ID, COLUMN_SEND_ID];
    NSString *createNotificationsStatement = [NSString stringWithFormat:
                                         @"create table if not exists %@ (%@ integer primary key autoincrement, %@ text not null, %@ text not null, %@ integer not null default 0 check(%@ IN (0,1)), %@ integer not null, %@ text, %@);",
                                         TABLE_NOTIFICATIONS, COLUMN_DB_ID, COLUMN_NOTIFICATION_ID, COLUMN_SEND_ID,
                                         COLUMN_UNREAD, COLUMN_UNREAD, COLUMN_DATE, COLUMN_PAYLOAD, notificationsUniquenessStatement];
    
    if( sqlite3_exec(_database, [createNotificationsStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while creating the sqlite notifications table, not persisting notifications."];
        return nil;
    }
    
    /*** Table fetcher_notifications  ***/
    NSString *fetchersNotificationsUniquenessStatement = [NSString stringWithFormat:@"unique(%@, %@)", COLUMN_FETCHER_ID, COLUMN_NOTIFICATION_ID];
    NSString *fetchersForeignStatement = [NSString stringWithFormat:@"foreign key(%@) references %@(%@)", COLUMN_FETCHER_ID, TABLE_FETCHERS, COLUMN_DB_ID];
    NSString *notificationsForeignStatement = [NSString stringWithFormat:@"foreign key(%@) references %@(%@)", COLUMN_NOTIFICATION_ID, TABLE_NOTIFICATIONS, COLUMN_NOTIFICATION_ID];
    NSString *createFetchersNotificationsStatement = [NSString stringWithFormat:
                                         @"create table if not exists %@ (%@ integer primary key autoincrement, %@ integer not null, %@ text not null, %@ text, %@ text, %@, %@, %@);",
                                         TABLE_FETCHERS_NOTIFICATIONS, COLUMN_DB_ID, COLUMN_FETCHER_ID, COLUMN_NOTIFICATION_ID, COLUMN_INSTALL_ID,
                                         COLUMN_CUSTOM_ID, fetchersNotificationsUniquenessStatement, fetchersForeignStatement, notificationsForeignStatement];

    if( sqlite3_exec(_database, [createFetchersNotificationsStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while creating the sqlite fetcher_notifications table, not persisting notifications."];
        return nil;
    }
    
    // Database is created, save in the parameters the last known version
    [BAParameter setValue:DB_VERSION forKey:kParametersInboxDBVersion saved:YES];
    
    NSMutableString *insertNotificationString = [[NSMutableString alloc] init];
    NSMutableString *valuesNotificationString = [[NSMutableString alloc] init];
    NSArray *parameterNotificationNames = [[self.inboxDBHelper class] insertNotificationStatementDescriptions];
    for (int i = 0; i < [parameterNotificationNames count]; i++)
    {
        if (i > 0)
        {
            [insertNotificationString appendString:@", "];
            [valuesNotificationString appendString:@", "];
        }
        [insertNotificationString appendString:[parameterNotificationNames objectAtIndex:i]];
        [valuesNotificationString appendString:@"?"];
    }
   
    NSString *insertNotificationStatement = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@);",
                                             TABLE_NOTIFICATIONS, insertNotificationString, valuesNotificationString];
    
    if (sqlite3_prepare_v2(_database, [insertNotificationStatement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_insertNotificationStatement, NULL) != SQLITE_OK)
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while preparing the sqlite insert statement, not persisting notifications."];
        return nil;
    }
    
    NSMutableString *insertFetcherString = [[NSMutableString alloc] init];
    NSMutableString *valuesFetcherString = [[NSMutableString alloc] init];
    NSArray *parameterFetcherNames = [[self.inboxDBHelper class] insertFetcherStatementDescriptions];
    for (int i = 0; i < [parameterFetcherNames count]; i++)
    {
        if (i > 0)
        {
            [insertFetcherString appendString:@", "];
            [valuesFetcherString appendString:@", "];
        }
        [insertFetcherString appendString:[parameterFetcherNames objectAtIndex:i]];
        [valuesFetcherString appendString:@"?"];
    }
    
    NSString *insertFectherStatement = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@);",
                                             TABLE_FETCHERS_NOTIFICATIONS, insertFetcherString, valuesFetcherString];
    if (sqlite3_prepare_v2(_database, [insertFectherStatement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_insertFetcherStatement, NULL) != SQLITE_OK)
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while preparing the sqlite insert statement, not persisting notifications."];
        return nil;
    }
    
    return self;
}

- (void)executeUpgradeQueries:(NSArray*)statements onDatabase:(NSString*)dbPath
{
    if( sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Error while opening sqlite database, not persisting notifications."];
        [[NSException exceptionWithName:@"InboxDatasource" reason:@"Error while opening sqlite database, not persisting notifications." userInfo:nil] raise];
    }
    
    sqlite3_stmt *sql_statement = NULL;
    
    @try
    {
        for (NSString* statement in statements)
        {
            const char *update_stmt = [statement UTF8String];
            sqlite3_prepare_v2(_database, update_stmt, -1, &sql_statement, NULL);
            
            if(sqlite3_step(sql_statement) != SQLITE_DONE)
            {
                [[NSException exceptionWithName:@"Inbox" reason:@"Error while performing ALTER." userInfo:nil] raise];
            }
            
            // Release the compiled statement from memory
            sqlite3_finalize(sql_statement);
            sql_statement = NULL;
        }
    }
    @finally
    {
        if (sql_statement != NULL)
        {
            sqlite3_finalize(sql_statement);
        }
        sqlite3_close(_database);
    }
    
}

#pragma mark -
#pragma mark BAInboxDatasourceProtocol methods

- (void)close
{
    @synchronized(self.lock)
    {
        if( self->_database )
        {
             sqlite3_finalize(self->_insertNotificationStatement);
             self->_insertNotificationStatement = NULL;
            
            sqlite3_close(self->_database);
            self->_database = NULL;
        }
    }
}

- (void)clear
{
    @synchronized(self.lock)
    {
        NSString *clearStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_FETCHERS];
        if (sqlite3_exec(self->_database, [clearStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK)
        {
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error clearing the table"];
        }
        
        clearStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_FETCHERS_NOTIFICATIONS];
        if (sqlite3_exec(self->_database, [clearStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK)
        {
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error clearing the table"];
        }
        
        clearStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_NOTIFICATIONS];
        if (sqlite3_exec(self->_database, [clearStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK)
        {
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error clearing the table"];
        }
    }
}

- (long long)createFetcherIdWith:(BAInboxWebserviceClientType)type identifier:(nonnull NSString*)identifier
{
    @synchronized(self.lock)
    {
        if ([BANullHelper isStringEmpty:identifier]) {
            return -1;
        }
        
        NSString *insertQuery = [NSString stringWithFormat:@"INSERT OR ABORT INTO %@ (%@, %@) VALUES (?, ?);", TABLE_FETCHERS, COLUMN_FETCHER_TYPE, COLUMN_FETCHER_IDENTIFIER];
        sqlite3_stmt *insertStatement;
        if (sqlite3_prepare_v2(self->_database, [insertQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &insertStatement, NULL) != SQLITE_OK)
        {
            return -1;
        }
        
        sqlite3_bind_int(insertStatement, 1, (int) type);
        sqlite3_bind_text(insertStatement, 2, [identifier cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        
        int stepResult = sqlite3_step(insertStatement);
        sqlite3_finalize(insertStatement);
        
        if (stepResult == SQLITE_CONSTRAINT)
        {
            NSString *selectQuery = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ?;", COLUMN_DB_ID, TABLE_FETCHERS, COLUMN_FETCHER_TYPE, COLUMN_FETCHER_IDENTIFIER];
            sqlite3_stmt *selectStatement;
            
            if (sqlite3_prepare_v2(self->_database, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], -1, &selectStatement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_int(selectStatement, 1, (int) type);
                sqlite3_bind_text(selectStatement, 2, [identifier cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
                if (sqlite3_step(selectStatement) == SQLITE_ROW)
                {
                    int fetcherId = sqlite3_column_int(selectStatement, 0);
                    sqlite3_finalize(selectStatement);
                    return fetcherId;
                } else {
                    [BALogger errorForDomain:@"InboxDatasource" message:@"Error while getting fetcher id."];
                    return -1;
                }
            }
        }
        else if (stepResult == SQLITE_DONE)
        {
            return sqlite3_last_insert_rowid(self->_database);
        }
    }
    
    [BALogger errorForDomain:@"InboxDatasource" message:@"Error while adding fetcher to sqlite, giving up."];
    return -1;
}

-(BOOL)insertResponse:(BAInboxWebserviceResponse *)response withFetcherId:(long long)fetcherId
{
    if (!response || fetcherId == -1) {
        return NO;
    }
    
    for (BAInboxNotificationContent *notification in response.notifications) {
        [self insertNotification:notification withFetcherId:fetcherId];
    }
    
    return YES;
}

- (BOOL)insertNotification:(BAInboxNotificationContent *)notification withFetcherId:(long long)fetcherId
{
    @synchronized(self.lock)
    {
        if (!self->_insertNotificationStatement || !self->_insertFetcherStatement) {
            return NO;
        }
        
        // Start a new transaction
        if (sqlite3_exec(self->_database, [@"BEGIN EXCLUSIVE TRANSACTION;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
            return NO;
        }
        
        sqlite3_clear_bindings(self->_insertNotificationStatement);
        sqlite3_stmt *stmt = self->_insertNotificationStatement;
        if (![self.inboxDBHelper bindNotification:notification withStatement:&stmt])
        {
            return NO;
        }
        
        // Insert in notification table
        int stepResult = sqlite3_step(self->_insertNotificationStatement);
        sqlite3_reset(self->_insertNotificationStatement);

        if (stepResult != SQLITE_DONE) {
            // We ROOLBACK and just ignore any errors.
            // Either the transation already was rolled back, or there is nothing we can do anyway.
            sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while adding notification to sqlite, giving up."];
            return NO;
        }
        
        sqlite3_clear_bindings(self->_insertFetcherStatement);
        stmt = self->_insertFetcherStatement;
        if (![self.inboxDBHelper bindFetcherNotification:notification withFetcherId:fetcherId statement:&stmt])
        {
            return NO;
        }
        
        // Insert in fetcher_notification table
        stepResult = sqlite3_step(self->_insertFetcherStatement);
        sqlite3_reset(self->_insertFetcherStatement);

        if (stepResult != SQLITE_DONE)
        {
            // We ROOLBACK and just ignore any errors.
            // Either the transation already was rolled back, or there is nothing we can do anyway.
            sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while adding notification to sqlite, giving up."];
            return NO;
        }
        
        sqlite3_exec(self->_database, [@"COMMIT;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
    }
    
    return YES;
}

-(NSArray<BAInboxCandidateNotification*> *)candidateNotificationsFromCursor:(NSString *)cursor limit:(NSUInteger)limit fetcherId:(long long)fetcherId
{
    NSMutableArray<BAInboxCandidateNotification*> *candidates = [NSMutableArray new];
    @synchronized(self.lock)
    {
        sqlite3_stmt *statement;
        if (![BANullHelper isStringEmpty:cursor]) {
            long long cursorTime = [self notificationTime:cursor];
            if (cursorTime != -1) {
                NSString *selectSQL = [NSString stringWithFormat:@"SELECT %@, %@.%@, %@, %@ FROM %@ INNER JOIN %@ ON %@.%@ = %@.%@ WHERE %@ < ? AND %@ = ? ORDER BY %@ DESC LIMIT ?",
                                       COLUMN_FETCHER_ID,
                                       TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                       COLUMN_UNREAD,
                                       COLUMN_DATE,
                                       TABLE_FETCHERS_NOTIFICATIONS,
                                       TABLE_NOTIFICATIONS,
                                       TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                       TABLE_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                       COLUMN_DATE,
                                       COLUMN_FETCHER_ID,
                                       COLUMN_DATE];
                
                if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK) {
                    sqlite3_bind_int64(statement, 1, cursorTime);
                    sqlite3_bind_int64(statement, 2, fetcherId);
                    sqlite3_bind_int64(statement, 3, limit);
                } else {
                    [BALogger errorForDomain:@"InboxDatasource" message:@"Error while getting candidates notifications."];
                    return candidates;
                }
            } else {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Error while getting notification time."];
                return candidates;
            }
        } else {
            NSString *selectSQL = [NSString stringWithFormat:@"SELECT %@, %@.%@, %@, %@ FROM %@ INNER JOIN %@ ON %@.%@ = %@.%@ WHERE %@ = ? ORDER BY %@ DESC LIMIT ?",
                                   COLUMN_FETCHER_ID,
                                   TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                   COLUMN_UNREAD,
                                   COLUMN_DATE,
                                   TABLE_FETCHERS_NOTIFICATIONS,
                                   TABLE_NOTIFICATIONS,
                                   TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                   TABLE_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                                   COLUMN_FETCHER_ID,
                                   COLUMN_DATE];
            
            if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK) {
                sqlite3_bind_int64(statement, 1, fetcherId);
                sqlite3_bind_int64(statement, 2, limit);
            } else {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Error while getting candidates notifications."];
                return candidates;
            }
        }
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
            BOOL unread = sqlite3_column_int(statement, 2) == 1;
            
            const char *identifierChar = (const char*) sqlite3_column_text(statement, 1);
            NSString *identifier = nil;
            if (identifierChar != NULL) {
                identifier = [NSString stringWithUTF8String:(const char *) identifierChar];
                
                BAInboxCandidateNotification *candidate = [[BAInboxCandidateNotification alloc] init];
                candidate.identifier = identifier;
                candidate.isUnread = unread;
                
                [candidates addObject:candidate];
            }
        }
        
        sqlite3_finalize(statement);
    }
    return candidates;
}

-(NSArray<BAInboxNotificationContent*> *)notifications:(NSArray<NSString*> *)notificaitonIds withFetcherId:(long long)fetcherId
{
    NSMutableArray<BAInboxNotificationContent*> *notifications = [NSMutableArray new];
    if ([notificaitonIds count] <= 0) {
        return notifications;
    }
    
    @synchronized(self.lock)
    {
        NSMutableString *valuesString = [[NSMutableString alloc] init];
        for (int i = 0; i < [notificaitonIds count]; i++)
        {
            if (i > 0)
            {
                [valuesString appendString:@", "];
            }
            [valuesString appendString:@"?"];
        }
        
        sqlite3_stmt *statement;
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT * FROM %@ INNER JOIN %@ ON %@.%@ = %@.%@ WHERE %@ = ? AND %@.%@ IN(%@) ORDER BY %@ DESC",
                               TABLE_FETCHERS_NOTIFICATIONS,
                               TABLE_NOTIFICATIONS,
                               TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                               TABLE_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                               COLUMN_FETCHER_ID,
                               TABLE_FETCHERS_NOTIFICATIONS, COLUMN_NOTIFICATION_ID,
                               valuesString,
                               COLUMN_DATE];

        if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int64(statement, 1, fetcherId);
            for (int i = 0; i < [notificaitonIds count]; i++)
            {
                sqlite3_bind_text(statement, i + 2, [[notificaitonIds objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            }
            
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                BAInboxNotificationContent *notification = [self createNotificationFromStatement:statement];
                if (notification != nil) {
                    [notifications addObject:notification];
                }
            }
            
            sqlite3_finalize(statement);
        }
        else
        {
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while getting notifications."];
        }
    }
    return notifications;
}

-(NSString *)updateNotification:(NSDictionary *)dictionary withFetcherId:(long long)fetcherId
{
    BATJsonDictionary *json = [[BATJsonDictionary alloc] initWithDictionary:dictionary errorDomain:@"InboxWebserviceClient"];
    
    NSError *err = nil;
    NSString* notificationId = [json objectForKey:@"notificationId" kindOfClass:[NSString class] allowNil:false error:&err];
    if (err != nil) {
        [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get notification id from payload."];
        return nil;
    }
    
    NSMutableDictionary *notifcationFields = [NSMutableDictionary new];
    NSMutableDictionary *notifcationFetcherFields = [NSMutableDictionary new];
    NSArray *keys = [dictionary allKeys];
    
    for (NSString *key in keys) {
        if ([key isEqualToString:@"sendId"]) {
            NSString *sendId = [json objectForKey:@"sendId" kindOfClass:[NSString class] allowNil:false error:&err];
            if (err != nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get send id from payload."];
                return nil;
            }
            
            [notifcationFields setObject:sendId forKey:COLUMN_SEND_ID];
        } else if ([key isEqualToString:@"read"]) {
            NSNumber *read = [json objectForKey:@"read" kindOfClass:[NSNumber class] fallback:@(false)];
            NSNumber *opened = [json objectForKey:@"opened" kindOfClass:[NSNumber class] fallback:@(false)];
            NSNumber *isUnread = ![read boolValue] && ![opened boolValue] ? @1 : @0;
            
            [notifcationFields setObject:isUnread forKey:COLUMN_UNREAD];
        } else if ([key isEqualToString:@"notificationTime"]) {
            NSNumber *time = [json objectForKey:@"notificationTime" kindOfClass:[NSNumber class] allowNil:false error:&err];
            if (err != nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get notification time from payload."];
                return nil;
            }
            
            [notifcationFields setObject:time forKey:COLUMN_DATE];
        } else if ([key isEqualToString:@"payload"]) {
            NSDictionary *payload = [json objectForKey:@"payload" kindOfClass:[NSDictionary class] allowNil:false error:&err];
            if (err != nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get payload."];
                return nil;
            }
            
            NSString *jsonPayload = [BAJson serialize:payload error:nil];
            if (jsonPayload == nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not serialize payload."];
                return nil;
            }
            
            [notifcationFields setObject:jsonPayload forKey:COLUMN_PAYLOAD];
        } else if ([key isEqualToString:@"installId"]) {
            NSString *installId = [json objectForKey:@"installId" kindOfClass:[NSString class] allowNil:false error:&err];
            if (err != nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get install id from payload."];
                return nil;
            }
            
            [notifcationFetcherFields setObject:installId forKey:COLUMN_INSTALL_ID];
        } else if ([key isEqualToString:@"customId"]) {
            NSString *customId = [json objectForKey:@"customId" kindOfClass:[NSString class] allowNil:false error:&err];
            if (err != nil) {
                [BALogger errorForDomain:@"InboxDatasource" message:@"Could not get custom id from payload."];
                return nil;
            }
            
            [notifcationFetcherFields setObject:customId forKey:COLUMN_CUSTOM_ID];
        }
    }
    
    if ([notifcationFields count] <= 0) {
        // JSON contains only notificationId
        // Meaning we have the latest payload and states in DB
        return notificationId;
    }
    
    // Ordering keys to create statement then bind values to it
    NSArray *notificationKeys = [[notifcationFields allKeys] mutableCopy];
    notificationKeys = [notificationKeys sortedArrayUsingSelector:@selector(compare:)];
    
    int i = 0;
    NSString *setQuery = @"";
    for (NSString *key in notificationKeys) {
        if (i > 0) {
            setQuery = [setQuery stringByAppendingString:@", "];
        }
        setQuery = [setQuery stringByAppendingString:key];
        setQuery = [setQuery stringByAppendingString:@" = ?"];
        i += 1;
    }
    
    @synchronized(self.lock)
    {
        NSString *updateNotificationSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?", TABLE_NOTIFICATIONS, setQuery, COLUMN_NOTIFICATION_ID];
        sqlite3_stmt *updateNotificationStatement;
        if (sqlite3_prepare_v2(self->_database, [updateNotificationSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &updateNotificationStatement, NULL) != SQLITE_OK) {
           // TODO ERROR
           return nil;
        }
        
        i = 1;
        for (NSString *key in notificationKeys) {
            if ([key isEqualToString:COLUMN_SEND_ID]) {
                NSString *sendId = [notifcationFields objectForKey:key];
                sqlite3_bind_text(updateNotificationStatement, i, [sendId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            } else if ([key isEqualToString:COLUMN_UNREAD]) {
                NSNumber *isUnread = [notifcationFields objectForKey:key];
                sqlite3_bind_int(updateNotificationStatement, i, [isUnread intValue]);
            } else if ([key isEqualToString:COLUMN_DATE]) {
                NSNumber *time = [notifcationFields objectForKey:key];
                sqlite3_bind_int64(updateNotificationStatement, i, [time longLongValue] / 1000);
            } else if ([key isEqualToString:COLUMN_PAYLOAD]) {
                NSString *payload = [notifcationFields objectForKey:key];
                sqlite3_bind_text(updateNotificationStatement, i, [payload cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            }
           
            // Keys are sorted, so we bind in the same order as we created the statement
            i += 1;
        }
        
        sqlite3_bind_text(updateNotificationStatement, i, [notificationId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        
        sqlite3_stmt *updateNotificationFetcherStatement = nil;
        if ([notifcationFetcherFields count] > 0) {
            NSArray *notificationFetcherKeys = [[notifcationFetcherFields allKeys] mutableCopy];
            notificationFetcherKeys = [notificationFetcherKeys sortedArrayUsingSelector:@selector(compare:)];
            
            i = 0;
            setQuery = @"";
            for (NSString *key in notificationFetcherKeys) {
                if (i > 0) {
                    setQuery = [setQuery stringByAppendingString:@", "];
                }
                setQuery = [setQuery stringByAppendingString:key];
                setQuery = [setQuery stringByAppendingString:@" = ?"];
                 i += 1;
            }
            
            NSString *updateNotificationFetcherSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ? AND %@ = ?", TABLE_FETCHERS_NOTIFICATIONS, setQuery, COLUMN_NOTIFICATION_ID, COLUMN_FETCHER_ID];
            if (sqlite3_prepare_v2(self->_database, [updateNotificationFetcherSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &updateNotificationFetcherStatement, NULL) != SQLITE_OK) {
               // TODO ERROR
               // TODO finalize previous statement
               return nil;
            }
            
            i = 1;
            for (NSString *key in notificationFetcherKeys) {
                if ([key isEqualToString:COLUMN_INSTALL_ID]) {
                    NSString *installId = [notifcationFetcherFields objectForKey:key];
                    sqlite3_bind_text(updateNotificationFetcherStatement, i, [installId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
                } else if ([key isEqualToString:COLUMN_CUSTOM_ID]) {
                    NSString *installId = [notifcationFetcherFields objectForKey:key];
                    sqlite3_bind_text(updateNotificationFetcherStatement, i, [installId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
                }
               
                // Keys are sorted, so we bind in the same order as we created the statement
                i += 1;
            }
            
            sqlite3_bind_text(updateNotificationFetcherStatement, i, [notificationId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            sqlite3_bind_int64(updateNotificationFetcherStatement, i + 1, fetcherId);
            
        }
        
        // Start a new transaction
        if (sqlite3_exec(self->_database, [@"BEGIN EXCLUSIVE TRANSACTION;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
            return nil;
        }
        
        // Insert in notification table
        int stepResult = sqlite3_step(updateNotificationStatement);
        if (stepResult != SQLITE_DONE) {
            // We ROOLBACK and just ignore any errors.
            // Either the transation already was rolled back, or there is nothing we can do anyway.
            sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while updating notification to sqlite, giving up."];
            return nil;
        }
        
        if (updateNotificationFetcherStatement != nil) {
            stepResult = sqlite3_step(updateNotificationFetcherStatement);
            if (stepResult != SQLITE_DONE) {
                // We ROOLBACK and just ignore any errors.
                // Either the transation already was rolled back, or there is nothing we can do anyway.
                sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
                [BALogger errorForDomain:@"InboxDatasource" message:@"Error while updating notification to sqlite, giving up."];
                return nil;
            }
        }
        
        sqlite3_exec(self->_database, [@"COMMIT;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
        return notificationId;
    }
}

-(BOOL)markAllAsRead:(long long)time withFetcherId:(long long)fetcherId
{
    @synchronized(self.lock)
    {
        NSString *updateSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ? WHERE %@ <= ? AND EXISTS (SELECT %@ FROM %@ WHERE %@ = ? AND %@ = %@.%@);",
                               TABLE_NOTIFICATIONS,
                               COLUMN_UNREAD,
                               COLUMN_DATE,
                               COLUMN_NOTIFICATION_ID,
                               TABLE_FETCHERS_NOTIFICATIONS,
                               COLUMN_FETCHER_ID,
                               COLUMN_NOTIFICATION_ID,
                               TABLE_NOTIFICATIONS,
                               COLUMN_NOTIFICATION_ID];
        
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_database, [updateSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int(statement, 1, 0);
            sqlite3_bind_int64(statement, 2, time);
            sqlite3_bind_int64(statement, 3, fetcherId);
            
            int stepResult = sqlite3_step(statement);
            sqlite3_finalize(statement);
            return stepResult == SQLITE_DONE;
        } else {
            return NO;
        }
    }
}

-(BOOL)deleteNotifications:(nonnull NSArray<NSString*> *)notificaitonIds
{
    @synchronized(self.lock)
    {
        if ([notificaitonIds count] <= 0) {
            return YES;
        }

        NSString *inQuery = @"";
        for (int i = 0; i < [notificaitonIds count]; ++i) {
            if (i > 0) {
                inQuery = [inQuery stringByAppendingString:@","];
            }
            inQuery = [inQuery stringByAppendingString:@"?"];
        }
        
        NSString *deleteNotification = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN(%@);",
                                        TABLE_NOTIFICATIONS,
                                        COLUMN_NOTIFICATION_ID,
                                        inQuery];
        
        sqlite3_stmt *notificationStatement;
        if (sqlite3_prepare_v2(self->_database, [deleteNotification cStringUsingEncoding:NSUTF8StringEncoding], -1, &notificationStatement, NULL) != SQLITE_OK)
        {
            return NO;
        }
        
        NSString *deleteFetcher = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN(%@);",
                                   TABLE_FETCHERS_NOTIFICATIONS,
                                   COLUMN_NOTIFICATION_ID,
                                   inQuery];
        
        sqlite3_stmt *fetcherStatement;
        if (sqlite3_prepare_v2(self->_database, [deleteFetcher cStringUsingEncoding:NSUTF8StringEncoding], -1, &fetcherStatement, NULL) != SQLITE_OK)
        {
            sqlite3_finalize(notificationStatement);
            return NO;
        }
        
        int i = 1;
        for (NSString *notificaitonId in notificaitonIds) {
            sqlite3_bind_text(notificationStatement, i, [notificaitonId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            sqlite3_bind_text(fetcherStatement, i, [notificaitonId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            i += 1;
        }
        
        // Start a new transaction
        if (sqlite3_exec(self->_database, [@"BEGIN EXCLUSIVE TRANSACTION;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK) {
            return NO;
        }
        
        // Insert in notification table
        int stepResult = sqlite3_step(notificationStatement);
        if (stepResult != SQLITE_DONE) {
            // We ROOLBACK and just ignore any errors.
            // Either the transation already was rolled back, or there is nothing we can do anyway.
            sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while deleting notification, giving up."];
            return NO;
        }
        
        stepResult = sqlite3_step(fetcherStatement);
        if (stepResult != SQLITE_DONE) {
            // We ROOLBACK and just ignore any errors.
            // Either the transation already was rolled back, or there is nothing we can do anyway.
            sqlite3_exec(self->_database, [@"ROLLBACK;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
            [BALogger errorForDomain:@"InboxDatasource" message:@"Error while deleting notification, giving up."];
            return NO;
        }
        
        sqlite3_exec(self->_database, [@"COMMIT;" cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
        return YES;
    }
}

-(BOOL)cleanDatabase
{
    @synchronized(self.lock)
    {
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ <= ?", COLUMN_NOTIFICATION_ID, TABLE_NOTIFICATIONS, COLUMN_DATE];
        
        long long expireTime = [[NSDate date] timeIntervalSince1970] - 7776000; // 90 days in second
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK)
        {
            sqlite3_bind_int64(statement, 1, expireTime);
            
            NSMutableArray *idsToDeletes = [NSMutableArray new];
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                const char *idChar = (const char*) sqlite3_column_text(statement, 0);
                if (idChar != NULL) {
                    NSString *idToDelete = [NSString stringWithUTF8String:idChar];
                    if (![BANullHelper isStringEmpty: idToDelete]) {
                        [idsToDeletes addObject:idToDelete];
                    }
                }
            }
            
            sqlite3_finalize(statement);
            return [self deleteNotifications:idsToDeletes];
        } else {
            return NO;
        }
    }
}

#pragma mark -
#pragma mark Private methods

-(long long)notificationTime:(NSString *)notificationId
{
    NSString *selectSQL = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = ? LIMIT 1", COLUMN_DATE, TABLE_NOTIFICATIONS, COLUMN_NOTIFICATION_ID];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK)
    {
        sqlite3_bind_text(statement, 1, [notificationId cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        
        long long date = -1;
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            date = sqlite3_column_int64(statement, 0);
        }
        
        sqlite3_finalize(statement);
        return date;
    } else {
        return -1;
    }
}

-(BAInboxNotificationContent*)createNotificationFromStatement:(sqlite3_stmt *)statement
{
    BAInboxNotificationContent *content = [BAInboxNotificationContent new];
    
    const char *payloadChar = (const char*) sqlite3_column_text(statement, 10);
    if (payloadChar == NULL) {
        // TODO error handling
        return nil;
    }
    
    NSDictionary *json = [BAJson deserializeAsDictionary:[NSString stringWithUTF8String:payloadChar] error:nil];
    if (!json) {
        return nil;
    }
    
    content.payload = (NSDictionary *)json;
    content.isUnread = sqlite3_column_int(statement, 8) == 1;
    long long time = sqlite3_column_int64(statement, 9);
    content.date = [NSDate dateWithTimeIntervalSince1970:time];
    
    content.identifiers = [BAInboxNotificationContentIdentifiers new];
    content.identifiers.identifier = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(statement, 2)];
    content.identifiers.sendID = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(statement, 7)];
    
    const char *installIdChar = (const char*) sqlite3_column_text(statement, 3);
    if (installIdChar != NULL) {
        content.identifiers.installID = [NSString stringWithUTF8String:installIdChar];
    }
    
    const char *customIdChar = (const char*) sqlite3_column_text(statement, 4);
    if (customIdChar != NULL) {
        content.identifiers.customID = [NSString stringWithUTF8String:customIdChar];
    }
    
    content.identifiers.additionalData = [[[BAPushPayload alloc] initWithUserInfo:content.payload] openEventData];
    return content;
}

@end

