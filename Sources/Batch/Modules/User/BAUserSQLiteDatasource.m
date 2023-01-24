//
//  BAUserSQLiteDatasource.m
//  Batch
//
//  https://batch.com
//  Copyright (c) 2015 Batch SDK. All rights reserved.
//

#import <Batch/BADirectories.h>
#import <Batch/BALogger.h>
#import <Batch/BAParameter.h>
#import <Batch/BAUserSQLiteDatasource.h>
#import <sqlite3.h>

#define USER_DATABASE_NAME @"ba_user_profile.db"
#define TABLE_ATTRIBUTES @"attributes"
#define TABLE_TAGS @"tags"
#define COLUMN_DB_ID @"_db_id"

#define USER_DB_VERSION @1

#define LOGGER_DOMAIN @"UserProfileDatasource"

@interface BAUserSQLiteDatasource () {
    sqlite3 *_database;

    sqlite3_stmt *_attributeInsertStatement;

    sqlite3_stmt *_tagInsertStatement;

    sqlite3_stmt *_attributeDeleteStatement;

    sqlite3_stmt *_tagCollectionDeleteStatement;

    sqlite3_stmt *_tagDeleteStatement;

    BOOL _transactionOccuring;

    long long _currentChangeset;
}

@end

@implementation BAUserSQLiteDatasource

+ (BAUserSQLiteDatasource *)instance {
    static BAUserSQLiteDatasource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedInstance = [[BAUserSQLiteDatasource alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    return [self initWithDatabaseName:USER_DATABASE_NAME];
}

- (instancetype)initWithDatabaseName:(NSString *)dbName {
    self = [super init];
    if (!self) {
        return nil;
    }

    _database = NULL;

    _attributeInsertStatement = NULL;
    _tagInsertStatement = NULL;

    _attributeDeleteStatement = NULL;
    _tagDeleteStatement = NULL;

    _currentChangeset = 0;
    _transactionOccuring = NO;

    NSString *dbPath = [[BADirectories pathForBatchAppSupportDirectory] stringByAppendingPathComponent:dbName];

    /*** Migration things ***/

    // If the database already exists, check if we need to upgrade it
    // Future migration code goes here
    /*if( [[NSFileManager defaultManager] fileExistsAtPath:dbPath] )
    {
        NSNumber *oldDbVesion = [BAParameter objectForKey:kParametersUserProfileDBVersion fallback:@-1];
    }
    */

    /*** End of migration things ***/

    // TODO: Make In-App JIT use a shared queue and disable FULLMUTEX
    // See sc-54731
    // We might want to remove this for performance reasons, but this ensures
    // that concurrent access of sqlite3 will never crash, at the cost of threads possibly
    // being blocked for a little bit.
    if (sqlite3_open_v2([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &_database,
                        SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while opening sqlite database, not persisting user data."];
        return nil;
    }

    // Create the three tables with it.
    // See the header for a human readable schema.

    if (![self executeSimpleStatement:@"BEGIN;"]) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while initializing table creation transaction"];
        return nil;
    }

    BOOL attributesCreated = [self
        executeSimpleStatement:[NSString
                                   stringWithFormat:@"create table if not exists %@ (name text not null, type integer, "
                                                    @"value text, changeset integer, unique(name) on conflict replace, "
                                                    @"unique(name, type, value) on conflict abort);",
                                                    TABLE_ATTRIBUTES]];

    BOOL tagsCreated =
        [self executeSimpleStatement:
                  [NSString stringWithFormat:@"create table if not exists %@ (collection text not null, value text not "
                                             @"null, changeset integer, unique(collection, value) on conflict abort);",
                                             TABLE_TAGS]];

    if (!attributesCreated || !tagsCreated) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while creating tables"];
        return nil;
    }

    if (![self executeSimpleStatement:@"COMMIT;"]) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while commiting table creation transaction"];
        return nil;
    }

    // Database is created, save in the parameters the last known version
    [BAParameter setValue:USER_DB_VERSION forKey:kParametersUserProfileDBVersion saved:YES];

    NSString *statement = [NSString
        stringWithFormat:@"INSERT INTO %@ (name, type, value, changeset) VALUES (?, ?, ?, ?)", TABLE_ATTRIBUTES];

    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1,
                           &_attributeInsertStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the attribute sqlite insert statement, not persisting data."];
        return nil;
    }

    statement =
        [NSString stringWithFormat:@"INSERT INTO %@ (collection, value, changeset) VALUES (?, ?, ?)", TABLE_TAGS];

    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_tagInsertStatement,
                           NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the tag sqlite insert statement, not persisting data."];
        return nil;
    }

    statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE name=?", TABLE_ATTRIBUTES];

    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1,
                           &_attributeDeleteStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the sqlite delete statement, not persisting data."];
        return nil;
    }

    statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE collection=?", TABLE_TAGS];

    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1,
                           &_tagCollectionDeleteStatement, NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the sqlite delete statement, not persisting data."];
        return nil;
    }

    statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE collection=? AND value=?", TABLE_TAGS];

    if (sqlite3_prepare_v2(_database, [statement cStringUsingEncoding:NSUTF8StringEncoding], -1, &_tagDeleteStatement,
                           NULL) != SQLITE_OK) {
        [BALogger errorForDomain:LOGGER_DOMAIN
                         message:@"Error while preparing the sqlite delete statement, not persisting data."];
        return nil;
    }

    return self;
}

- (void)close {
    if (_transactionOccuring) {
        [self rollbackTransaction];
    }
}

- (void)clear {
    if (!_transactionOccuring) {
        [self executeSimpleStatement:[NSString stringWithFormat:@"DELETE FROM %@;", TABLE_ATTRIBUTES]];
        [self executeSimpleStatement:[NSString stringWithFormat:@"DELETE FROM %@;", TABLE_TAGS]];
    }
}

#pragma mark Transaction methods

- (BOOL)acquireTransactionLockWithChangeset:(long long)changeset {
    if (!_transactionOccuring && [self executeSimpleStatement:@"BEGIN TRANSACTION;"]) {
        _transactionOccuring = YES;
        _currentChangeset = changeset;
        return YES;
    }

    return NO;
}

- (BOOL)commitTransaction {
    if (_transactionOccuring && [self executeSimpleStatement:@"COMMIT TRANSACTION;"]) {
        _transactionOccuring = NO;
        _currentChangeset = 0;
        return YES;
    }
    return NO;
}

- (BOOL)rollbackTransaction {
    if (_transactionOccuring && [self executeSimpleStatement:@"ROLLBACK TRANSACTION;"]) {
        _transactionOccuring = NO;
        _currentChangeset = 0;
        return YES;
    }
    return NO;
}

#pragma mark Attributes methods

- (BOOL)setLongLongAttribute:(long long)attribute forKey:(NSString *)key {
    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_int64(statement, columnNumber, attribute);
        }
                        forKey:key
                      withType:BAUserAttributeTypeLongLong
                      isNative:NO];
}

- (BOOL)setDoubleAttribute:(double)attribute forKey:(NSString *)key {
    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_double(statement, columnNumber, attribute);
        }
                        forKey:key
                      withType:BAUserAttributeTypeDouble
                      isNative:NO];
}

- (BOOL)setBoolAttribute:(BOOL)attribute forKey:(NSString *)key {
    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_int(statement, columnNumber, attribute);
        }
                        forKey:key
                      withType:BAUserAttributeTypeBool
                      isNative:NO];
}

- (BOOL)setStringAttribute:(NSString *)attribute forKey:(NSString *)key {
    if (!attribute)
        return NO;

    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_text(statement, columnNumber, [attribute cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        }
                        forKey:key
                      withType:BAUserAttributeTypeString
                      isNative:NO];
}

- (BOOL)setDateAttribute:(NSDate *)attribute forKey:(NSString *)key {
    if (!attribute)
        return NO;

    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_double(statement, columnNumber, [attribute timeIntervalSince1970]);
        }
                        forKey:key
                      withType:BAUserAttributeTypeDate
                      isNative:NO];
}

- (BOOL)setURLAttribute:(nonnull NSURL *)attribute forKey:(nonnull NSString *)key {
    if (!attribute)
        return NO;

    return [self
        setAttributeUsingBlock:^(sqlite3_stmt *statement, int columnNumber) {
          sqlite3_bind_text(statement, columnNumber,
                            [attribute.absoluteString cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL);
        }
                        forKey:key
                      withType:BAUserAttributeTypeURL
                      isNative:NO];
}

- (BOOL)removeAttributeNamed:(NSString *)attribute {
    if (!_transactionOccuring)
        return NO;

    return [self deleteAttributeForKey:attribute isNative:NO];
}

#pragma mark Tags methods

- (BOOL)addTag:(NSString *)tag toCollection:(NSString *)collection {
    return [self writeTag:tag inCollection:collection];
}

- (BOOL)removeTag:(NSString *)tag fromCollection:(NSString *)collection {
    return [self _removeTag:tag fromCollection:collection];
}

#pragma mark Cleanup methods
- (BOOL)clearTags {
    if (!_transactionOccuring || !_currentChangeset)
        return NO;

    return [self executeSimpleStatement:[NSString stringWithFormat:@"DELETE FROM %@;", TABLE_TAGS]];
}

- (BOOL)clearTagsFromCollection:(NSString *)collection {
    if (!_transactionOccuring || !_tagCollectionDeleteStatement || !_currentChangeset || !collection)
        return NO;

    sqlite3_clear_bindings(_tagCollectionDeleteStatement);

    sqlite3_bind_text(_tagCollectionDeleteStatement, 1, [collection cStringUsingEncoding:NSUTF8StringEncoding], -1,
                      NULL);

    int result = sqlite3_step(_tagCollectionDeleteStatement);
    sqlite3_reset(_tagCollectionDeleteStatement);

    if (result != SQLITE_DONE) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while clearing tag collection %@.", collection];
        return NO;
    }

    return YES;
}

- (BOOL)clearAttributes {
    if (!_transactionOccuring || !_currentChangeset)
        return NO;

    return [self executeSimpleStatement:[NSString stringWithFormat:@"DELETE FROM %@;", TABLE_ATTRIBUTES]];
}

#pragma mark Reader methods

- (nonnull NSDictionary<NSString *, BAUserAttribute *> *)attributes;
{
    NSString *selectSQL = [NSString stringWithFormat:@"SELECT name, type, value FROM %@", TABLE_ATTRIBUTES];

    sqlite3_stmt *statement;

    NSMutableDictionary<NSString *, BAUserAttribute *> *attributes = [NSMutableDictionary new];

    if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement,
                           NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            const char *name = (const char *)sqlite3_column_text(statement, 0);
            const BAUserAttributeType type = (const int)sqlite3_column_int(statement, 1);

            id objcValue = nil;

            switch (type) {
                case BAUserAttributeTypeBool:
                    objcValue = [NSNumber numberWithBool:(sqlite3_column_int(statement, 2) ? YES : NO)];
                    break;
                case BAUserAttributeTypeDouble:
                    objcValue = [NSNumber numberWithDouble:sqlite3_column_double(statement, 2)];
                    break;
                case BAUserAttributeTypeLongLong:
                    objcValue = [NSNumber numberWithLongLong:sqlite3_column_int64(statement, 2)];
                    break;
                case BAUserAttributeTypeDate:
                    objcValue = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 2)];
                    break;
                case BAUserAttributeTypeString:
                    objcValue = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 2)
                                                   encoding:NSUTF8StringEncoding];
                    break;
                case BAUserAttributeTypeURL:
                    objcValue =
                        [NSURL URLWithString:[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 2)
                                                                encoding:NSUTF8StringEncoding]];
                    break;
                default:
                    continue;
            }

            if (!objcValue) {
                continue;
            }

            NSString *nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            if (nameString != nil) {
                [attributes setObject:[BAUserAttribute attributeWithValue:objcValue type:type] forKey:nameString];
            }
        }

        sqlite3_finalize(statement);
    }

    return attributes;
}

- (nonnull NSDictionary<NSString *, NSSet<NSString *> *> *)tagCollections {
    NSString *selectSQL =
        [NSString stringWithFormat:@"SELECT collection, value FROM %@ ORDER BY collection", TABLE_TAGS];

    sqlite3_stmt *statement;

    NSMutableDictionary<NSString *, NSSet<NSString *> *> *tagCollections = [NSMutableDictionary new];

    if (sqlite3_prepare_v2(self->_database, [selectSQL cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement,
                           NULL) == SQLITE_OK) {
        NSString *currentCollection = nil;
        NSMutableSet<NSString *> *currentTags = nil;

        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSString *collection = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0)
                                                      encoding:NSUTF8StringEncoding];
            NSString *tag = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 1)
                                               encoding:NSUTF8StringEncoding];

            // Only works if ordered by collection
            // Much better than looking up the dictionary to find where to insert every time
            if (![currentCollection isEqualToString:collection]) {
                if (currentCollection && currentTags) {
                    [tagCollections setObject:currentTags forKey:currentCollection];
                }

                currentCollection = collection;
                currentTags = [NSMutableSet new];
            }

            [currentTags addObject:tag];
        }

        // Add the current array since the sql loop ended
        if (currentCollection && currentTags) {
            [tagCollections setObject:currentTags forKey:currentCollection];
        }

        sqlite3_finalize(statement);
    }

    return tagCollections;
}

#pragma mark Debug

- (NSString *)printDebugDump {
    NSString *baseString = @"";

    if (_transactionOccuring) {
        baseString = @"---- WARNING Transaction is occurring, debug dump may be inaccurrate ----\n";
    }

    baseString = [baseString stringByAppendingString:@"---- Batch Custom User Data debug dump ----\n"];

    NSString *dump =
        [NSString stringWithFormat:@"%@Attributes: %@\n\nTags: %@", baseString,
                                   [BAUserAttribute serverJsonRepresentationForAttributes:[self attributes]],
                                   [self tagCollections]];

    [BALogger publicForDomain:@"BatchUserData" message:@"%@", dump];

    return dump;
}

#pragma mark Private methods

- (BOOL)setAttributeUsingBlock:(void (^)(sqlite3_stmt *statement, int columnNumber))bindBlock
                        forKey:(NSString *)key
                      withType:(BAUserAttributeType)type
                      isNative:(BOOL)native {
    if (!_transactionOccuring || !_attributeInsertStatement || !key || !bindBlock || !_currentChangeset)
        return NO;

    key = [(native ? @"n." : @"c.") stringByAppendingString:key];

    sqlite3_clear_bindings(_attributeInsertStatement);

    sqlite3_bind_text(_attributeInsertStatement, 1, [key cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // name
    sqlite3_bind_int(_attributeInsertStatement, 2, type);                                                       // type
    // The block will do the job of binding using the appropriate sqlite function
    bindBlock(_attributeInsertStatement, 3); // value
    sqlite3_bind_int64(_attributeInsertStatement, 4, _currentChangeset);

    int result = sqlite3_step(_attributeInsertStatement);
    sqlite3_reset(_attributeInsertStatement);

    if (result != SQLITE_DONE && result != SQLITE_CONSTRAINT) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while setting custom attribute to sqlite."];
        return NO;
    }

    return YES;
}

- (BOOL)deleteAttributeForKey:(NSString *)key isNative:(BOOL)native {
    if (!_transactionOccuring || !_attributeInsertStatement || !key || !_currentChangeset)
        return NO;

    key = [(native ? @"n." : @"c.") stringByAppendingString:key];

    sqlite3_clear_bindings(_attributeDeleteStatement);

    sqlite3_bind_text(_attributeDeleteStatement, 1, [key cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // name

    int result = sqlite3_step(_attributeDeleteStatement);
    sqlite3_reset(_attributeDeleteStatement);

    if (result != SQLITE_DONE) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while deleteing custom attribute from sqlite."];
        return NO;
    }

    return YES;
}

- (BOOL)writeTag:(NSString *)tag inCollection:(NSString *)collection {
    if (!_transactionOccuring || !_tagInsertStatement || !tag || !collection || !_currentChangeset)
        return NO;

    sqlite3_clear_bindings(_tagInsertStatement);

    sqlite3_bind_text(_tagInsertStatement, 1, [collection cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // tag
    sqlite3_bind_text(_tagInsertStatement, 2, [tag cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // value
    sqlite3_bind_int64(_tagInsertStatement, 3, _currentChangeset);

    int result = sqlite3_step(_tagInsertStatement);
    sqlite3_reset(_tagInsertStatement);

    if (result != SQLITE_DONE && result != SQLITE_CONSTRAINT) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while adding a custom tag to sqlite."];
        return NO;
    }

    return YES;
}

- (BOOL)_removeTag:(NSString *)tag fromCollection:(NSString *)collection {
    if (!_transactionOccuring || !_tagInsertStatement || !tag || !collection || !_currentChangeset)
        return NO;

    sqlite3_clear_bindings(_tagDeleteStatement);

    sqlite3_bind_text(_tagDeleteStatement, 1, [collection cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // tag
    sqlite3_bind_text(_tagDeleteStatement, 2, [tag cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL); // value

    int result = sqlite3_step(_tagDeleteStatement);
    sqlite3_reset(_tagDeleteStatement);

    if (result != SQLITE_DONE) {
        [BALogger errorForDomain:LOGGER_DOMAIN message:@"Error while adding a custom tag to sqlite."];
        return NO;
    }

    return YES;
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

@end
