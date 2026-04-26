//
//  SettingViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "SettingViewController.h"
#import "Utility.h"

@interface SettingViewController ()

- (void)addSettingsView;
- (UIView *)settingCardWithFrame:(CGRect)frame;
- (void)addMenuRowToView:(UIView *)view title:(NSString *)title subtitle:(NSString *)subtitle y:(CGFloat)y;
- (void)showVersionInfo;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [Utility nceBackgroundColor];
    self.navigationItem.title = @"设置";
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftItemsSupplementBackButton = NO;
    UIImage *backImage = [[UIImage imageNamed:@"btn_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(goBack)];
    
    [self addSettingsView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Private Methods

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addSettingsView
{
    CGFloat safeTop = 0.f;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
    }
    
    CGRect layoutFrame = self.view.bounds;
    if (@available(iOS 11.0, *)) {
        layoutFrame = self.view.safeAreaLayoutGuide.layoutFrame;
    }
    CGFloat viewWidth = [Utility isPad] ? CGRectGetWidth(layoutFrame) : CGRectGetWidth(self.view.bounds);
    CGFloat margin = ([Utility isPad] ? CGRectGetMinX(layoutFrame) : 0.f) + [Utility nceReadableContentXForViewWidth:viewWidth];
    CGFloat width = [Utility nceReadableContentWidthForViewWidth:viewWidth];
    CGFloat contentTop = safeTop + ([Utility isPad] ? 52.f : 64.f);
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    
    NSDictionary *stats = [Utility nceStudyStats];
    NSInteger completedLessons = [[stats objectForKey:@"completedLessons"] integerValue];
    NSInteger totalLessons = [[stats objectForKey:@"totalLessons"] integerValue];
    NSInteger masteredWords = [[stats objectForKey:@"masteredWords"] integerValue];
    NSInteger totalWords = [[stats objectForKey:@"totalWords"] integerValue];
    NSInteger wordBookCount = [[stats objectForKey:@"wordBookCount"] integerValue];
    
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(margin, contentTop, width, 32.f)
                                               text:@"第一册独立版"
                                               font:[UIFont boldSystemFontOfSize:28.f]
                                              color:[Utility nceTextColor]];
    [scrollView addSubview:titleLabel];
    
    UILabel *subtitleLabel = [Utility nceLabelWithFrame:CGRectMake(margin, CGRectGetMaxY(titleLabel.frame) + 6.f, width, 22.f)
                                                  text:@"72课完整课程 · 离线学习"
                                                  font:[UIFont systemFontOfSize:14.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [scrollView addSubview:subtitleLabel];
    
    CGFloat versionY = CGRectGetMaxY(subtitleLabel.frame) + 18.f;
    UIView *versionCard = [self settingCardWithFrame:CGRectMake(margin, versionY, width, 94.f)];
    [scrollView addSubview:versionCard];
    
    UILabel *versionTitle = [Utility nceLabelWithFrame:CGRectMake(18.f, 16.f, width - 36.f, 24.f)
                                                 text:@"当前版本"
                                                 font:[UIFont boldSystemFontOfSize:17.f]
                                                color:[Utility nceTextColor]];
    [versionCard addSubview:versionTitle];
    
    UILabel *versionValue = [Utility nceLabelWithFrame:CGRectMake(18.f, 46.f, width - 36.f, 24.f)
                                                 text:@"新概念英语第一册 · 独立版"
                                                 font:[UIFont systemFontOfSize:15.f]
                                                color:[Utility nceBrandColor]];
    [versionCard addSubview:versionValue];
    
    CGFloat statsY = CGRectGetMaxY(versionCard.frame) + 14.f;
    UIView *statsCard = [self settingCardWithFrame:CGRectMake(margin, statsY, width, 116.f)];
    [scrollView addSubview:statsCard];
    
    UILabel *statsTitle = [Utility nceLabelWithFrame:CGRectMake(18.f, 14.f, width - 36.f, 22.f)
                                               text:@"学习统计"
                                               font:[UIFont boldSystemFontOfSize:17.f]
                                              color:[Utility nceTextColor]];
    [statsCard addSubview:statsTitle];
    
    NSArray *statItems = @[
        @[@"已学课文", [NSString stringWithFormat:@"%ld/%ld", (long)completedLessons, (long)totalLessons]],
        @[@"已掌握单词", [NSString stringWithFormat:@"%ld/%ld", (long)masteredWords, (long)totalWords]],
        @[@"单词本", [NSString stringWithFormat:@"%ld", (long)wordBookCount]]
    ];
    CGFloat statWidth = (width - 36.f) / 3.f;
    for (int ii = 0; ii < statItems.count; ii++) {
        UILabel *valueLabel = [Utility nceLabelWithFrame:CGRectMake(18.f + ii * statWidth, 49.f, statWidth, 26.f)
                                                   text:statItems[ii][1]
                                                   font:[UIFont boldSystemFontOfSize:20.f]
                                                  color:[Utility nceTextColor]];
        valueLabel.textAlignment = NSTextAlignmentCenter;
        [statsCard addSubview:valueLabel];
        
        UILabel *nameLabel = [Utility nceLabelWithFrame:CGRectMake(18.f + ii * statWidth, 77.f, statWidth, 18.f)
                                                  text:statItems[ii][0]
                                                  font:[UIFont systemFontOfSize:12.f]
                                                 color:[Utility nceSecondaryTextColor]];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [statsCard addSubview:nameLabel];
    }
    
    CGFloat menuY = CGRectGetMaxY(statsCard.frame) + 14.f;
    UIView *menuCard = [self settingCardWithFrame:CGRectMake(margin, menuY, width, 228.f)];
    [scrollView addSubview:menuCard];
    
    [self addMenuRowToView:menuCard title:@"数据备份与恢复" subtitle:@"学习记录保存在本机" y:0.f];
    [self addMenuRowToView:menuCard title:@"反馈与联系" subtitle:@"欢迎反馈学习体验" y:56.f];
    [self addMenuRowToView:menuCard title:@"隐私说明" subtitle:@"不上传你的学习记录" y:112.f];
    [self addMenuRowToView:menuCard title:@"关于第一册独立版" subtitle:@"专注完成第一册学习闭环" y:168.f];
    
    UIButton *versionButton = [Utility nceTextButtonWithFrame:CGRectMake(margin, CGRectGetMaxY(menuCard.frame) + 18.f, width, 42.f)
                                                         text:@"第一册版本说明"
                                              backgroundColor:[UIColor whiteColor]
                                                    textColor:[Utility nceSecondaryTextColor]];
    versionButton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [versionButton addTarget:self action:@selector(showVersionInfo) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:versionButton];
    
    scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetMaxY(versionButton.frame) + 32.f);
}

- (UIView *)settingCardWithFrame:(CGRect)frame
{
    UIView *cardView = [Utility nceCardViewWithFrame:frame];
    cardView.layer.shadowOpacity = 0.7f;
    return cardView;
}

- (void)addMenuRowToView:(UIView *)view title:(NSString *)title subtitle:(NSString *)subtitle y:(CGFloat)y
{
    CGFloat width = CGRectGetWidth(view.frame);
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, y + 10.f, width - 36.f, 22.f)
                                               text:title
                                               font:[UIFont boldSystemFontOfSize:15.f]
                                              color:[Utility nceTextColor]];
    [view addSubview:titleLabel];
    
    UILabel *subtitleLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, y + 32.f, width - 36.f, 18.f)
                                                  text:subtitle
                                                  font:[UIFont systemFontOfSize:12.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [view addSubview:subtitleLabel];
    
    if (y > 0.f) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(18.f, y, width - 36.f, 0.5f)];
        line.backgroundColor = [Utility nceLineColor];
        [view addSubview:line];
    }
}

- (void)showVersionInfo
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"第一册独立版"
                                                                   message:@"本版本专注第一册完整学习，包含课文、单词、听写、测试和本地学习记录，可独立使用。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
