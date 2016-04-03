//
//  NSObject+ReviewerListView.m
//  Coding_iOS
//
//  Created by hardac on 16/3/25.
//  Copyright © 2016年 Coding. All rights reserved.
//
#import "ReviewerListController.h"
#import "ReviewCell.h"
#import "ProjectListCell.h"
#import "ProjectListTaCell.h"
#import "ODRefreshControl.h"
#import "Coding_NetAPIManager.h"
#import "AddReviewerViewController.h"

//新系列 cell
#import "ProjectAboutMeListCell.h"
#import "ProjectAboutOthersListCell.h"
#import "ProjectPublicListCell.h"
#import "SVPullToRefresh.h"

@interface ReviewerListController ()<UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) NSString *delReviewerPath;
@property (strong, nonatomic) UISearchBar *mySearchBar;
@property (strong, nonatomic) ReviewersInfo *curReviewersInfo;

@end

@implementation ReviewerListController

static NSString *const kTitleKey = @"kTitleKey";
static NSString *const kValueKey = @"kValueKey";

-(void)viewDidLoad {
    self.title = @"评审人";
    [self.myTableView registerNib:[UINib nibWithNibName:kCellIdentifier_ReviewCell bundle:nil] forCellReuseIdentifier:kCellIdentifier_ReviewCell];
    self.myTableView.separatorStyle = NO;
    self.reviewers = [[NSMutableArray alloc] init];
    self.volunteer_reviewers = [[NSMutableArray alloc] init];
    UIImage* backImage = [UIImage imageNamed:@"tag_button_add.png"];
    CGRect backframe = CGRectMake(0,0,19,19);
    UIButton* addReviewerButton= [[UIButton alloc] initWithFrame:backframe];
    [addReviewerButton setBackgroundImage:backImage forState:UIControlStateNormal];
    [addReviewerButton addTarget:self action:@selector(selectRightAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addReviewerButton];
    self.navigationItem.rightBarButtonItem = leftBarButtonItem;

}

-(void)viewWillAppear:(BOOL)animated {
    self.delReviewerPath = [NSString stringWithFormat:@"/api/user/%@/project/%@/git/merge/%@/del_reviewer",_curMRPR.des_owner_name, _curMRPR.des_project_name,self.curMRPR.iid];
    __weak typeof(self) weakSelf = self;
    [[Coding_NetAPIManager sharedManager] request_MRReviewerInfo_WithObj:_curMRPR andBlock:^(ReviewersInfo *data, NSError *error) {
        if (data) {
            weakSelf.curReviewersInfo = data;
            weakSelf.reviewers = weakSelf.curReviewersInfo.reviewers;
            
            weakSelf.volunteer_reviewers = weakSelf.curReviewersInfo.volunteer_reviewers;
            [weakSelf.myTableView reloadData];
        }
    }];
}

-(void)selectRightAction:(id)sender
{
    NSArray  *apparray= [[NSBundle mainBundle]loadNibNamed:@"AddReviewerViewController" owner:nil options:nil];
    AddReviewerViewController *appview=[apparray firstObject];
    appview.reviewers = self.reviewers;
    appview.volunteer_reviewers = self.volunteer_reviewers;
    appview.curMRPR = self.curMRPR;
    appview.currentProject = self.currentProject;
    
    [self.navigationController pushViewController:appview animated:YES];
}

- (id)initWithFrame:(CGRect)frame projects:(Projects *)projects block:(ReviewerListControllerBlock)block  tabBarHeight:(CGFloat)tabBarHeight
{
    //self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}
#pragma mark Table M

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.reviewers count] + [self.volunteer_reviewers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ReviewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier_ReviewCell forIndexPath:indexPath];
    
 //   [cell configureCellWithHeadIconURL:@"test" reviewIconURL:@"PointLikeHead" userName:@"test" userState:@"test"];

    if(indexPath.row < self.reviewers.count) {
         Reviewer* cellReviewer = self.reviewers[indexPath.row];
        [cell initCellWithReviewer:cellReviewer.reviewer likeValue:cellReviewer.value];
    } else {
         Reviewer* cellReviewer = self.volunteer_reviewers[indexPath.row - self.reviewers.count];
        [cell initCellWithVolunteerReviewers:cellReviewer.reviewer likeValue:cellReviewer.value];
    }
    [tableView addLineforPlainCell:cell forRowAtIndexPath:indexPath withLeftSpace:50];
    return cell;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [ReviewCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
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

- (void)searchProjectWithStr:(NSString *)string{
    [self.myTableView reloadData];
}


//先要设Cell可编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < self.reviewers.count) {
        return YES;
    } else {
        return NO;
    }
}

//定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{

    return UITableViewCellEditingStyleDelete;
}

//进入编辑模式，按下出现的编辑按钮后
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReviewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    [[CodingNetAPIClient sharedJsonClient] requestJsonDataWithPath:self.delReviewerPath withParams:@{@"user_id":currentCell.user.id} withMethodType:Delete andBlock:^(id data, NSError *error) {
        if (data) {
            Reviewer* tmpReviewer;
            if(indexPath.row < weakSelf.reviewers.count) {
               tmpReviewer = weakSelf.reviewers[indexPath.row];
               [weakSelf.reviewers removeObject:tmpReviewer];
               
            }
            [weakSelf.myTableView reloadData];
        }
    }];
}



//修改编辑按钮文字
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}


//先设置Cell可移动
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < self.reviewers.count) {
        return YES;
    } else {
        return NO;
    }
}


//设置进入编辑状态时，Cell不会缩进
- (BOOL)tableView: (UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
