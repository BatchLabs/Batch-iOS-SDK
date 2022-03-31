#import <Batch/BADBGLCDetailsViewController.h>

#import <Batch/BADBGNameValueListItem.h>
#import <Batch/BAEventTrigger.h>
#import <Batch/BANextSessionTrigger.h>

#define DEFAULT_CELL_NAME @"cell"

@implementation BADBGLCDetailsViewController
{
    NSArray<BADBGNameValueListItem*>* _items;
    BALocalCampaign *_campaign;
    NSDateFormatter *_dateFormatter;
}

- (instancetype)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Campaign details";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    
    [self.tableView registerClass:[BADBGNameValueCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
}

- (void)setCampaign:(BALocalCampaign *)campaign
{
    _campaign = campaign;
    
    NSMutableArray *items = [NSMutableArray new];
    
    NSString *token = campaign.publicToken;
    
    [items addObject:[BADBGNameValueListItem itemWithName:@"Token" value:token != nil ? token : @"unknown"]];
    [items addObject:[BADBGNameValueListItem itemWithName:@"Start Date" value:[self nullableDateString:campaign.startDate]]];
    [items addObject:[BADBGNameValueListItem itemWithName:@"End Date" value:[self nullableDateString:campaign.endDate]]];
    [items addObject:[BADBGNameValueListItem itemWithName:@"Capping" value:(campaign.capping > 0 ? [@(campaign.capping) stringValue] : @"None")]];
    [items addObject:[BADBGNameValueListItem itemWithName:@"Grace period" value:(campaign.minimumDisplayInterval > 60 ? [@(campaign.minimumDisplayInterval) stringValue] : @"None")]]; // Hide any grace period that's not more than one minute
    
    for (id<BALocalCampaignTriggerProtocol> trigger in campaign.triggers)
    {
        NSString *triggerValue = nil;
        if ([trigger isKindOfClass:[BAEventTrigger class]]) {
            BAEventTrigger *eventTrigger = (BAEventTrigger*)trigger;
            
            if (eventTrigger.label) {
                triggerValue = [NSString stringWithFormat:@"Event: \"%@\"\nLabel: \"%@\"", eventTrigger.name, eventTrigger.label];
            } else {
                triggerValue = [NSString stringWithFormat:@"Event: \"%@\"", eventTrigger.name];
            }
        } else if ([trigger isKindOfClass:[BANextSessionTrigger class]]) {
            triggerValue = @"New session";
        } else {
            triggerValue = @"Other";
        }
        
        if (triggerValue != nil) {
            [items addObject:[BADBGNameValueListItem itemWithName:@"Trigger" value:triggerValue]];
        }
    }
    
    _items = items;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];
    
    BADBGNameValueListItem *item = _items[indexPath.row];
    
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.value;
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

- (NSString*)nullableDateString:(BATZAwareDate*)date
{
    if (date == nil) {
        return @"None";
    }
    
    return [_dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:date.offsettedTimeIntervalSince1970]];
}

- (void)share:(id)sender
{
    NSMutableString *infos = [NSMutableString new];
    
    [infos appendString:@"Batch Debug: Identifiers\n\n"];
    
    for (BADBGNameValueListItem *item in _items)
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
