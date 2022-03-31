#import <Batch/BADBGLCListViewController.h>

#import <Batch/BALocalCampaign.h>
#import <Batch/BALocalCampaignsCenter.h>

#import <Batch/BADBGLCDetailsViewController.h>

#define DEFAULT_CELL_NAME @"cell"

@implementation BADBGLCListViewController {
    NSArray<BALocalCampaign *> *_campaigns;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Inspect";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _campaigns = BALocalCampaignsCenter.instance.campaignManager.campaignList;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_campaigns count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];

    NSString *token = _campaigns[indexPath.row].publicToken;
    cell.textLabel.text = token != nil ? token : @"unknown";
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];

    BADBGLCDetailsViewController *vc = [BADBGLCDetailsViewController new];
    [vc setCampaign:_campaigns[indexPath.row]];
    [self.navigationController pushViewController:vc animated:true];
}

@end
