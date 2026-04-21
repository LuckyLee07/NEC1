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

@interface FirstViewController ()
{
    CGFloat _scale;
}

- (void)addSettingButton;
- (void)goSetting;
- (void)addBooks;
- (void)goMain:(UIButton *)button;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _scale = self.view.frame.size.width/320;
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:self.view.frame];
    backgroundView.image = [UIImage imageNamed:@"background"];
    [self.view addSubview:backgroundView];
    self.navigationItem.hidesBackButton = YES;
    
    UIImage *image = [UIImage imageNamed:@"bg_navigation"];
    image = [image stretchableImageWithLeftCapWidth:floorf(image.size.width/2) topCapHeight:floorf(image.size.height/2)];
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    // set title
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dic;
    self.navigationItem.title = @"新概念英语";
    
    [self addBooks];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Private Methods

- (void)addSettingButton
{
    UIImage *settingImage = [UIImage imageNamed:@"btn_setting"];
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingButton.frame = CGRectMake(0, 0, settingImage.size.width, settingImage.size.height);
    [settingButton setBackgroundImage:settingImage forState:UIControlStateNormal];
    [settingButton addTarget:self action:@selector(goSetting) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingButton];
}

- (void)goSetting
{
    SettingViewController *setttingController = [[SettingViewController alloc] init];
    [self.navigationController pushViewController:setttingController animated:YES];
}

- (void)addBooks
{
    for (int ii = 0; ii < 1; ii++) {
        UIButton *bookButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        CGFloat buttonWidth = 0.0f;
        CGFloat buttonHeight = 0.0f;
        NSString *imageName;
        if ([Utility isPad]) {
            buttonWidth = 372 * 2.0f;
            buttonHeight = 465 * 2.0f;
            imageName = [NSString stringWithFormat:@"book%d_iPad.png",ii+1];
        } else {
            buttonWidth = 145 * 2.0f * _scale;
            buttonHeight = 219 * 2.0f * _scale;
            imageName = [NSString stringWithFormat:@"book%d.jpg",ii+1];
        }

        CGFloat originX = (CGRectGetWidth(self.view.bounds) - buttonWidth) / 2.0f;
        CGFloat originY = (CGRectGetHeight(self.view.bounds) - buttonHeight) / 2.0f;
        bookButton.frame = CGRectMake(originX, originY, buttonWidth, buttonHeight);

        [bookButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        [bookButton addTarget:self action:@selector(goMain:) forControlEvents:UIControlEventTouchUpInside];
        bookButton.tag = 100+ii;
        [self.view addSubview:bookButton];
    }
}

- (void)goMain:(UIButton *)button
{
    MainViewController *mainController = [[MainViewController alloc] initWithBookId:(int)button.tag-100];
    [self.navigationController pushViewController:mainController animated:YES];
}



@end
