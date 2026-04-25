//
//  WordViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "WordViewController.h"
#import "sqlite3.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "Utility.h"

static NSString *NCEWordAssetPath(NSString *folder, NSString *word, NSString *fileExtension)
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
        NSString *assetName = [NSString stringWithFormat:@"data/words/%@/%@.%@", folder, candidate, fileExtension];
        NSString *assetPath = [[NSBundle mainBundle] pathForResource:assetName ofType:nil];
        if (assetPath) {
            return assetPath;
        }
    }

    return nil;
}

@interface WordViewController () <AVAudioPlayerDelegate, UIAlertViewDelegate>
{
    int _bookId;
    NSMutableArray *_items;
    NSDictionary *_lesson;
    int _function; // 1：单词学习 2：词义回想 3：单词回想
    
    AVAudioPlayer *_audioPlayer;
    int _currentIndex;
    
    UIButton *_continueButton;
    UIButton *_pauseButton;
    
    UILabel *_englishLabel;
    UILabel *_countLabel;
    
    UIView *_chineseView;
    UILabel *_chineseLabel;
    UIImageView *_wordImageView;
}

- (void)initData;
- (void)willShowWordInformation;
- (void)showWordInformation;
- (void)addBottomView:(CGFloat)startPosy;

- (void)prev;
- (void)pause;
- (void)next;

- (void)signWord:(id)sender;
- (void)showEnglish;
- (void)showChinese;
- (void)repeat;

@end

@implementation WordViewController

- (id)initWithBookId:(int)bookId withLesson:(NSDictionary *)lesson withFunction:(int)function
{
    self = [super init];
    if (self) {
        _bookId = bookId;
        _lesson = lesson;
        _function = function;
        [self initData];
        
        _currentIndex = 0;
    }
    return self;
}

- (id)initWithData:(NSArray *)data withIndex:(int)index
{
    self = [super init];
    if (self) {
        _items = [[NSMutableArray alloc] initWithArray:data];
        _currentIndex = index;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [Utility nceBackgroundColor];
    if (self.titleString.length == 0) {
        self.navigationItem.title = @"单词训练";
    }
    
    CGFloat headerPosy = [self getHeaderPosY] + 8.f;
    CGFloat contentWidth = self.view.frame.size.width - 28.f;
    
    NSArray *modes = @[@"学习", @"回想", @"听写"];
    UIView *modeView = [Utility nceCardViewWithFrame:CGRectMake(14.f, headerPosy, contentWidth, 44.f)];
    modeView.layer.shadowOpacity = 0.4f;
    [self.view addSubview:modeView];
    for (int ii = 0; ii < modes.count; ii++) {
        CGFloat itemW = contentWidth / 3.f;
        UILabel *modeLabel = [Utility nceLabelWithFrame:CGRectMake(ii * itemW + 4.f, 5.f, itemW - 8.f, 34.f)
                                                  text:modes[ii]
                                                  font:[UIFont boldSystemFontOfSize:14.f]
                                                 color:ii == MAX(0, _function - 1) ? [UIColor whiteColor] : [Utility nceSecondaryTextColor]];
        modeLabel.textAlignment = NSTextAlignmentCenter;
        modeLabel.backgroundColor = ii == MAX(0, _function - 1) ? [Utility nceBrandColor] : [UIColor clearColor];
        modeLabel.layer.cornerRadius = 17.f;
        modeLabel.layer.masksToBounds = YES;
        [modeView addSubview:modeLabel];
    }
    
    UIView *wordCard = [Utility nceCardViewWithFrame:CGRectMake(14.f, CGRectGetMaxY(modeView.frame) + 12.f, contentWidth, 236.f)];
    [self.view addSubview:wordCard];
    
    UILabel *contextLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 16.f, contentWidth - 36.f, 20.f)
                                                 text:@"来自第一册课程"
                                                 font:[UIFont systemFontOfSize:13.f]
                                                color:[Utility nceSecondaryTextColor]];
    [wordCard addSubview:contextLabel];
    
    _englishLabel = [[UILabel alloc] initWithFrame:CGRectMake(18.f, 44.f, contentWidth - 36.f, 48.f)];
    _englishLabel.backgroundColor = [UIColor clearColor];
    _englishLabel.font = [UIFont boldSystemFontOfSize:34.f];
    _englishLabel.textColor = [Utility nceTextColor];
    _englishLabel.textAlignment = NSTextAlignmentCenter;
    _englishLabel.adjustsFontSizeToFitWidth = YES;
    _englishLabel.minimumScaleFactor = 0.62f;
    [wordCard addSubview:_englishLabel];
    
    _chineseView = [[UIView alloc] initWithFrame:CGRectMake(18.f, 106.f, contentWidth - 36.f, 92.f)];
    _chineseView.backgroundColor = [UIColor colorWithRed:255/255.f green:248/255.f blue:243/255.f alpha:1.f];
    _chineseView.layer.cornerRadius = 10.f;
    [wordCard addSubview:_chineseView];
    
    _chineseLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 8.f, CGRectGetWidth(_chineseView.frame) - 32.f, 76.f)];
    _chineseLabel.backgroundColor = [UIColor clearColor];
    _chineseLabel.font = [UIFont systemFontOfSize:17.f];
    _chineseLabel.textColor = [Utility nceTextColor];
    _chineseLabel.textAlignment = NSTextAlignmentCenter;
    _chineseLabel.numberOfLines = 0;
    _chineseLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_chineseView addSubview:_chineseLabel];
    
    _wordImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [_chineseView addSubview:_wordImageView];
    UILabel *progressLabel = [Utility nceLabelWithFrame:CGRectMake(18.f, 207.f, contentWidth - 36.f, 18.f)
                                                  text:@"第一册单词进度"
                                                  font:[UIFont systemFontOfSize:12.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [wordCard addSubview:progressLabel];
    
    CGFloat startPosy = CGRectGetMaxY(wordCard.frame) + 10.f;
    [self addBottomView:startPosy];
    
    [self showWordInformation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (_currentIndex < _items.count-1) {
        [self performSelector:@selector(next) withObject:nil afterDelay:5];
    }
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
    
    int lessonId = [[_lesson objectForKey:@"id"] intValue];
    NSString *selectSql = [NSString stringWithFormat:@"select `word_name`,`word_translation`,`lesson_id` from words where lesson_id=%d and book_id=%d order by order_id",lessonId,_bookId+1];
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
        
        NSString *lessonId = [NSString stringWithFormat:@"%d",sqlite3_column_int(statement, 2)];
        [item setObject:lessonId forKey:@"lesson_id"];
        
        [_items addObject:item];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (void)showWordInformation
{
    NSDictionary *item = [_items objectAtIndex:_currentIndex];
    
    if (_function != 3) _englishLabel.text = [item objectForKey:@"english"];
    else _englishLabel.text = nil;
    
    
    _chineseLabel.text = [item objectForKey:@"chinese"];
    
    NSString *imagePath = NCEWordAssetPath(@"jpg", [item objectForKey:@"english"], @"jpg");
    if (imagePath) {
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        CGFloat imageHeight = CGRectGetHeight(_chineseView.bounds) - 24.f;
        CGFloat imageWidth = image.size.height > 0 ? image.size.width * imageHeight / image.size.height : 0.f;
        imageWidth = MIN(imageWidth, CGRectGetWidth(_chineseView.bounds) * 0.32f);
        _wordImageView.frame = CGRectMake(CGRectGetWidth(_chineseView.bounds) - imageWidth - 10.f, 12.f, imageWidth, imageHeight);
        _wordImageView.image = image;
        _wordImageView.layer.cornerRadius = 8.f;
        _wordImageView.layer.masksToBounds = YES;
        _chineseLabel.frame = CGRectMake(16.f, 10.f, CGRectGetWidth(_chineseView.bounds) - imageWidth - 42.f, CGRectGetHeight(_chineseView.bounds) - 20.f);
    } else {
        _wordImageView.image = nil;
        _chineseLabel.frame = CGRectMake(16.f, 10.f, CGRectGetWidth(_chineseView.bounds) - 32.f, CGRectGetHeight(_chineseView.bounds) - 20.f);
    }
    
    if (_function == 2) {
        _chineseLabel.hidden = YES;
        _wordImageView.hidden = YES;
    }
    
    _countLabel.text = [NSString stringWithFormat:@"%d/%d", _currentIndex+1, (int)_items.count];
    
    NSString *soundPath = NCEWordAssetPath(@"wav", [item objectForKey:@"english"], @"wav");
    
    if (soundPath) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundPath] error:nil];
        _audioPlayer.delegate = self;
        [_audioPlayer play];
    }
    
    if (_function) {
        UILabel *lessonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 40)];
        lessonLabel.font = [UIFont systemFontOfSize:14.f];
        lessonLabel.text = [NSString stringWithFormat:@"第%@课",[item objectForKey:@"lesson_id"]];
        lessonLabel.textColor = [UIColor whiteColor];
        lessonLabel.textAlignment = NSTextAlignmentRight;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:lessonLabel];
    }
    
}

- (void)addBottomView:(CGFloat)startPosy
{
    CGFloat bgviewHeight = self.view.frame.size.height-startPosy-self.bannerHeight;
    if ([self getHeaderPosY] <= 0) { // iPad适配
        bgviewHeight = bgviewHeight - [self getDefaultBottomHeight];
    }

    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(14.f, startPosy, self.view.frame.size.width - 28.f, bgviewHeight)];
    backgroundView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:backgroundView];
    
    UIView *statusCard = [Utility nceCardViewWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(backgroundView.frame), 88.f)];
    [backgroundView addSubview:statusCard];
    
    UILabel *hintLabel = [Utility nceLabelWithFrame:CGRectMake(16.f, 12.f, CGRectGetWidth(statusCard.frame) - 32.f, 20.f)
                                              text:@"熟悉度标记"
                                              font:[UIFont boldSystemFontOfSize:15.f]
                                             color:[Utility nceTextColor]];
    [statusCard addSubview:hintLabel];
    
    CGFloat statusButtonWidth = (CGRectGetWidth(statusCard.frame) - 48.f) / 3.f;
    UIButton *strangeButton = [Utility nceTextButtonWithFrame:CGRectMake(16.f, 42.f, statusButtonWidth, 34.f)
                                                         text:@"陌生"
                                              backgroundColor:[UIColor colorWithRed:255/255.f green:238/255.f blue:233/255.f alpha:1.f]
                                                    textColor:[Utility nceAccentColor]];
    [strangeButton addTarget:self action:@selector(signWord:) forControlEvents:UIControlEventTouchUpInside];
    strangeButton.tag = 101;
    [statusCard addSubview:strangeButton];
    
    UIButton *vagueButton = [Utility nceTextButtonWithFrame:CGRectMake(24.f + statusButtonWidth, 42.f, statusButtonWidth, 34.f)
                                                       text:@"模糊"
                                            backgroundColor:[UIColor colorWithRed:255/255.f green:247/255.f blue:225/255.f alpha:1.f]
                                                  textColor:[UIColor colorWithRed:213/255.f green:148/255.f blue:45/255.f alpha:1.f]];
    [vagueButton addTarget:self action:@selector(signWord:) forControlEvents:UIControlEventTouchUpInside];
    vagueButton.tag = 103;
    [statusCard addSubview:vagueButton];
    
    UIButton *familiarButton = [Utility nceTextButtonWithFrame:CGRectMake(32.f + statusButtonWidth * 2.f, 42.f, statusButtonWidth, 34.f)
                                                          text:@"认识"
                                               backgroundColor:[Utility nceBrandSoftColor]
                                                     textColor:[Utility nceBrandColor]];
    [familiarButton addTarget:self action:@selector(signWord:) forControlEvents:UIControlEventTouchUpInside];
    familiarButton.tag = 102;
    [statusCard addSubview:familiarButton];
    
    CGFloat actionY = CGRectGetMaxY(statusCard.frame) + 12.f;
    CGFloat actionWidth = CGRectGetWidth(backgroundView.frame);
    CGFloat volumeX = 0.f;
    CGFloat volumeWidth = actionWidth;
    if (_function == 3) {
        volumeX = actionWidth / 2.f + 5.f;
        volumeWidth = actionWidth / 2.f - 5.f;
        UIButton *originButton = [Utility nceTextButtonWithFrame:CGRectMake(0.f, actionY, actionWidth / 2.f - 5.f, 36.f)
                                                            text:@"显示英文"
                                                 backgroundColor:[UIColor whiteColor]
                                                       textColor:[Utility nceTextColor]];
        [originButton addTarget:self action:@selector(showEnglish) forControlEvents:UIControlEventTouchUpInside];
        [backgroundView addSubview:originButton];
    }
    
    if (_function == 2) {
        volumeX = actionWidth / 2.f + 5.f;
        volumeWidth = actionWidth / 2.f - 5.f;
        UIButton *translateButton = [Utility nceTextButtonWithFrame:CGRectMake(0.f, actionY, actionWidth / 2.f - 5.f, 36.f)
                                                               text:@"显示释义"
                                                    backgroundColor:[UIColor whiteColor]
                                                          textColor:[Utility nceTextColor]];
        [translateButton addTarget:self action:@selector(showChinese) forControlEvents:UIControlEventTouchUpInside];
        [backgroundView addSubview:translateButton];
    }
    
    UIButton *volumeButton = [Utility nceTextButtonWithFrame:CGRectMake(volumeX, actionY, volumeWidth, 36.f)
                                                        text:@"播放发音"
                                             backgroundColor:[UIColor whiteColor]
                                                   textColor:[Utility nceBrandColor]];
    [volumeButton addTarget:self action:@selector(repeat) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:volumeButton];
    
    CGFloat yy = actionY + 52.f;
    UIView *controlCard = [Utility nceCardViewWithFrame:CGRectMake(0.f, yy, CGRectGetWidth(backgroundView.frame), 68.f)];
    [backgroundView addSubview:controlCard];
    
    // count
    _countLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 0.f, 90.f, 68.f)];
    _countLabel.backgroundColor = [UIColor clearColor];
    _countLabel.font = [UIFont systemFontOfSize:16];
    _countLabel.textColor = [Utility nceSecondaryTextColor];
    _countLabel.textAlignment = NSTextAlignmentLeft;
    [controlCard addSubview:_countLabel];
    
    // prev
    UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    prevButton.frame = CGRectMake(CGRectGetWidth(controlCard.frame)-192, 14, 40, 40);
    [prevButton setImage:[UIImage imageNamed:@"prev_normal"] forState:UIControlStateNormal];
    [prevButton setImage:[UIImage imageNamed:@"prev_click"] forState:UIControlStateHighlighted];
    [prevButton addTarget:self action:@selector(prev) forControlEvents:UIControlEventTouchUpInside];
    [controlCard addSubview:prevButton];
    
    // pause
    _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _pauseButton.frame = CGRectMake(CGRectGetWidth(controlCard.frame)-130, 9, 50, 50);
    [_pauseButton setImage:[UIImage imageNamed:@"pause_normal"] forState:UIControlStateNormal];
    [_pauseButton setImage:[UIImage imageNamed:@"pause_click"] forState:UIControlStateHighlighted];
    [_pauseButton addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [controlCard addSubview:_pauseButton];
    
    // continue
    _continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _continueButton.frame = CGRectMake(CGRectGetWidth(controlCard.frame)-130, 9, 50, 50);
    [_continueButton setImage:[UIImage imageNamed:@"play_normal"] forState:UIControlStateNormal];
    [_continueButton setImage:[UIImage imageNamed:@"play_click"] forState:UIControlStateHighlighted];
    [_continueButton addTarget:self action:@selector(continue) forControlEvents:UIControlEventTouchUpInside];
    [controlCard addSubview:_continueButton];
    _continueButton.hidden = YES;
    
    // next
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = CGRectMake(CGRectGetWidth(controlCard.frame)-58, 14, 40, 40);
    [nextButton setImage:[UIImage imageNamed:@"next_normal"] forState:UIControlStateNormal];
    [nextButton setImage:[UIImage imageNamed:@"next_click"] forState:UIControlStateHighlighted];
    [nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [controlCard addSubview:nextButton];
}

- (void)prev
{
    [self willShowWordInformation];
    
    if (_currentIndex > 0) {
        _currentIndex --;
        [self showWordInformation];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        // Configure for text only and offset down
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"已是第一个";
        hud.removeFromSuperViewOnHide = YES;
        
        [hud hideAnimated:YES afterDelay:0.75f];
    }
}

- (void)pause
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
    
    _pauseButton.hidden = YES;
    _continueButton.hidden = NO;
    
    [_audioPlayer pause];
}

- (void)continue
{
    [self willShowWordInformation];
    
    [_audioPlayer play];
}

- (void)next
{
    [self willShowWordInformation];
    
    if (_currentIndex < _items.count - 1) {
        _currentIndex++;
        [self showWordInformation];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        // Configure for text only and offset down
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"已是最后一个";
        hud.removeFromSuperViewOnHide = YES;
        
        [hud hideAnimated:YES afterDelay:0.75f];
    }
}

- (void)willShowWordInformation
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
    _continueButton.hidden = YES;
    _pauseButton.hidden = NO;
}

- (void)signWord:(id)sender
{
    UIButton *button = (UIButton *)sender;
    int status = (int)button.tag-100;
    
    sqlite3 *database;
    //    NSString *dbPath = [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
    NSString *dbPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"NCE.db"];
    
    if (sqlite3_open([dbPath UTF8String], &database) == SQLITE_OK) {
        //        NSLog(@"ok");
    }
    
    NSString *updateSql = [NSString stringWithFormat:@"update words set `word_status`=%d where `word_name`='%@'",status,[[_items objectAtIndex:_currentIndex] objectForKey:@"english"]];
    
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [updateSql UTF8String], -1, &statement, nil)==SQLITE_OK) {
        //        NSLog(@"select ok.");
    }
    
    if (sqlite3_step(statement) == SQLITE_DONE) {
        //        NSLog(@"done.");
    } else {
        //        NSLog(@"%@, %s",updateSql, sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
}

- (void)showEnglish
{
    if (_englishLabel.text) _englishLabel.text = nil;
    else _englishLabel.text = [[_items objectAtIndex:_currentIndex] objectForKey:@"english"];
}

- (void)showChinese
{
    _chineseLabel.hidden = !_chineseLabel.hidden;
    _wordImageView.hidden = !_wordImageView.hidden;
}

- (void)repeat
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(next) object:nil];
    
    NSString *soundPath = NCEWordAssetPath(@"wav", [[_items objectAtIndex:_currentIndex] objectForKey:@"english"], @"wav");
    
    if (soundPath) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:soundPath] error:nil];
        _audioPlayer.delegate = self;
        [_audioPlayer play];
    }
}

@end
