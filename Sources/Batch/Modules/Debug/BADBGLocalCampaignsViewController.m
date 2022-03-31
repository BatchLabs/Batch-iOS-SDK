#import <Batch/BADBGLocalCampaignsViewController.h>

#import <Batch/BADBGLCListViewController.h>
#import <Batch/BALocalCampaignsCenter.h>

#define DEFAULT_CELL_NAME @"cell"

@interface BADBGLocalCampaignsMenuCell : UITableViewCell
@end

@implementation BADBGLocalCampaignsMenuCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

@end

@implementation BADBGLocalCampaignsViewController

- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"In-App Campaigns";
    [self.tableView registerClass:[BADBGLocalCampaignsMenuCell class] forCellReuseIdentifier:DEFAULT_CELL_NAME];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
        /*case 1:
                return 1;*/
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"Note: If refreshing the campaigns succeeds, the campaign count might not be refreshed until this view "
               @"is closed and reopened.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DEFAULT_CELL_NAME forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.detailTextLabel.text = nil;

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text =
                        [NSString stringWithFormat:@"%lu campaign(s)", (unsigned long)BALocalCampaignsCenter.instance
                                                                           .campaignManager.campaignList.count];
                    cell.detailTextLabel.text = @"Inspect";
                    break;
                case 1:
                    cell.textLabel.text = @"Refresh campaigns from server";
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    break;
            }
            break;
        case 1:
            cell.textLabel.text = @"View history";
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self.navigationController pushViewController:[BADBGLCListViewController new] animated:YES];
                    break;
                case 1:
                    [BALocalCampaignsCenter.instance refreshCampaignsFromServer];
                    break;
            }
            break;
    }
}

@end
