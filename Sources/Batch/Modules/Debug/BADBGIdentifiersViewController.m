#import <Batch/BADBGIdentifiersViewController.h>

#import <Batch/BatchUser.h>
#import <Batch/BatchPush.h>
#import <Batch/BACoreCenter.h>
#import <Batch/BAPropertiesCenter.h>
#import <Batch/BABundleInfo.h>

#import <Batch/BADBGNameValueListItem.h>

#define DEFAULT_CELL_NAME @"cell"

@interface BADBGIdentifiersViewController ()

@end

@implementation BADBGIdentifiersViewController
{
    NSArray<BADBGNameValueListItem*>* _identifiers;
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self fetchIdentifiers];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Identifiers";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    
    [self.tableView registerClass:[BADBGNameValueCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_identifiers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];
    
    BADBGNameValueListItem *item = _identifiers[indexPath.row];
    
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.value != nil ? item.value : @"unavailable";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)fetchIdentifiers
{
    NSString *pushToken = [BatchPush lastKnownPushToken];
    
    NSMutableArray *temporaryIdentifiers = [NSMutableArray arrayWithCapacity:5];
    
    [temporaryIdentifiers addObject:[BADBGNameValueListItem itemWithName:@"Batch SDK" value:[@"Version " stringByAppendingString:BACoreCenter.sdkVersion]]];
    [temporaryIdentifiers addObject:[BADBGNameValueListItem itemWithName:@"Installation ID" value:[BatchUser installationID]]];
    [temporaryIdentifiers addObject:[BADBGNameValueListItem itemWithName:@"Push Token" value:(pushToken != nil ? pushToken : @"none")]];
    [temporaryIdentifiers addObject:[BADBGNameValueListItem itemWithName:@"APNS Environment" value:([BABundleInfo usesAPNSandbox] ? @"Sandbox" : @"Production")]];
    
    _identifiers = temporaryIdentifiers;
    
    /* Todo: add application info, such as bundle id and version*/
}

- (void)share:(id)sender
{
    NSMutableString *infos = [NSMutableString new];
    
    [infos appendString:@"Batch Debug: Identifiers\n\n"];
    
    for (BADBGNameValueListItem *item in _identifiers)
    {
        [infos appendFormat:@"%@: %@\n\n", item.name, item.value];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[infos]
                                                                             applicationActivities:nil];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        [activityVC.popoverPresentationController setBarButtonItem:sender];
    }
    
    [self.navigationController presentViewController:activityVC
                                            animated:YES
                                          completion:nil];
}

@end
