//
//  WordDictationViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "WordDictationViewController.h"
#import "sqlite3.h"
#import "CKAlertView.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import <AVFoundation/AVFoundation.h>

static NSString* const kWordDictationViewControllerCellReuseId = @"kWordDictationViewControllerCellReuseId";

static NSString *NCEWordSoundPath(NSString *word)
{
    if (word.length == 0) {
        return nil;
    }

    NSArray<NSString *> *candidates = @[
        word,
        word.lowercaseString,
        word.capitalizedString,
    ];

    for (NSString *candidate in candidates) {
        NSString *soundName = [NSString stringWithFormat:@"data/words/wav/%@.wav", candidate];
        NSString *soundPath = [[NSBundle mainBundle] pathForResource:soundName ofType:nil];
        if (soundPath) {
            return soundPath;
        }
    }

    return nil;
}

@interface WordDictationViewController () <UITableViewDataSource, UITableViewDelegate, CKAlertViewDelegate, UITextFieldDelegate>
{
    int _bookId;
    NSMutableArray *_items;
    int _lessonId;
    
    int _currentIndex;
    
    int _correctAnswers;
    
    UILabel *_countLabel;
    UILabel *_scoreLabel;
    
    UILabel *_questionLabel;
    UITextField *_answerField;
    
    MBProgressHUD *_hud;
    
    AVAudioPlayer *_audioPlayer;
    UIButton *_volumeButton;
    
    //    CKAlertView *_alertView;
}

@property (nonatomic, strong) UITableView *tableView;

- (void)initData;
- (void)addTableView;

- (void)showWordInformation;
- (void)isAnswerWrong:(BOOL)wrong;

- (void)submit;
- (void)pass;
- (void)repeat;

@end

@implementation WordDictationViewController

- (id)initWithBookId:(int)bookId withLessonId:(int)lessonId
{
    self = [super init];
    if (self) {
        self.titleString = @"单词听写";
        _bookId = bookId;
        _lessonId = lessonId;
        
        [self initData];
        
        _currentIndex = 0;
        _correctAnswers = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [Utility nceBackgroundColor];
    
    [self addTableView];
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Configure for text only and offset down
    //    _hud.mode = MBProgressHUDModeText;
    _hud.label.text = @"loading...";
    _hud.removeFromSuperViewOnHide = YES;
    
    [self performSelector:@selector(showWordInformation) withObject:nil afterDelay:0.1f];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self submit];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.text = @"  ";
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    textField.text = @"  ";
    return NO;
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kWordDictationViewControllerCellReuseId
                                                            forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray *array = [cell.contentView subviews];
    for (UIView *view in array) {
        [view removeFromSuperview];
    }
    
    CGFloat width = tableView.frame.size.width;
    CGFloat height = tableView.frame.size.height/8;
    
    if (indexPath.row == 1) {
        CGFloat cardHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath] - 12.f;
        UIView *cardView = [Utility nceCardViewWithFrame:CGRectMake(14.f, 6.f, width - 28.f, cardHeight)];
        [cell.contentView addSubview:cardView];
        
        UILabel *hintLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 16.f, width - 64.f, 20.f)
                                                  text:@"听发音，写出英文单词"
                                                  font:[UIFont systemFontOfSize:13.f]
                                                 color:[Utility nceSecondaryTextColor]];
        [cardView addSubview:hintLabel];
        
        _questionLabel = [[UILabel alloc] initWithFrame:CGRectMake(18.f, 46.f, width - 64.f, cardHeight - 62.f)];
        _questionLabel.backgroundColor = [Utility nceBrandSoftColor];
        _questionLabel.layer.cornerRadius = 10.f;
        _questionLabel.layer.masksToBounds = YES;
        _questionLabel.font = [UIFont boldSystemFontOfSize:18.f];
        _questionLabel.textColor = [Utility nceTextColor];
        _questionLabel.textAlignment = NSTextAlignmentCenter;
        _questionLabel.numberOfLines = 0;
        [cardView addSubview:_questionLabel];
    } else if (indexPath.row > 1) {
        CGFloat cardHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath] - 12.f;
        UIView *cardView = [Utility nceCardViewWithFrame:CGRectMake(14.f, 6.f, width - 28.f, cardHeight)];
        [cell.contentView addSubview:cardView];
        
        _answerField = [[UITextField alloc] initWithFrame:CGRectMake(18.f, 18.f, width - 64.f, 44.f)];
        _answerField.backgroundColor = [UIColor colorWithRed:248/255.f green:250/255.f blue:247/255.f alpha:1.f];
        _answerField.font = [UIFont systemFontOfSize:16.f];
        _answerField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _answerField.delegate = self;
        _answerField.returnKeyType = UIReturnKeyDone;
        _answerField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _answerField.layer.cornerRadius = 10.f;
        _answerField.layer.masksToBounds = YES;
        _answerField.layer.borderWidth = 1;
        _answerField.layer.borderColor = [Utility nceLineColor].CGColor;
        _answerField.textColor = [Utility nceTextColor];
        _answerField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 12.f, 44.f)];
        _answerField.leftViewMode = UITextFieldViewModeAlways;
        _answerField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入答案" attributes:@{NSForegroundColorAttributeName:[Utility nceSecondaryTextColor],NSFontAttributeName:[UIFont systemFontOfSize:15.f]}];
        [cardView addSubview:_answerField];
        
        
        CGFloat buttonY = 78.f;
        CGFloat buttonWidth = (width - 92.f) / 3.f;
        UIButton *submitButton = [Utility nceTextButtonWithFrame:CGRectMake(18.f, buttonY, buttonWidth, 38.f)
                                                            text:@"提交"
                                                 backgroundColor:[Utility nceAccentColor]
                                                       textColor:[UIColor whiteColor]];
        [submitButton addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
        [cardView addSubview:submitButton];
        
        UIButton *passButton = [Utility nceTextButtonWithFrame:CGRectMake(27.f + buttonWidth, buttonY, buttonWidth, 38.f)
                                                          text:@"跳过"
                                               backgroundColor:[Utility nceBrandSoftColor]
                                                     textColor:[Utility nceBrandColor]];
        [passButton addTarget:self action:@selector(pass) forControlEvents:UIControlEventTouchUpInside];
        [cardView addSubview:passButton];
        
        _volumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _volumeButton.frame = CGRectMake(36.f + buttonWidth * 2.f, buttonY - 1.f, buttonWidth, 40.f);
        _volumeButton.backgroundColor = [UIColor whiteColor];
        _volumeButton.layer.cornerRadius = 20.f;
        [_volumeButton setImage:[UIImage imageNamed:@"volume_click"] forState:UIControlStateNormal];
        [_volumeButton addTarget:self action:@selector(repeat) forControlEvents:UIControlEventTouchUpInside];
        [cardView addSubview:_volumeButton];
    } else {
        UIView *cardView = [Utility nceCardViewWithFrame:CGRectMake(14.f, 6.f, width - 28.f, [self tableView:tableView heightForRowAtIndexPath:indexPath] - 12.f)];
        cardView.layer.shadowOpacity = 0.45f;
        [cell.contentView addSubview:cardView];
        
        _scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(18.f, 0, 120.f, CGRectGetHeight(cardView.frame))];
        _scoreLabel.backgroundColor = [UIColor clearColor];
        _scoreLabel.font = [UIFont boldSystemFontOfSize:16.f];
        _scoreLabel.textColor = [Utility nceTextColor];
        _scoreLabel.textAlignment = NSTextAlignmentLeft;
        [cardView addSubview:_scoreLabel];
        
        _countLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 154.f, 0, 120.f, CGRectGetHeight(cardView.frame))];
        _countLabel.backgroundColor = [UIColor clearColor];
        _countLabel.font = [UIFont boldSystemFontOfSize:16.f];
        _countLabel.textColor = [Utility nceSecondaryTextColor];
        _countLabel.textAlignment = NSTextAlignmentRight;
        [cardView addSubview:_countLabel];
    }
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) return 64.f;
    if (indexPath.row == 1) return 150.f;
    return 140.f;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view viewWithTag:1000+indexPath.row].backgroundColor = [UIColor clearColor];
}

#pragma mark -
#pragma mark CKAlertViewDelegate

- (void)alertView:(UIView *)alertView customClickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Private Methods

- (void)initData
{
    _items = [[NSMutableArray alloc] init];
    
    sqlite3 *database;
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
    
    if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
        //        NSLog(@"ok");
    }
    
    NSString *selectSql;
    if (_lessonId == 0) {
        selectSql = [NSString stringWithFormat:@"select `word_name`,`word_translation` from words where book_id=%d order by random() limit 20",_bookId+1];
    } else {
        selectSql = [NSString stringWithFormat:@"select `word_name`,`word_translation` from words where lesson_id=%d and book_id=%d order by random()",_lessonId,_bookId+1];
        
    }
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [selectSql UTF8String], -1, &statement, nil)==SQLITE_OK) {
        //        NSLog(@"select ok.");
    }
    
    while (sqlite3_step(statement)==SQLITE_ROW) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithCapacity:3];
        
        NSString *englishString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        [item setObject:englishString forKey:@"english"];
        
        NSString *chineseString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
        [item setObject:chineseString forKey:@"chinese"];
        
        [_items addObject:item];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (void)showResult
{
    CKAlertView *alertView = [[CKAlertView alloc] initWithTitle:@"测验结果"
                                                        message:[NSString stringWithFormat:@"一共 %d 单词，答对 %d 个", (int)_items.count, _correctAnswers]
                                                       delegate:self
                                              cancelButtonTitle:@"返回"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)showWordInformation
{
    if (_hud) [_hud hideAnimated:YES];
    
    if (_currentIndex >= _items.count) {
        [self showResult];
    } else {
        _scoreLabel.text = [NSString stringWithFormat:@"%d 分",_correctAnswers*100/(int)_items.count];
        _countLabel.text = [NSString stringWithFormat:@"%d / %d",_currentIndex+1, (int)_items.count];
        
        NSDictionary *item = [_items objectAtIndex:_currentIndex];
        _questionLabel.text = [item objectForKey:@"chinese"];
        
        NSString *soundPath = NCEWordSoundPath([item objectForKey:@"english"]);
        
        if (soundPath) {
            _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundPath] error:nil];
            [_audioPlayer play];
            
            _volumeButton.hidden = NO;
        } else {
            _volumeButton.hidden = YES;
        }
    }
}

- (void)addTableView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:view];
    
    CGRect tableViewFrame = [self getTableViewFrame];
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kWordDictationViewControllerCellReuseId];
    
    [self.view addSubview:self.tableView];
}

- (void)isAnswerWrong:(BOOL)wrong
{
    sqlite3 *database;
    //    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
    NSString *dbPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"NCE.db"];
    
    if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
        //        NSLog(@"ok");
    }
    
    NSString *updateSql = [NSString stringWithFormat:@"update words set `wrong`=%d where `word_name`='%@'",wrong,[[_items objectAtIndex:_currentIndex] objectForKey:@"english"]];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [updateSql UTF8String], -1, &statement, nil)==SQLITE_OK) {
        //        NSLog(@"select ok.");
    }
    
    if (sqlite3_step(statement) == SQLITE_DONE) {
        //        NSLog(@"done.");
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (void)submit
{
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Configure for text only and offset down
    HUD.mode = MBProgressHUDModeCustomView;
    HUD.removeFromSuperViewOnHide = YES;
    
    NSDictionary *item = [_items objectAtIndex:_currentIndex];
    NSString *answerString = [_answerField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([answerString isEqualToString:[item objectForKey:@"english"]]) {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"answer_correct"]];
        
        _correctAnswers++;
        
        [self isAnswerWrong:NO];
    } else {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"answer_incorrect"]];
        
        [self isAnswerWrong:YES];
    }
    
    [HUD hideAnimated:YES afterDelay:0.5f];
    
    [self pass];
}

- (void)pass
{
    _answerField.text = nil;
    
    [_answerField resignFirstResponder];
    
    _currentIndex++;
    [self showWordInformation];
}

- (void)repeat
{
    NSString *soundPath = NCEWordSoundPath([[_items objectAtIndex:_currentIndex] objectForKey:@"english"]);
    
    if (soundPath) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundPath] error:nil];
        [_audioPlayer play];
    }
}

@end
