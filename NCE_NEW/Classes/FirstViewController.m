//
//  FirstViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "FirstViewController.h"
#import "MainViewController.h"
#import "UINavigationItem+Spacing.h"
#import "Utility.h"
#import "SettingViewController.h"
#import "LessonViewController.h"
#import "WordSearchViewController.h"
#import "TextViewController.h"
#import "sqlite3.h"

static NSInteger const kNCEDashboardViewTag = 9101;

@interface FirstViewController ()
{
    CGFloat _scale;
    NSDictionary *_continueLesson;
}

- (void)addSettingButton;
- (void)goSetting;
- (void)initContinueLesson;
- (void)addDashboard;
- (void)goContinue;
- (void)goFeature:(UIButton *)button;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _scale = self.view.frame.size.width/320;
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = nil;
    backgroundView.backgroundColor = [Utility nceBackgroundColor];
    [self.view addSubview:backgroundView];
    self.navigationItem.hidesBackButton = YES;
    
    UIImage *image = [UIImage imageNamed:@"bg_navigation"];
    image = [image stretchableImageWithLeftCapWidth:floorf(image.size.width/2) topCapHeight:floorf(image.size.height/2)];
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    // set title
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dic;
    self.navigationItem.title = @"新概念第一册";
    [self addSettingButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initContinueLesson];
    [self addDashboard];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Private Methods

- (void)addSettingButton
{
    UIButton *settingButton = [Utility nceCircleIconButtonWithFrame:CGRectMake(0.f, 0.f, 36.f, 36.f)
                                                         systemName:@"gearshape"
                                                       fallbackText:@"设"
                                                          iconColor:[Utility nceBrandColor]
                                                    backgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.92f]];
    settingButton.accessibilityLabel = @"设置";
    [settingButton addTarget:self action:@selector(goSetting) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingButton];
}

- (void)goSetting
{
    SettingViewController *setttingController = [[SettingViewController alloc] init];
    [self.navigationController pushViewController:setttingController animated:YES];
}

- (void)initContinueLesson
{
    _continueLesson = nil;
    
    NSDictionary *lastLesson = [Utility nceLastLesson];
    if (lastLesson) {
        _continueLesson = lastLesson;
        return;
    }
    
    sqlite3 *database;
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
    if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK) {
        return;
    }

    NSString *selectSql = @"select `name`,`lesson_id` from play_list_lessons where book_id=1 and order_id=8";
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [selectSql UTF8String], -1, &statement, nil) == SQLITE_OK &&
        sqlite3_step(statement) == SQLITE_ROW) {
        NSString *nameString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        NSString *idString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
        _continueLesson = @{@"name": nameString, @"id": idString};
    }
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (void)addDashboard
{
    [[self.view viewWithTag:kNCEDashboardViewTag] removeFromSuperview];
    
    NSDictionary *statsDictionary = [Utility nceStudyStats];
    NSInteger completedLessons = [[statsDictionary objectForKey:@"completedLessons"] integerValue];
    NSInteger totalLessons = [[statsDictionary objectForKey:@"totalLessons"] integerValue];
    NSInteger familiarWords = [[statsDictionary objectForKey:@"familiarWords"] integerValue];
    NSInteger totalWords = [[statsDictionary objectForKey:@"totalWords"] integerValue];
    NSInteger wrongWords = [[statsDictionary objectForKey:@"wrongWords"] integerValue];
    
    CGRect layoutFrame = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        layoutFrame = self.view.safeAreaLayoutGuide.layoutFrame;
    }
    CGFloat viewWidth = [Utility isPad] ? CGRectGetWidth(layoutFrame) : CGRectGetWidth(self.view.bounds);
    CGFloat navigationBottom = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat safeTop = 0.f;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    CGFloat contentTop = [Utility isPad] ? MIN(safeTop + 118.f, 128.f) : navigationBottom + 34.f;
    CGFloat margin = ([Utility isPad] ? CGRectGetMinX(layoutFrame) : 0.f) + [Utility nceReadableContentXForViewWidth:viewWidth];
    CGFloat width = [Utility nceReadableContentWidthForViewWidth:viewWidth];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.tag = kNCEDashboardViewTag;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.alwaysBounceVertical = YES;
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:scrollView];
    
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(margin, contentTop, width - 90.f, 32.f)
                                               text:@"新概念英语第一册"
                                               font:[UIFont boldSystemFontOfSize:28.f]
                                              color:[Utility nceTextColor]];
    [scrollView addSubview:titleLabel];
    
    UILabel *badgeLabel = [Utility nceLabelWithFrame:CGRectMake(margin, CGRectGetMaxY(titleLabel.frame) + 8.f, 170.f, 28.f)
                                              text:@"独立版 · 72课完整课程"
                                              font:[UIFont systemFontOfSize:13.f]
                                             color:[Utility nceBrandColor]];
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    badgeLabel.backgroundColor = [Utility nceBrandSoftColor];
    badgeLabel.layer.cornerRadius = 14.f;
    badgeLabel.layer.masksToBounds = YES;
    [scrollView addSubview:badgeLabel];
    
    UIImageView *bookView = [[UIImageView alloc] initWithFrame:CGRectMake(margin + width - 64.f, contentTop - 2.f, 58.f, 82.f)];
    bookView.image = [UIImage imageNamed:@"book1.jpg"];
    bookView.contentMode = UIViewContentModeScaleAspectFill;
    bookView.layer.cornerRadius = 8.f;
    bookView.layer.masksToBounds = YES;
    bookView.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:0.12f].CGColor;
    bookView.layer.shadowOffset = CGSizeMake(0.f, 4.f);
    bookView.layer.shadowOpacity = 1.f;
    bookView.layer.shadowRadius = 8.f;
    [scrollView addSubview:bookView];
    
    CGFloat cardY = CGRectGetMaxY(badgeLabel.frame) + 26.f;
    UIView *continueCard = [Utility nceCardViewWithFrame:CGRectMake(margin, cardY, width, 190.f)];
    [scrollView addSubview:continueCard];
    
    UILabel *continueLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 18.f, width - 36.f, 22.f)
                                                  text:@"继续学习"
                                                  font:[UIFont boldSystemFontOfSize:17.f]
                                                 color:[Utility nceTextColor]];
    [continueCard addSubview:continueLabel];
    
    NSArray *lessonArray = [[_continueLesson objectForKey:@"name"] componentsSeparatedByString:@"－"];
    NSString *lessonNo = lessonArray.count > 0 ? [lessonArray objectAtIndex:0] : @"Lesson";
    NSString *englishTitle = lessonArray.count > 1 ? [lessonArray objectAtIndex:1] : @"Your Passports, Please.";
    NSString *chineseTitle = lessonArray.count > 2 ? [lessonArray objectAtIndex:2] : @"请出示你们的护照";
    
    UILabel *lessonLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 52.f, width - 36.f, 24.f)
                                                text:[NSString stringWithFormat:@"%@  %@", lessonNo, englishTitle]
                                                font:[UIFont boldSystemFontOfSize:18.f]
                                               color:[Utility nceTextColor]];
    lessonLabel.adjustsFontSizeToFitWidth = YES;
    lessonLabel.minimumScaleFactor = 0.78f;
    [continueCard addSubview:lessonLabel];
    
    UILabel *subLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 80.f, width - 36.f, 20.f)
                                             text:chineseTitle
                                             font:[UIFont systemFontOfSize:14.f]
                                            color:[Utility nceSecondaryTextColor]];
    [continueCard addSubview:subLabel];
    
    UIView *progressBg = [[UIView alloc] initWithFrame:CGRectMake(18.f, 116.f, width - 36.f, 8.f)];
    progressBg.backgroundColor = [Utility nceBrandSoftColor];
    progressBg.layer.cornerRadius = 4.f;
    [continueCard addSubview:progressBg];
    
    CGFloat lessonProgress = totalLessons > 0 ? (CGFloat)completedLessons / (CGFloat)totalLessons : 0.f;
    UIView *progressValue = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(progressBg.frame) * lessonProgress, 8.f)];
    progressValue.backgroundColor = [Utility nceBrandColor];
    progressValue.layer.cornerRadius = 4.f;
    [progressBg addSubview:progressValue];
    
    UILabel *progressLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 132.f, 120.f, 22.f)
                                                  text:[NSString stringWithFormat:@"已完成 %ld / %ld 课", (long)completedLessons, (long)totalLessons]
                                                  font:[UIFont systemFontOfSize:13.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [continueCard addSubview:progressLabel];
    
    UIButton *continueButton = [Utility nceTextButtonWithFrame:CGRectMake(width - 130.f, 138.f, 106.f, 38.f)
                                                          text:@"继续学习"
                                               backgroundColor:[Utility nceAccentColor]
                                                     textColor:[UIColor whiteColor]];
    [continueButton addTarget:self action:@selector(goContinue) forControlEvents:UIControlEventTouchUpInside];
    [continueCard addSubview:continueButton];
    
    NSArray *stats = @[@[@"课文", [NSString stringWithFormat:@"%ld/%ld", (long)completedLessons, (long)totalLessons]],
                       @[@"单词", [NSString stringWithFormat:@"%ld/%ld", (long)familiarWords, (long)totalWords]],
                       @[@"错题", [NSString stringWithFormat:@"%ld词", (long)wrongWords]]];
    CGFloat statY = CGRectGetMaxY(continueCard.frame) + 14.f;
    CGFloat statWidth = (width - 16.f) / 3.f;
    for (int ii = 0; ii < stats.count; ii++) {
        UIView *statCard = [Utility nceCardViewWithFrame:CGRectMake(margin + ii * (statWidth + 8.f), statY, statWidth, 74.f)];
        [scrollView addSubview:statCard];
        UILabel *valueLabel = [Utility nceLabelWithFrame:CGRectMake(10.f, 13.f, statWidth - 20.f, 24.f)
                                                   text:stats[ii][1]
                                                   font:[UIFont boldSystemFontOfSize:18.f]
                                                  color:[Utility nceTextColor]];
        valueLabel.textAlignment = NSTextAlignmentCenter;
        [statCard addSubview:valueLabel];
        UILabel *nameLabel = [Utility nceLabelWithFrame:CGRectMake(10.f, 40.f, statWidth - 20.f, 20.f)
                                                  text:stats[ii][0]
                                                  font:[UIFont systemFontOfSize:12.f]
                                                 color:[Utility nceSecondaryTextColor]];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [statCard addSubview:nameLabel];
    }
    
    CGFloat adviceY = statY + 92.f;
    UIView *adviceCard = [Utility nceCardViewWithFrame:CGRectMake(margin, adviceY, width, 96.f)];
    [scrollView addSubview:adviceCard];
    
    UILabel *adviceTitle = [Utility nceLabelWithFrame:CGRectMake(18.f, 14.f, width - 36.f, 22.f)
                                                text:@"今日建议"
                                                font:[UIFont boldSystemFontOfSize:17.f]
                                               color:[Utility nceTextColor]];
    [adviceCard addSubview:adviceTitle];
    
    NSString *adviceText = nil;
    if (wrongWords > 0) {
        adviceText = [NSString stringWithFormat:@"先复习 %ld 个做错单词，再继续当前课文。", (long)wrongWords];
    } else if (completedLessons < totalLessons) {
        adviceText = [NSString stringWithFormat:@"继续 %@，听完后复习本课单词。", lessonNo];
    } else {
        adviceText = @"第一册课文已完成，可以集中复习陌生词和错题。";
    }
    
    UILabel *adviceLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 44.f, width - 36.f, 40.f)
                                                text:adviceText
                                                font:[UIFont systemFontOfSize:14.f]
                                               color:[Utility nceSecondaryTextColor]];
    adviceLabel.numberOfLines = 2;
    [adviceCard addSubview:adviceLabel];
    
    NSArray *features = @[@[@"学课文", @"听"], @[@"背单词", @"词"], @[@"做测试", @"练"], @[@"单词搜索", @"查"]];
    CGFloat featureY = CGRectGetMaxY(adviceCard.frame) + 18.f;
    for (int ii = 0; ii < features.count; ii++) {
        CGFloat x = margin + (ii % 2) * ((width - 10.f) / 2.f + 10.f);
        CGFloat y = featureY + (ii / 2) * 76.f;
        UIButton *featureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        featureButton.frame = CGRectMake(x, y, (width - 10.f) / 2.f, 64.f);
        featureButton.backgroundColor = [UIColor whiteColor];
        featureButton.layer.cornerRadius = 10.f;
        featureButton.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:0.06f].CGColor;
        featureButton.layer.shadowOffset = CGSizeMake(0.f, 3.f);
        featureButton.layer.shadowOpacity = 1.f;
        featureButton.layer.shadowRadius = 8.f;
        featureButton.tag = ii;
        [featureButton addTarget:self action:@selector(goFeature:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:featureButton];
        
        UILabel *iconLabel = [Utility nceLabelWithFrame:CGRectMake(14.f, 15.f, 34.f, 34.f)
                                                  text:features[ii][1]
                                                  font:[UIFont boldSystemFontOfSize:15.f]
                                                 color:[Utility nceBrandColor]];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.backgroundColor = [Utility nceBrandSoftColor];
        iconLabel.layer.cornerRadius = 17.f;
        iconLabel.layer.masksToBounds = YES;
        [featureButton addSubview:iconLabel];
        
        UILabel *textLabel = [Utility nceLabelWithFrame:CGRectMake(58.f, 0.f, CGRectGetWidth(featureButton.frame) - 66.f, 64.f)
                                                 text:features[ii][0]
                                                 font:[UIFont boldSystemFontOfSize:16.f]
                                                color:[Utility nceTextColor]];
        [featureButton addSubview:textLabel];
    }
    
    scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), featureY + 166.f);
}

- (void)goContinue
{
    if (_continueLesson) {
        TextViewController *textController = [[TextViewController alloc] initWithBookId:0 withLesson:_continueLesson];
        [self.navigationController pushViewController:textController animated:YES];
    } else {
        MainViewController *mainController = [[MainViewController alloc] initWithBookId:0];
        [self.navigationController pushViewController:mainController animated:YES];
    }
}

- (void)goFeature:(UIButton *)button
{
    if (button.tag == 0) {
        LessonViewController *lessonController = [[LessonViewController alloc] initWithBookId:0 withTitle:@"课文列表" withFunction:0];
        [self.navigationController pushViewController:lessonController animated:YES];
    } else if (button.tag == 1) {
        LessonViewController *lessonController = [[LessonViewController alloc] initWithBookId:0 withTitle:@"单词训练" withFunction:1];
        [self.navigationController pushViewController:lessonController animated:YES];
    } else if (button.tag == 2) {
        LessonViewController *lessonController = [[LessonViewController alloc] initWithBookId:0 withTitle:@"做测试" withFunction:5];
        [self.navigationController pushViewController:lessonController animated:YES];
    } else {
        WordSearchViewController *wordSearchController = [[WordSearchViewController alloc] initWithBookId:0];
        [self.navigationController pushViewController:wordSearchController animated:YES];
    }
}

@end
