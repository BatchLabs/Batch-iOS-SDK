#import <Batch/BADBGCustomDataViewController.h>
#import <Batch/BADBGCustomDataModels.h>

#import <Batch/BatchCore.h>
#import <Batch/BAParameter.h>
#import <Batch/BAUserDataManager.h>
#import <Batch/BAUserSQLiteDatasource.h>

#define DEFAULT_CELL_NAME @"cell"

@interface BADBGUserIdentifierCell: UITableViewCell
@end

@implementation BADBGUserIdentifierCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

@end

@implementation BADBGCustomDataViewController
{
    NSDateFormatter *_dateFormatter;
    
    NSArray<BADBGCustomDataAttribute*>* _builtins;
    NSArray<BADBGCustomDataAttribute*>* _attributes;
    NSArray<BADBGCustomDataTagCollection*>* _tagCollections;
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        
        [self populate];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Custom user data";
    
    self.tableView.allowsSelection = false;
    [self.tableView registerClass:[BADBGUserIdentifierCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
}

- (void)populate
{
    dispatch_async([BAUserDataManager sharedQueue], ^{
        NSMutableArray *builtins = [NSMutableArray arrayWithCapacity:3];
        [builtins addObject:[BADBGCustomDataAttribute attributeWithName:@"Custom User ID" value:[BAParameter objectForKey:kParametersCustomUserIDKey fallback:@"<None set>"]]];
        
        NSString *customLanguage = [BAParameter objectForKey:kParametersAppLanguageKey fallback:nil];
        if (customLanguage) {
            [builtins addObject:[BADBGCustomDataAttribute attributeWithName:@"Language override" value:customLanguage]];
        }
        
        NSString *customRegion = [BAParameter objectForKey:kParametersAppRegionKey fallback:nil];
        if (customRegion) {
            [builtins addObject:[BADBGCustomDataAttribute attributeWithName:@"Region override" value:customRegion]];
        }
        
        self->_builtins = builtins;
        
        id<BAUserDatasourceProtocol> datasource = [BAUserSQLiteDatasource instance];
        
        NSMutableArray *attributes = [NSMutableArray new];
        
        NSDictionary<NSString*, BAUserAttribute*>* datasourceAttributes = datasource.attributes;
        
        for (NSString *key in datasourceAttributes.allKeys)
        {
            BAUserAttribute* attribute = datasourceAttributes[key];
            // Convert the dates!
            id value = attribute.value;
            
            if ([value isKindOfClass:[NSDate class]])
            {
                value = [self->_dateFormatter stringFromDate:value];
            }
            
            if (![value isKindOfClass:[NSString class]])
            {
                value = [value description];
            }
            
            [attributes addObject:[BADBGCustomDataAttribute attributeWithName:key value:value]];
        }
        
        self->_attributes = attributes;
        
        NSMutableArray *tagCollections = [NSMutableArray new];
        
        [datasource.tagCollections enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                                           usingBlock:^(id key, id object, BOOL *stop) {
                                                               BADBGCustomDataTagCollection *tc = [BADBGCustomDataTagCollection new];
                                                               tc.collectionName = [@"t." stringByAppendingString:key];
                                                               
                                                               // A refactoring once turned this untyped "object" into a crasher
                                                               // We now ensure we're gonna put a valid value for tc.tags
                                                               if ([object isKindOfClass:[NSSet class]]) {
                                                                   NSArray *tagsArray = [(NSSet*)object allObjects];
                                                                   BOOL isArrayValid = true;
                                                                   for (NSObject *val in tagsArray) {
                                                                       if (![val isKindOfClass:[NSString class]]) {
                                                                           isArrayValid = false;
                                                                           break;
                                                                       }
                                                                   }
                                                                   
                                                                   if (isArrayValid) {
                                                                       tc.tags = tagsArray;
                                                                   } else {
                                                                       tc.tags = @[@"Internal error (2)"];
                                                                   }
                                                               } else {
                                                                   tc.tags = @[@"Internal error (1)"];
                                                               }
                                                               
                                                               [tagCollections addObject:tc];
                                                           }];
        
        self->_tagCollections = tagCollections;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3 + [_tagCollections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [_builtins count];
        case 1:
            return [_attributes count];
        case 2:
            return 0;
        default:
            return [[self tagCollectionForSection:section].tags count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"Basic";
        case 1:
            return @"Custom Attributes";
        case 2:
            return @"Tag Collections";
        default:
            return [self tagCollectionForSection:section].collectionName;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];
    
    NSString *mainText = nil;
    NSString *detailText = nil;
    
    switch (indexPath.section) {
        case 0:
        {
            BADBGCustomDataAttribute *attr = _builtins[indexPath.row];
            mainText = attr.name;
            detailText = attr.value;
            break;
        }
        case 1:
        {
            BADBGCustomDataAttribute *attr = _attributes[indexPath.row];
            mainText = attr.name;
            detailText = attr.value;
            break;
        }
        default:
            mainText = [self tagCollectionForSection:indexPath.section].tags[indexPath.row];
            break;
    }
    
    cell.textLabel.text = mainText;
    cell.detailTextLabel.text = detailText;
    
    return cell;
}

- (BADBGCustomDataTagCollection*)tagCollectionForSection:(NSInteger)section
{
    @try {
        return _tagCollections[section-3];
    } @catch (NSException *exception) {
        return nil;
    }
}

@end
