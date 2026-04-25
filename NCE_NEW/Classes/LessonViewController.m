//
//  LessonViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "LessonViewController.h"
#import "sqlite3.h"
#import "TextViewController.h"
#import "WordViewController.h"
#import "WordTestViewController.h"
#import "WordDictationViewController.h"
#import "Utility.h"

static NSString* const kLessonViewControllerCellReuseId = @"kLessonViewControllerCellReuseId";

@interface LessonViewController () <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *_allItems;
    NSMutableArray *_items;
    int _bookId;
    int _function;
    int _showTimes;
    NSInteger _currIndex;
    NSSet *_completedLessonIds;
    NSDictionary *_lastLesson;
    NSString *_filterStatus;
}

@property (nonatomic, strong) UITableView *tableView;

- (void)initData;
- (void)addTableView;
- (UIView *)tableHeaderViewWithWidth:(CGFloat)width;
- (NSString *)statusForLessonId:(NSString *)lessonId;
- (void)applyLessonFilter;
- (void)filterLessons:(UIButton *)button;
- (void)updateEmptyState;

@end

@implementation LessonViewController

- (id)initWithBookId:(int)bookId withTitle:(NSString *)title withFunction:(int)function
{
    self = [super init];
    if (self) {
        _bookId = bookId;
        self.titleString = title;
        _function = function;
        _showTimes = 1;
        _currIndex = -1;
        _completedLessonIds = [Utility nceCompletedLessonIds];
        _lastLesson = [Utility nceLastLesson];
        _filterStatus = @"全部";
        
        [self initData];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLessonViewControllerCellReuseId
                                                            forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray *array = [cell.contentView subviews];
    for (UIView *view in array) {
        [view removeFromSuperview];
    }
    
    NSString *nameString = [[_items objectAtIndex:indexPath.row] objectForKey:@"name"];
    NSArray *lessonArray = [nameString componentsSeparatedByString:@"－"];
    NSString *lessonNo = lessonArray.count > 0 ? [lessonArray objectAtIndex:0] : @"Lesson";
    NSString *englishTitle = lessonArray.count > 1 ? [lessonArray objectAtIndex:1] : nameString;
    NSString *chineseTitle = lessonArray.count > 2 ? [lessonArray objectAtIndex:2] : @"";
    UIColor *statusBgColor = [UIColor colorWithRed:239/255.f green:242/255.f blue:242/255.f alpha:1.f];
    UIColor *statusTextColor = [Utility nceSecondaryTextColor];
    NSString *lessonId = [[_items objectAtIndex:indexPath.row] objectForKey:@"id"];
    NSString *statusText = [self statusForLessonId:lessonId];
    if ([statusText isEqualToString:@"已完成"]) {
        statusBgColor = [Utility nceBrandSoftColor];
        statusTextColor = [Utility nceBrandColor];
    } else if ([statusText isEqualToString:@"学习中"]) {
        statusBgColor = [UIColor colorWithRed:255/255.f green:235/255.f blue:226/255.f alpha:1.f];
        statusTextColor = [Utility nceAccentColor];
    }
    
    CGFloat cardX = 14.f;
    CGFloat cardY = 6.f;
    CGFloat cardWidth = tableView.frame.size.width - 28.f;
    UIView *cardView = [Utility nceCardViewWithFrame:CGRectMake(cardX, cardY, cardWidth, 82.f)];
    cardView.layer.shadowOpacity = 0.5f;
    [cell.contentView addSubview:cardView];
    
    UILabel *idLabel = [Utility nceLabelWithFrame:CGRectMake(14.f, 17.f, 62.f, 24.f)
                                            text:lessonNo
                                            font:[UIFont boldSystemFontOfSize:13.f]
                                           color:[Utility nceBrandColor]];
    idLabel.textAlignment = NSTextAlignmentCenter;
    idLabel.backgroundColor = [Utility nceBrandSoftColor];
    idLabel.layer.cornerRadius = 12.f;
    idLabel.layer.masksToBounds = YES;
    [cardView addSubview:idLabel];
    
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(90.f, 14.f, cardWidth - 178.f, 25.f)
                                               text:englishTitle
                                               font:[UIFont boldSystemFontOfSize:16.f]
                                              color:[Utility nceTextColor]];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.76f;
    [cardView addSubview:titleLabel];
    
    UILabel *subTitleLabel = [Utility nceLabelWithFrame:CGRectMake(90.f, 43.f, cardWidth - 178.f, 22.f)
                                                  text:chineseTitle
                                                  font:[UIFont systemFontOfSize:13.f]
                                                 color:[Utility nceSecondaryTextColor]];
    subTitleLabel.textAlignment = NSTextAlignmentLeft;
    [cardView addSubview:subTitleLabel];
    
    UILabel *statusLabel = [Utility nceLabelWithFrame:CGRectMake(cardWidth - 78.f, 28.f, 58.f, 26.f)
                                                text:statusText
                                                font:[UIFont systemFontOfSize:12.f]
                                               color:statusTextColor];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.backgroundColor = statusBgColor;
    statusLabel.layer.cornerRadius = 13.f;
    statusLabel.layer.masksToBounds = YES;
    [cardView addSubview:statusLabel];
    
    // show when the cell is selected
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(cardX, cardY, cardWidth, 82.f)];
    maskView.backgroundColor = [UIColor clearColor];
    maskView.tag = 1000+indexPath.row;
    [cell.contentView addSubview:maskView];
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 94.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view viewWithTag:1000+indexPath.row].backgroundColor = [UIColor colorWithWhite:0.3f alpha:0.15f];
    
    NSDictionary *lesson = [_items objectAtIndex:indexPath.row];
    
    if (_function == 0) {
        TextViewController *textController = [[TextViewController alloc] initWithBookId:_bookId
                                                                             withLesson:lesson];
        [self.navigationController pushViewController:textController animated:YES];
    
    } else if (_function < 4) {
        WordViewController *wordController = [[WordViewController alloc] initWithBookId:_bookId
                                                                             withLesson:lesson
                                                                           withFunction:_function];
        wordController.titleString = self.titleString;
        [self.navigationController pushViewController:wordController animated:YES];
    } else if (_function == 4) {
        WordDictationViewController *dictationController = [[WordDictationViewController alloc]
                                                            initWithBookId:_bookId
                                                            withLessonId:[[lesson objectForKey:@"id"] intValue]];
        [self.navigationController pushViewController:dictationController animated:YES];
    } else if (_function < 7) {
        WordTestViewController *wortTestController = [[WordTestViewController alloc]
                                                      initWithBookId:_bookId
                                                      withLessonId:[[lesson objectForKey:@"id"] intValue]
                                                      withFunction:_function];
        [self.navigationController pushViewController:wortTestController animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view viewWithTag:1000+indexPath.row].backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)])
    {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    else if ([tableView respondsToSelector:@selector(setLayoutMargins:)])
    {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    else if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)initData
{
    _allItems = [[NSMutableArray alloc] init];
    _items = [[NSMutableArray alloc] init];
    
    sqlite3 *database;
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
    
    if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
        //                NSLog(@"ok");
    }
    
    NSString *selectSql = [NSString stringWithFormat:@"select `name`,`lesson_id` from play_list_lessons where book_id=%d order by order_id",_bookId+1];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [selectSql UTF8String], -1, &statement, nil)==SQLITE_OK) {
        //                NSLog(@"select ok.");
    }
    
    while (sqlite3_step(statement)==SQLITE_ROW) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:2];
        
        NSString *nameString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        [item setObject:nameString forKey:@"name"];
        
        NSString *idString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
        [item setObject:idString forKey:@"id"];
        
        [_allItems addObject:item];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    [self applyLessonFilter];
}

- (NSString *)statusForLessonId:(NSString *)lessonId
{
    if ([_completedLessonIds containsObject:lessonId]) {
        return @"已完成";
    }
    
    if ([[_lastLesson objectForKey:@"id"] isEqualToString:lessonId]) {
        return @"学习中";
    }
    
    return @"未学";
}

- (void)applyLessonFilter
{
    [_items removeAllObjects];
    for (NSDictionary *lesson in _allItems) {
        NSString *status = [self statusForLessonId:[lesson objectForKey:@"id"]];
        if ([_filterStatus isEqualToString:@"全部"] || [_filterStatus isEqualToString:status]) {
            [_items addObject:lesson];
        }
    }
}

- (void)filterLessons:(UIButton *)button
{
    NSArray *filters = @[@"全部", @"未学", @"学习中", @"已完成"];
    if (button.tag < 0 || button.tag >= filters.count) {
        return;
    }
    
    _filterStatus = [filters objectAtIndex:button.tag];
    [self applyLessonFilter];
    self.tableView.tableHeaderView = [self tableHeaderViewWithWidth:CGRectGetWidth(self.tableView.frame)];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)updateEmptyState
{
    if (_items.count > 0) {
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        return;
    }
    
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.tableView.frame), 180.f)];
    UILabel *emptyLabel = [Utility nceLabelWithFrame:CGRectMake(24.f, 58.f, CGRectGetWidth(emptyView.frame) - 48.f, 44.f)
                                               text:[NSString stringWithFormat:@"当前没有%@课文", _filterStatus]
                                               font:[UIFont systemFontOfSize:15.f]
                                              color:[Utility nceSecondaryTextColor]];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    [emptyView addSubview:emptyLabel];
    self.tableView.tableFooterView = emptyView;
}

- (void)addTableView
{
    _completedLessonIds = [Utility nceCompletedLessonIds];
    _lastLesson = [Utility nceLastLesson];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:view];
    
    CGRect tableViewFrame = [self getTableViewFrame];
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [self tableHeaderViewWithWidth:CGRectGetWidth(tableViewFrame)];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kLessonViewControllerCellReuseId];
    
    [self.view addSubview:self.tableView];
    [self updateEmptyState];
}

- (UIView *)tableHeaderViewWithWidth:(CGFloat)width
{
    NSDictionary *statsDictionary = [Utility nceStudyStats];
    NSInteger completedLessons = [[statsDictionary objectForKey:@"completedLessons"] integerValue];
    NSInteger totalLessons = [[statsDictionary objectForKey:@"totalLessons"] integerValue];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, width, 132.f)];
    headerView.backgroundColor = [UIColor clearColor];
    
    UIView *summaryCard = [Utility nceCardViewWithFrame:CGRectMake(14.f, 12.f, width - 28.f, 72.f)];
    [headerView addSubview:summaryCard];
    
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(16.f, 12.f, width - 60.f, 24.f)
                                               text:@"第一册进度"
                                               font:[UIFont boldSystemFontOfSize:17.f]
                                              color:[Utility nceTextColor]];
    [summaryCard addSubview:titleLabel];
    
    UILabel *progressLabel = [Utility nceLabelWithFrame:CGRectMake(16.f, 40.f, width - 60.f, 18.f)
                                                  text:[NSString stringWithFormat:@"已完成 %ld / %ld 课", (long)completedLessons, (long)totalLessons]
                                                  font:[UIFont systemFontOfSize:13.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [summaryCard addSubview:progressLabel];
    
    UIView *progressBg = [[UIView alloc] initWithFrame:CGRectMake(width - 148.f, 34.f, 104.f, 8.f)];
    progressBg.backgroundColor = [Utility nceBrandSoftColor];
    progressBg.layer.cornerRadius = 4.f;
    [summaryCard addSubview:progressBg];
    
    CGFloat progress = totalLessons > 0 ? (CGFloat)completedLessons / (CGFloat)totalLessons : 0.f;
    UIView *progressValue = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 104.f * progress, 8.f)];
    progressValue.backgroundColor = [Utility nceBrandColor];
    progressValue.layer.cornerRadius = 4.f;
    [progressBg addSubview:progressValue];
    
    NSArray *chips = @[@"全部", @"未学", @"学习中", @"已完成"];
    CGFloat chipX = 14.f;
    for (int ii = 0; ii < chips.count; ii++) {
        CGFloat chipWidth = ii == 0 ? 54.f : 68.f;
        BOOL selected = [_filterStatus isEqualToString:[chips objectAtIndex:ii]];
        UIButton *chipButton = [Utility nceTextButtonWithFrame:CGRectMake(chipX, 98.f, chipWidth, 28.f)
                                                          text:[chips objectAtIndex:ii]
                                               backgroundColor:selected ? [Utility nceBrandColor] : [UIColor whiteColor]
                                                     textColor:selected ? [UIColor whiteColor] : [Utility nceSecondaryTextColor]];
        chipButton.titleLabel.font = [UIFont systemFontOfSize:13.f];
        chipButton.tag = ii;
        [chipButton addTarget:self action:@selector(filterLessons:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:chipButton];
        chipX += chipWidth + 8.f;
    }
    
    return headerView;
}

@end
