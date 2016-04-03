#import "AddReviewerViewController.h"
#import "ReviewCell.h"
#import "ProjectListCell.h"
#import "ProjectListTaCell.h"
#import "ODRefreshControl.h"
#import "Coding_NetAPIManager.h"

//新系列 cell
#import "ProjectAboutMeListCell.h"
#import "ProjectAboutOthersListCell.h"
#import "ProjectPublicListCell.h"
#import "SVPullToRefresh.h"
#import "Reviewer.h"
#import "ProjectMember.h"

@interface AddReviewerViewController ()<UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) UISearchBar *mySearchBar;
@property (strong, nonatomic) NSString *addReviewerPath;
@property (strong, nonatomic) NSString *delReviewerPath;
@property (readwrite, nonatomic, strong) NSMutableArray *users;
@property (readwrite, nonatomic, strong) NSMutableArray *allUsers;
@property (readwrite, nonatomic, strong) NSMutableArray *projectUsers;
@property (strong, nonatomic) ReviewersInfo *curReviewersInfo;
@end

@implementation AddReviewerViewController

static NSString *const kTitleKey = @"kTitleKey";
static NSString *const kValueKey = @"kValueKey";

-(void)viewDidLoad {
    self.title = @"评审人";
    self.users = [[NSMutableArray alloc] init];
     self.allUsers = [[NSMutableArray alloc] init];
    [self.myTableView registerNib:[UINib nibWithNibName:kCellIdentifier_ReviewCell bundle:nil] forCellReuseIdentifier:kCellIdentifier_ReviewCell];
    self.myTableView.separatorStyle = NO;
    
    
    /*
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(selectRightAction:)];
    self.navigationItem.rightBarButtonItem = saveButton;*/
    
    _mySearchBar = ({
     UISearchBar *searchBar = [[UISearchBar alloc] init];
     searchBar.delegate = self;
     [searchBar sizeToFit];
     [searchBar setPlaceholder:@"昵称，个性后缀"];
     searchBar;
     });
     [self.myTableView sizeToFit];
     _myTableView.tableHeaderView = _mySearchBar;
}

-(IBAction)selectRightAction:(id)sender{
    [self updateProjectMembersData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateProjectMembersData];
}

- (void)updateProjectMembersData {
    __weak typeof(self) weakSelf = self;
    self.addReviewerPath = [NSString stringWithFormat:@"/api/user/%@/project/%@/git/merge/%@/add_reviewer",_curMRPR.des_owner_name, _curMRPR.des_project_name,self.curMRPR.iid];
    [[Coding_NetAPIManager sharedManager] request_ProjectMembers_WithObj:self.currentProject andBlock:^(id data, NSError *error) {
        [weakSelf.view endLoading];
        if (data) {
            NSMutableArray* projectUsers = data;
            weakSelf.projectUsers = projectUsers;
            [weakSelf updateUnReviewers];
            [weakSelf.myTableView reloadData];
        }
    }];
    [[Coding_NetAPIManager sharedManager] request_MRReviewerInfo_WithObj:_curMRPR andBlock:^(ReviewersInfo *data, NSError *error) {
        if (data) {
            weakSelf.curReviewersInfo = data;
            [weakSelf updateUnReviewers];
            [weakSelf.myTableView reloadData];
        }
    }];
}

-(void)updateUnReviewers {
    BOOL flag = NO;
    NSMutableArray *totalUser = [[NSMutableArray alloc] init];
    for(int i = 0; i < self.projectUsers.count; i ++) {
        flag = YES;
        ProjectMember* member = self.projectUsers[i];
        for(int j = 0; j < self.curReviewersInfo.reviewers.count; j ++) {
            Reviewer* reviewer = self.curReviewersInfo.reviewers[j];
            if(member.user.id == reviewer.reviewer.id) {
                flag = NO;
            }
        }
        
        for(int j = 0; j < self.curReviewersInfo.volunteer_reviewers.count; j ++) {
            Reviewer* reviewer = self.curReviewersInfo.volunteer_reviewers[j];
            if(member.user.id == reviewer.reviewer.id) {
                flag = NO;
            }
        }
        if(flag) {
            [totalUser addObject:member.user];
        }
    }
     self.users = totalUser;
    self.allUsers = totalUser;
}

- (id)initWithFrame:(CGRect)frame projects:(Projects *)projects block:(AddReviewerViewControllerBlock)block  tabBarHeight:(CGFloat)tabBarHeight
{
    //self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}
#pragma mark Table M

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.allUsers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_ReviewCell forIndexPath:indexPath];
    
    //   [cell configureCellWithHeadIconURL:@"test" reviewIconURL:@"PointLikeHead" userName:@"test" userState:@"test"];
    User* cellReviewer = self.allUsers[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    [cell initCellWithUsers:cellReviewer];
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:50];
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [ReviewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ReviewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    currentCell.accessoryType = UITableViewCellAccessoryCheckmark;
    currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    [[CodingNetAPIClient sharedJsonClient] requestJsonDataWithPath:self.addReviewerPath withParams:@{@"user_id": currentCell.user.id} withMethodType:Post andBlock:^(id data, NSError *error) {
    }];
}

#pragma mark SWTableViewCellDelegate
- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell{
    return YES;
}
#pragma mark ScrollView Delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    if (scrollView == _myTableView) {
        [self.mySearchBar resignFirstResponder];
    }
}

#pragma mark UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    [self searchProjectWithStr:searchText];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [searchBar resignFirstResponder];
    [self searchProjectWithStr:searchBar.text];
}

- (void)searchProjectWithStr:(NSString *)searchString{
    // strip out all the leading and trailing spaces
    NSString *strippedStr = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = nil;
    if (strippedStr.length > 0)
    {
        searchItems = [strippedStr componentsSeparatedByString:@" "];
    }
    
    // build all the "AND" expressions for each value in the searchString
    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    
    for (NSString *searchString in searchItems)
    {
        // each searchString creates an OR predicate for: name, global_key
        NSMutableArray *searchItemsPredicate = [NSMutableArray array];
        
        // name field matching
        NSExpression *lhs = [NSExpression expressionForKeyPath:@"name"];
        NSExpression *rhs = [NSExpression expressionForConstantValue:searchString];
        NSPredicate *finalPredicate = [NSComparisonPredicate
                                       predicateWithLeftExpression:lhs
                                       rightExpression:rhs
                                       modifier:NSDirectPredicateModifier
                                       type:NSContainsPredicateOperatorType
                                       options:NSCaseInsensitivePredicateOption];
        [searchItemsPredicate addObject:finalPredicate];
        
        // at this OR predicate to ourr master AND predicate
        NSCompoundPredicate *orMatchPredicates = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
        [andMatchPredicates addObject:orMatchPredicates];
    }
    
    NSCompoundPredicate *finalCompoundPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    
    self.allUsers = [[self.users filteredArrayUsingPredicate:finalCompoundPredicate] mutableCopy];
    [self.myTableView reloadData];
}

@end