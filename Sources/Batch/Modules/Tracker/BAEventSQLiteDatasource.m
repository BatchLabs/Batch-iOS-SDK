//
//  BAEventSQLiteDatasource.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2014 Batch SDK. All rights reserved.
//

#import <Batch/BAEventSQLiteDatasource.h>
#import <sqlite3.h>
#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>
#import <Batch/BADirectories.h>

#define TABLE_EVENTS        @"events"
#define COLUMN_DB_ID        @"_db_id"
#define COLUMN_ID           @"id"
#define COLUMN_STATE        @"state"
#define COLUMN_NAME         @"name"

#define DB_VERSION          @3


@implementation BAEventSQLiteDatasource

- (instancetype)initWithFilename:(NSString *)name forDBHelper:(id<BAEventDBHelperProtocol>)eventDBHelper
{
    self = [super init];
    
    if( [BANullHelper isNull:self] )
    {
        return nil;
    }
    
    self.lock = [NSObject new];
    
    if (!eventDBHelper) {
        return nil;
    }
    
    self.eventDBHelper = eventDBHelper;
    
    _database = NULL;
    _insertStatement = NULL;

    /*** Migration things ***/
    
    NSString *dbPath = [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:name];
    
    // If the database already exists, check if we need to upgrade it
    if( [[NSFileManager defaultManager] fileExistsAtPath:dbPath] )
    {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersTrackerDBVersion kindOfClass:[NSNumber class] fallback:@-1];
        if( [oldDbVesion isEqualToNumber:@1] )
        {
            @try
            {
                [self executeUpgradeQueries:@[[NSString stringWithFormat: @"alter table %@ add column sdate text",TABLE_EVENTS], [NSString stringWithFormat:@"alter table %@ add column session text",TABLE_EVENTS]] onDatabase:dbPath];
                
            }
            @catch (NSException *exception)
            {
                // The update strategy for the time being is to wipe the SQLite file and recreate it. Safest way.
                if( ![[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil] )
                {
                    [BALogger errorForDomain:@"Event" message:@"Error while upgrading sqlite database, not persisting events."];
                    return nil;
                }
            }
        }
        else if( [oldDbVesion isEqualToNumber:@2] )
        {
            @try
            {
                [self executeUpgradeQueries:@[[NSString stringWithFormat:@"alter table %@ add column session text",TABLE_EVENTS]] onDatabase:dbPath];
                
            }
            @catch (NSException *exception)
            {
                // The update strategy for the time being is to wipe the SQLite file and recreate it. Safest way.
                if( ![[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil] )
                {
                    [BALogger errorForDomain:@"Event" message:@"Error while upgrading sqlite database, not persisting events."];
                    return nil;
                }
            }
        }
        else if (![oldDbVesion isEqualToNumber:DB_VERSION])
        {
            // Wipe the SQLite file and recreate it if no old version (or too new) found. Safest way.
            if( ![[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil] )
            {
                [BALogger errorForDomain:@"Event" message:@"Error while upgrading sqlite database, not persisting events."];
                return nil;
            }
        }
    }
    
    /*** End of migration things ***/

    if( sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"Event" message:@"Error while opening sqlite database, not persisting events."];
        return nil;
    }
    
    NSMutableString *createString = [[NSMutableString alloc] init];
    NSArray *parameters = [[self.eventDBHelper class] createStatementDescriptions];
    for (int i = 0; i<[parameters count]; i++)
    {
        if (i>0)
        {
            [createString appendString:@", "];
        }
        [createString appendString:[parameters objectAtIndex:i]];
    }
    
    NSString *createStatement = [NSString stringWithFormat:@"create table if not exists %@ (%@ integer primary key autoincrement, %@);", TABLE_EVENTS, COLUMN_DB_ID, createString];
    
    if( sqlite3_exec(_database, [createStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"Event" message:@"Error while creating the sqlite table, not persisting events."];
        return nil;
    }
    
    // Database is created, save in the parameters the last known version
    [BAParameter setValue:DB_VERSION forKey:kParametersTrackerDBVersion saved:YES];
    
    NSMutableString *insertString = [[NSMutableString alloc] init];
    NSMutableString *valuesString = [[NSMutableString alloc] init];
    NSArray *parameterNames = [[self.eventDBHelper class] insertStatementDescriptions];
    for (int i = 0; i<[parameterNames count]; i++)
    {
        if (i>0)
        {
            [insertString appendString:@", "];
            [valuesString appendString:@", "];
        }
        [insertString appendString:[parameterNames objectAtIndex:i]];
        [valuesString appendString:@"?"];
    }
    
    NSString *insertStatement = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", TABLE_EVENTS, insertString, valuesString];
    
    if( sqlite3_prepare_v2(_database, [insertStatement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_insertStatement, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"Event" message:@"Error while preparing the sqlite insert statement, not persisting events."];
        return nil;
    }
    
    NSString *collapseDeleteStatement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", TABLE_EVENTS, COLUMN_NAME];
    
    if( sqlite3_prepare_v2(_database, [collapseDeleteStatement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_collapseDeleteStatement, NULL) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"Event" message:@"Error while preparing the sqlite collapsed event delete statement, ignoring."];
        _collapseDeleteStatement = NULL;
        return nil;
    }
    
    return self;
}

- (void)executeUpgradeQueries:(NSArray*)statements onDatabase:(NSString*)dbPath
{
    if( sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database) != SQLITE_OK )
    {
        [BALogger errorForDomain:@"Event" message:@"Error while opening sqlite database, not persisting events."];
        [[NSException exceptionWithName:@"Event" reason:@"Error while opening sqlite database, not persisting events." userInfo:nil] raise];
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
                [[NSException exceptionWithName:@"Event" reason:@"Error while performing ALTER." userInfo:nil] raise];
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
#pragma mark BAEventDatasourceProtocol methods

- (void)close
{
    @synchronized(self.lock)
    {
        if( self->_database )
        {
            sqlite3_finalize(self->_insertStatement);
            self->_insertStatement = NULL;
            
            sqlite3_close(self->_database);
            self->_database = NULL;
        }
    }
}

- (void)clear
{
    @synchronized(self.lock)
    {
        NSString *clearStatement = [NSString stringWithFormat:@"DELETE FROM %@;", TABLE_EVENTS];
        
        if( sqlite3_exec(self->_database, [clearStatement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
        {
            [BALogger errorForDomain:@"Event" message:@"Error clearing the table"];
        }
    }
}

- (BOOL)addEvent:(BAEvent *)event
{
    @synchronized(self.lock)
    {
        if( !self->_insertStatement || !event )
        {
            return NO;
        }
        
        
        if ([event isKindOfClass:[BACollapsableEvent class]] && self->_collapseDeleteStatement != NULL)
        {
            sqlite3_clear_bindings(self->_collapseDeleteStatement);
            
            sqlite3_bind_text(self->_collapseDeleteStatement, 1, [event.name cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
            
            int stepResult = sqlite3_step(self->_collapseDeleteStatement);
            sqlite3_reset(self->_collapseDeleteStatement);
            
            if( stepResult != SQLITE_DONE )
            {
                [BALogger errorForDomain:@"Event" message:@"Error removing past occurences of a collapsable event, ignoring."];
                return NO;
            }
        }
        
        sqlite3_clear_bindings(self->_insertStatement);
        
        sqlite3_stmt *stmt = self->_insertStatement;
        if (![self.eventDBHelper bindEvent:event withStatement:&stmt])
        {
            return NO;
        }
        
        int stepResult = sqlite3_step(self->_insertStatement);
        sqlite3_reset(self->_insertStatement);
        
        if( stepResult != SQLITE_DONE )
        {
            [BALogger errorForDomain:@"Event" message:@"Error while adding event to sqlite, giving up."];
            return NO;
        }
    }
    return YES;
}

- (NSArray *)eventsToSend:(NSUInteger)count
{
    @synchronized(self.lock)
    {
        NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:count];
        
        NSMutableString *insertString = [[NSMutableString alloc] init];
        NSArray *parameterNames = [[self.eventDBHelper class] insertStatementDescriptions];
        for (int i = 0; i<[parameterNames count]; i++)
        {
            if (i>0)
            {
                [insertString appendString:@", "];
            }
            [insertString appendString:[parameterNames objectAtIndex:i]];
        }
        
        // LIKE should be read as LIKE "\_%"
        NSString *selectSQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ IN (%d,%d) ORDER BY CASE WHEN %@ LIKE \"\\_%%\" ESCAPE '\\' THEN 1 ELSE 0 END DESC, %@ DESC", COLUMN_DB_ID, insertString, TABLE_EVENTS, COLUMN_STATE, BAEventStateNew, BAEventStateOld, COLUMN_NAME, COLUMN_DB_ID];
        if( count > 0 )
        {
            selectSQL = [NSString stringWithFormat:@"%@ LIMIT %lu", selectSQL, (unsigned long)count];
        }
        
        sqlite3_stmt *statement;
        
        if( sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK )
        {
            while( sqlite3_step(statement) == SQLITE_ROW )
            {
                const char *parametersChars = (const char*) sqlite3_column_text(statement, 4);
                NSString *parameters = nil;
                if( parametersChars != NULL )
                {
                    parameters = [NSString stringWithUTF8String:(const char *) parametersChars];
                }
                
                const char *secureDateChars = (const char*) sqlite3_column_text(statement, 7);
                NSString *secureDate = nil;
                if( secureDateChars != NULL )
                {
                    secureDate = [NSString stringWithUTF8String:(const char *) secureDateChars];
                }
                
                const char *sessionChars = (const char*) sqlite3_column_text(statement, 8);
                NSString *session = nil;
                if( sessionChars != NULL )
                {
                    session = [NSString stringWithUTF8String:(const char *) sessionChars];
                }
                
                [events addObject:[BAEvent eventWithIdentifier:[NSString stringWithUTF8String:(const char*) sqlite3_column_text(statement, 1)]
                                                          name:[NSString stringWithUTF8String:(const char*) sqlite3_column_text(statement, 2)]
                                                          date:[NSString stringWithUTF8String:(const char*) sqlite3_column_text(statement, 3)]
                                                    secureDate:secureDate
                                                    parameters:parameters
                                                         state:sqlite3_column_int(statement, 5)
                                                       session:session
                                                       andTick:sqlite3_column_int64(statement, 6)]];
            }
            
            sqlite3_finalize(statement);
        }
        else
        {
            [BALogger errorForDomain:@"Event" message:@"Error while preparing select query."];
        }
        
        return events;
    }
}

- (void)updateEventsStateFrom:(BAEventState)fromState to:(BAEventState)toState
{
    @synchronized(self.lock)
    {
        NSMutableString *updateSQL = [[NSMutableString alloc] init];
        [updateSQL appendFormat:@"UPDATE %@ SET %@='%ld'", TABLE_EVENTS, COLUMN_STATE, (long)toState];
        if( fromState != BAEventStateAll )
        {
            [updateSQL appendFormat:@"WHERE %@='%ld'", COLUMN_STATE, (long)fromState];
        }
        
        sqlite3_stmt *statement;
        if( sqlite3_prepare_v2(self->_database, [updateSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK )
        {
            if( sqlite3_step(statement) != SQLITE_DONE )
            {
                [BALogger errorForDomain:@"Event" message:@"Error while updating event status"];
            }
            
            sqlite3_finalize(statement);
        }
        else
        {
            [BALogger errorForDomain:@"Event" message:@"Error while updating event status"];
        }
    }
}

- (void)updateEventsStateTo:(BAEventState)state forEventsIdentifier:(NSArray*)events
{
    @synchronized(self.lock)
    {
        if( !events || [events count] == 0 )
        {
            return;
        }
        
        NSMutableString *updateSQL = [[NSMutableString alloc] init];
        [updateSQL appendFormat:@"UPDATE %@ SET %@='%ld' WHERE %@ IN (", TABLE_EVENTS, COLUMN_STATE, (long)state, COLUMN_ID];
        for( int i = 0; i < [events count]; i++ )
        {
            if( i > 0 )
            {
                [updateSQL appendString:@","];
            }
            [updateSQL appendString:@"?"];
        }
        [updateSQL appendString:@")"];
        
        sqlite3_stmt *statement;
        if( sqlite3_prepare_v2(self->_database, [updateSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK )
        {
            for( int i = 0; i < [events count]; i++ )
            {
                NSString *eventID = [events objectAtIndex:i];
                if( [eventID isKindOfClass:[NSString class]] )
                {
                    sqlite3_bind_text(statement, i + 1, [eventID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
                }
                else
                {
                    [BALogger errorForDomain:@"Event" message:@"%s encountered a non string ID in the provided list. Skiping: %@.",__PRETTY_FUNCTION__, eventID];
                }
            }
            
            if( sqlite3_step(statement) != SQLITE_DONE )
            {
                [BALogger errorForDomain:@"Event" message:@"Error while updating event status"];
            }
            
            sqlite3_finalize(statement);
        }
        else
        {
            [BALogger errorForDomain:@"Event" message:@"Error while updating event status"];
        }
    }
}

- (void)deleteEvents:(NSArray *)eventIdentifiers
{
    @synchronized(self.lock)
    {
        if( !eventIdentifiers || [eventIdentifiers count] == 0 )
        {
            return;
        }
        
        NSMutableString *deleteSQL = [[NSMutableString alloc] init];
        [deleteSQL appendFormat:@"DELETE FROM %@ WHERE %@ IN (", TABLE_EVENTS, COLUMN_ID];
        
        for( int i = 0; i < [eventIdentifiers count]; i++ )
        {
            if( i > 0 )
            {
                [deleteSQL appendString:@","];
            }
            
            [deleteSQL appendString:@"?"];
        }
        
        [deleteSQL appendString:@");"];
        
        sqlite3_stmt *statement;
        
        if( sqlite3_prepare_v2(self->_database, [deleteSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL) == SQLITE_OK )
        {
            for( int i = 0; i < [eventIdentifiers count]; i++ )
            {
                NSString *eventID = [eventIdentifiers objectAtIndex:i];
                if( [eventID isKindOfClass:[NSString class]] )
                {
                    sqlite3_bind_text(statement, i + 1, [eventID cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
                }
                else
                {
                    [BALogger errorForDomain:@"Event" message:@"%s encountered a non string ID in the provided list. Aborting.",__PRETTY_FUNCTION__];
                }
            }
            
            sqlite3_step(statement);
            sqlite3_finalize(statement);
        }
        else
        {
            [BALogger errorForDomain:@"Event" message:@"Error while preparing delete query."];
        }
    }
}

- (BOOL)hasEventsToSend
{
    return [[self eventsToSend:1] count] > 0;
}

- (void)deleteEventsOlderThanTheLast:(NSUInteger)eventNumber
{
    @synchronized(self.lock)
    {
        if (eventNumber <= 0)
        {
            [BALogger errorForDomain:@"Event" message:@"Cannot remove events using a negative or null offset."];
            return;
        }
        
        NSString *statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ NOT IN (SELECT %@ FROM %@ ORDER BY %@ DESC LIMIT %lu)",
                               TABLE_EVENTS, COLUMN_DB_ID, COLUMN_DB_ID, TABLE_EVENTS, COLUMN_DB_ID, (unsigned long)eventNumber];
        
        if( sqlite3_exec(self->_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL) != SQLITE_OK )
        {
            [BALogger errorForDomain:@"Event" message:@"Error while deleting old events."];
        }
    }
}

@end
