#import <Batch/BADBGDebugViewController.h>

#import <Batch/BADBGIdentifiersViewController.h>
#import <Batch/BADBGLocalCampaignsViewController.h>
#import <Batch/BADBGCustomDataViewController.h>

#define DEFAULT_CELL_NAME @"cell"

typedef NS_ENUM(NSUInteger, BADBGMenuAction) {
    BADBGMenuActionIdentifiers,
    BADBGMenuActionLocalCampaigns,
    BADBGMenuActionCustomData,
};

@interface BADBGMenuItem : NSObject

@property NSString *name;
@property BADBGMenuAction action;

+ (instancetype)itemWithName:(NSString *)name action:(BADBGMenuAction)action;

@end

@implementation BADBGMenuItem

+ (instancetype)itemWithName:(NSString *)name action:(BADBGMenuAction)action
{
    BADBGMenuItem *item = [[BADBGMenuItem alloc] init];
    item.name = name;
    item.action = action;
    return item;
}

@end

@interface BADBGMenuSection : NSObject

@property NSString *name;
@property NSArray<BADBGMenuItem*>* items;

+ (instancetype)sectionWithName:(NSString *)name items:(NSArray<BADBGMenuItem*>*)items;

@end

@implementation BADBGMenuSection

+ (instancetype)sectionWithName:(NSString *)name items:(NSArray<BADBGMenuItem*>*)items
{
    BADBGMenuSection *section = [[BADBGMenuSection alloc] init];
    section.name = name;
    section.items = items;
    return section;
}

@end

@implementation BADBGDebugViewController
{
    NSArray<BADBGMenuSection*>* _sections;
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _sections = @[
                      [BADBGMenuSection sectionWithName:nil items:@[
                                                                    [BADBGMenuItem itemWithName:@"Identifiers" action:BADBGMenuActionIdentifiers],
                                                                    [BADBGMenuItem itemWithName:@"Custom user data" action:BADBGMenuActionCustomData],
                                                                    ]],
                      [BADBGMenuSection sectionWithName:nil items:@[
                                                                    [BADBGMenuItem itemWithName:@"In-App Campaigns" action:BADBGMenuActionLocalCampaigns]
                                                                    ]],
                      ];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Batch Debug";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
    self.clearsSelectionOnViewWillAppear = NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_sections[section].items count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _sections[section].name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];
    cell.textLabel.text = _sections[indexPath.section].items[indexPath.row].name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performAction:_sections[indexPath.section].items[indexPath.row].action];
}

- (void)performAction:(BADBGMenuAction)action
{
    switch (action) {
        case BADBGMenuActionIdentifiers:
            [self.navigationController pushViewController:[BADBGIdentifiersViewController new] animated:YES];
            break;
        case BADBGMenuActionLocalCampaigns:
            [self.navigationController pushViewController:[BADBGLocalCampaignsViewController new] animated:YES];
            break;
        case BADBGMenuActionCustomData:
            [self.navigationController pushViewController:[BADBGCustomDataViewController new] animated:YES];
            break;
    }
}

- (void)done
{
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
