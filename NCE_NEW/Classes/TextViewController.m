//
//  TextViewController.m
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "TextViewController.h"
#import "sqlite3.h"
#import <AVFoundation/AVFoundation.h>
#import "Utility.h"
#import "WordViewController.h"

static NSString* const kTextViewControllerCellReuseId = @"kTextViewControllerCellReuseId";

@interface TextViewController () <UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate>
{
    int _bookId;
    NSMutableArray *_items;
    NSDictionary *_lesson;
    
    BOOL _showChinese;
    
    NSMutableDictionary *_contentDictionary;
    
    AVAudioPlayer *_audioPlayer;
    int _currentIndex;    
    int _learnedCount;
    
    UIButton *_continueButton;
    UIButton *_pauseButton;
    
    UISlider *_contentSlider;
    UIButton *_circleButton;
    UILabel *_sentenceProgressLabel;
}

@property (nonatomic, strong) UITableView *tableView;

//@property (nonatomic, assign) NSInteger showTimes;

- (void)initData;
- (void)addTableView;
- (void)addRightButton;
- (void)showChinese:(UIButton *)button;
- (NSDictionary *)getContentItem:(NSUInteger)item;
- (UIView *)lessonHeaderViewWithWidth:(CGFloat)width;
- (void)goLessonWords;

@end

@implementation TextViewController

- (id)initWithBookId:(int)bookId withLesson:(NSDictionary *)lesson
{
    self = [super init];
    if (self) {
        _bookId = bookId;
        _lesson = lesson;
        
        NSArray *lessonArray = [[lesson objectForKey:@"name"] componentsSeparatedByString:@"－"];
        self.titleString = [NSString stringWithFormat:@"%@－%@",lessonArray[0], lessonArray[1]];
        
        [self initData];
        
        _showChinese = YES;
        
        _contentDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
        
        _currentIndex = 0;
        _learnedCount = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //self.showTimes = 1;
    [Utility nceSaveLastLessonId:[_lesson objectForKey:@"id"] lessonName:[_lesson objectForKey:@"name"]];
    
    if (![Utility isPad]) {
        self.bannerHeight = 20.f;
    }
    
    [self addTableView];
    
    [self addRightButton];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_currentIndex inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    
    [self addBottomView];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTextViewControllerCellReuseId
                                                            forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray *array = [cell.contentView subviews];
    for (UIView *view in array) {
        [view removeFromSuperview];
    }
    NSDictionary *contentItem = [self getContentItem:indexPath.row];
    CGFloat englishHeight = [[contentItem objectForKey:@"englishHeight"] floatValue];
    CGFloat chineseHeight = _showChinese ? [[contentItem objectForKey:@"chineseHeight"] floatValue] : 0.f;
    CGFloat cardHeight = englishHeight + chineseHeight + (_showChinese ? 24.f : 22.f);
    BOOL isCurrent = _currentIndex == indexPath.row;
    
    UIView *cardView = [[UIView alloc] initWithFrame:CGRectMake(14.f, 3.f, tableView.frame.size.width - 28.f, cardHeight)];
    cardView.backgroundColor = isCurrent ? [Utility nceBrandSoftColor] : [UIColor whiteColor];
    cardView.layer.cornerRadius = 10.f;
    [cell.contentView addSubview:cardView];
    
    UILabel *indexLabel = [Utility nceLabelWithFrame:CGRectMake(12.f, 9.f, 28.f, 20.f)
                                               text:[NSString stringWithFormat:@"%02ld", (long)indexPath.row + 1]
                                               font:[UIFont boldSystemFontOfSize:12.f]
                                              color:isCurrent ? [Utility nceBrandColor] : [Utility nceSecondaryTextColor]];
    [cardView addSubview:indexLabel];
    
    // english title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(46.f, 9.f, tableView.frame.size.width - 92.f, englishHeight)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:16.f];
    titleLabel.textColor = isCurrent ? [Utility nceBrandColor] : [Utility nceTextColor];
    titleLabel.text = [contentItem objectForKey:@"english"];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.numberOfLines = 0;
    titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    titleLabel.tag = 100+indexPath.row;
    [titleLabel sizeToFit];
    [cardView addSubview:titleLabel];
    
    // chinese title
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(46.f, CGRectGetMaxY(titleLabel.frame) + 4.f, tableView.frame.size.width - 92.f, [[contentItem objectForKey:@"chineseHeight"] floatValue])];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.font = [UIFont systemFontOfSize:14.f];
    subTitleLabel.textColor = isCurrent ? [Utility nceBrandColor] : [Utility nceSecondaryTextColor];
    subTitleLabel.text = [contentItem objectForKey:@"chinese"];
    subTitleLabel.textAlignment = NSTextAlignmentLeft;
    subTitleLabel.numberOfLines = 0;
    subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    subTitleLabel.tag = 10000+indexPath.row;
    [subTitleLabel sizeToFit];
    [cardView addSubview:subTitleLabel];
    if (!_showChinese) subTitleLabel.hidden = YES;;
    
    // show when the cell is selected
    UIView *maskView = [[UIView alloc] initWithFrame:cardView.frame];
    maskView.backgroundColor = [UIColor clearColor];
    maskView.tag = 1000+indexPath.row;
    [cell.contentView addSubview:maskView];
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *contentItem = [self getContentItem:indexPath.row];
    
    CGFloat contentHeight = [[contentItem objectForKey:@"englishHeight"] floatValue];
    if (_showChinese) {
        contentHeight += [[contentItem objectForKey:@"chineseHeight"] floatValue];
        contentHeight += 32.f;
    } else {
        contentHeight += 30.f;
    }
    
    return contentHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _currentIndex = (int)indexPath.row;
    
    [self play];
    [self.tableView reloadData];
    
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    _contentSlider.value = _currentIndex;
    _sentenceProgressLabel.text = [NSString stringWithFormat:@"%d / %d 句", _currentIndex + 1, (int)_items.count];
    
    _continueButton.hidden = YES;
    _pauseButton.hidden = NO;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (_currentIndex == _items.count-1 && _circleButton.selected) return;

    if (_currentIndex < _items.count-1) {
        _currentIndex++;
    } else {
        [Utility nceMarkLessonIdCompleted:[_lesson objectForKey:@"id"] lessonName:[_lesson objectForKey:@"name"]];
        _currentIndex = 0;
    }
    
    NSIndexPath *next = [NSIndexPath indexPathForRow:_currentIndex inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:next];
    
    _learnedCount++;
    if (_learnedCount == _items.count-1) {
        _learnedCount = -1;
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
        //                NSLog(@"ok");
    }
    
    int lessonId = [[_lesson objectForKey:@"id"] intValue];
    NSString *selectSql = [NSString stringWithFormat:@"select `name` from play_list_sentences where lesson_id=%d and book_id=%d order by order_id",lessonId,_bookId+1];
    sqlite3_stmt *statement;
    if (sqlite3_prepare_v2(database, [selectSql UTF8String], -1, &statement, nil)==SQLITE_OK) {
        //                NSLog(@"select ok.");
    }
    
    while (sqlite3_step(statement)==SQLITE_ROW) {
        NSString *nameString = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
        
        [_items addObject:nameString];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
}

- (void)addTableView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:view];
    
    self.viewType = ViewType_Lessons;
    CGRect tableViewFrame = [self getTableViewFrame];
    self.tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [self lessonHeaderViewWithWidth:CGRectGetWidth(tableViewFrame)];
    
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kTextViewControllerCellReuseId];
    
    [self.view addSubview:self.tableView];
}

- (void)addRightButton
{
    UIButton *showChineseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    showChineseButton.frame = CGRectMake(0, 0, 40, 40);
    showChineseButton.titleLabel.font = [UIFont systemFontOfSize:14.f];
    [showChineseButton setTitle:@"汉" forState:UIControlStateNormal];
    [showChineseButton setTitle:@"英" forState:UIControlStateSelected];
    [showChineseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [showChineseButton addTarget:self action:@selector(showChinese:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:showChineseButton];
}

- (void)showChinese:(UIButton *)button;
{
    button.selected = !button.selected;
    _showChinese = !_showChinese;
    [self.tableView reloadData];
}

- (NSDictionary *)getContentItem:(NSUInteger)item
{
    NSString *name = [_items objectAtIndex:item];
    
    NSDictionary *contentItem = [_contentDictionary objectForKey:name];
    if (!contentItem) {
        NSString *fileName = [NSString stringWithFormat:@"data/lessons/lrc/%@.lrc",name];
        NSString *filePath =  [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        NSString *contentString = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray *contentArray = [contentString componentsSeparatedByString:@"－"];
        NSString *english = contentArray.count > 0 ? [contentArray objectAtIndex:0] : @"";
        NSString *chinese = contentArray.count > 1 ? [contentArray objectAtIndex:1] : @"";
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:16.f], NSParagraphStyleAttributeName:paragraphStyle.copy};
        NSDictionary *attributes1 = @{NSFontAttributeName:[UIFont systemFontOfSize:14.f], NSParagraphStyleAttributeName:paragraphStyle.copy};
        
        CGSize content0Size = [english boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 92.f, MAXFLOAT)
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                        attributes:attributes
                                                                           context:nil].size;
        
        CGSize content1Size = [chinese boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 92.f, MAXFLOAT)
                                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                                        attributes:attributes1
                                                                           context:nil].size;
        
        contentItem = [[NSDictionary alloc] initWithObjectsAndKeys:english, @"english" ,chinese, @"chinese", @(ceilf(content0Size.height)), @"englishHeight", @(ceilf(content1Size.height)), @"chineseHeight", nil];
        
        [_contentDictionary setObject:contentItem forKey:name];
    }
    return contentItem;
}

- (void)play
{
    NSString *fileName = [NSString stringWithFormat:@"data/lessons/mp3/%@.mp3",[_items objectAtIndex:_currentIndex]];
    NSString *filePath =  [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:nil];
    _audioPlayer.delegate = self;
    [_audioPlayer prepareToPlay];
    [_audioPlayer play];
}

- (void)addBottomView
{
    CGFloat headerHight = [self getPlayViewHeight];
    
    CGFloat bgviewPosy = self.tableView.frame.origin.y + self.tableView.frame.size.height;
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, bgviewPosy, self.view.frame.size.width, headerHight)];
    backgroundView.backgroundColor = [UIColor whiteColor];
    backgroundView.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:0.08f].CGColor;
    backgroundView.layer.shadowOffset = CGSizeMake(0.f, -3.f);
    backgroundView.layer.shadowOpacity = 1.f;
    backgroundView.layer.shadowRadius = 10.f;
    
    [self.view addSubview:backgroundView];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 0.5f)];
    line.backgroundColor = [Utility nceLineColor];
    [backgroundView addSubview:line];
    
    _sentenceProgressLabel = [Utility nceLabelWithFrame:CGRectMake(16.f, 8.f, 72.f, 22.f)
                                                   text:[NSString stringWithFormat:@"%d / %d 句", _currentIndex + 1, (int)_items.count]
                                                   font:[UIFont systemFontOfSize:13.f]
                                                  color:[Utility nceSecondaryTextColor]];
    [backgroundView addSubview:_sentenceProgressLabel];
    
    UIButton *wordButton = [Utility nceTextButtonWithFrame:CGRectMake(16.f, 39.f, 88.f, 28.f)
                                                      text:@"本课单词"
                                           backgroundColor:[Utility nceBrandSoftColor]
                                                 textColor:[Utility nceBrandColor]];
    wordButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.f];
    [wordButton addTarget:self action:@selector(goLessonWords) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:wordButton];
    
    // prev
    UIButton *prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    prevButton.frame = CGRectMake(self.view.frame.size.width - 144.f, 36.f, 30.f, 30.f);
    [prevButton setImage:[UIImage imageNamed:@"prev_normal"] forState:UIControlStateNormal];
    [prevButton setImage:[UIImage imageNamed:@"prev_click"] forState:UIControlStateHighlighted];
    [prevButton addTarget:self action:@selector(prev) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:prevButton];
    
    // pause
    _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _pauseButton.frame = CGRectMake(self.view.frame.size.width - 97.f, 31.f, 40.f, 40.f);
    [_pauseButton setImage:[UIImage imageNamed:@"pause_normal"] forState:UIControlStateNormal];
    [_pauseButton setImage:[UIImage imageNamed:@"pause_click"] forState:UIControlStateHighlighted];
    [_pauseButton addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:_pauseButton];
    
    // continue
    _continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _continueButton.frame = CGRectMake(self.view.frame.size.width - 97.f, 31.f, 40.f, 40.f);
    [_continueButton setImage:[UIImage imageNamed:@"play_normal"] forState:UIControlStateNormal];
    [_continueButton setImage:[UIImage imageNamed:@"play_click"] forState:UIControlStateHighlighted];
    [_continueButton addTarget:self action:@selector(continue) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:_continueButton];
    _continueButton.hidden = YES;
    
    // next
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nextButton.frame = CGRectMake(self.view.frame.size.width - 42.f, 36.f, 30.f, 30.f);
    [nextButton setImage:[UIImage imageNamed:@"next_normal"] forState:UIControlStateNormal];
    [nextButton setImage:[UIImage imageNamed:@"next_click"] forState:UIControlStateHighlighted];
    [nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:nextButton];
    
    // init and add the content slider
    CGSize size = CGSizeMake(headerHight/9, headerHight/9);
    
    UIImage *leftImage = [UIImage imageNamed:@"progressBar_left"];
    UIImage *newLeftImage = [self OriginImage:leftImage scaleToSize:size];
    
    UIImage *rightImage = [UIImage imageNamed:@"progressBar_right"];
    UIImage *newRightImage = [self OriginImage:rightImage scaleToSize:size];
    
    UIImage *bgImage = [UIImage imageNamed:@"progressBar_bg"];
    UIImage *newbgImage = [self OriginImage:bgImage scaleToSize:size];
    
    CGFloat sliderX = 96.f;
    _contentSlider = [[UISlider alloc] initWithFrame:CGRectMake(sliderX, 15.f, self.view.frame.size.width - sliderX - 16.f, headerHight/9)];
    _contentSlider.maximumValue = (float)_items.count-1;
    _contentSlider.minimumValue = 0.f;
    _contentSlider.value = 0.f;
    [_contentSlider setMinimumTrackImage:[newLeftImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, newLeftImage.size.height*0.4, 0, newLeftImage.size.height*0.4)] forState:UIControlStateNormal];
    [_contentSlider setMaximumTrackImage:[newbgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, newbgImage.size.height*0.4, 0, newbgImage.size.height*0.4)] forState:UIControlStateNormal];
    [_contentSlider setThumbImage:newRightImage forState:UIControlStateNormal];
    [_contentSlider setThumbImage:newRightImage forState:UIControlStateHighlighted];
    [_contentSlider addTarget:self action:@selector(gotoContentItem:) forControlEvents:UIControlEventValueChanged];
    [backgroundView addSubview:_contentSlider];
    
    // init playing circle setting
    _circleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _circleButton.frame = CGRectMake(116.f, 37.f, 30.f, 30.f);
    [_circleButton setImage:[UIImage imageNamed:@"playing_circle_btn"] forState:UIControlStateNormal];
    [_circleButton setImage:[UIImage imageNamed:@"playing_single_btn"] forState:UIControlStateSelected];
    [_circleButton addTarget:self action:@selector(circleOrSingle:) forControlEvents:UIControlEventTouchUpInside];
    [backgroundView addSubview:_circleButton];
}

-(UIImage *)OriginImage:(UIImage *)image scaleToSize:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (void)prev
{
    if (_currentIndex > 0) {
        NSIndexPath *last = [NSIndexPath indexPathForRow:_currentIndex-1 inSection:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:last];
    }
}

- (void)pause
{
    _pauseButton.hidden = YES;
    _continueButton.hidden = NO;
    
    [_audioPlayer pause];
}

- (void)continue
{
    _continueButton.hidden = YES;
    _pauseButton.hidden = NO;
    
    [_audioPlayer play];
}

- (void)next
{
    if (_currentIndex < _items.count - 1) {
        NSIndexPath *last = [NSIndexPath indexPathForRow:_currentIndex+1 inSection:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:last];
    }
}

- (void)gotoContentItem:(id)sender
{
    UISlider *slider = (UISlider*)sender;
    NSIndexPath *index = [NSIndexPath indexPathForRow:slider.value inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:index];
}

- (void)circleOrSingle:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
}

- (UIView *)lessonHeaderViewWithWidth:(CGFloat)width
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, width, 96.f)];
    headerView.backgroundColor = [UIColor clearColor];
    
    NSArray *lessonArray = [[_lesson objectForKey:@"name"] componentsSeparatedByString:@"－"];
    NSString *lessonNo = lessonArray.count > 0 ? [lessonArray objectAtIndex:0] : @"Lesson";
    NSString *englishTitle = lessonArray.count > 1 ? [lessonArray objectAtIndex:1] : @"";
    NSString *chineseTitle = lessonArray.count > 2 ? [lessonArray objectAtIndex:2] : @"";
    
    UIView *cardView = [Utility nceCardViewWithFrame:CGRectMake(14.f, 10.f, width - 28.f, 74.f)];
    [headerView addSubview:cardView];
    
    UILabel *lessonLabel = [Utility nceLabelWithFrame:CGRectMake(16.f, 12.f, 72.f, 26.f)
                                                text:lessonNo
                                                font:[UIFont boldSystemFontOfSize:13.f]
                                               color:[Utility nceBrandColor]];
    lessonLabel.textAlignment = NSTextAlignmentCenter;
    lessonLabel.backgroundColor = [Utility nceBrandSoftColor];
    lessonLabel.layer.cornerRadius = 13.f;
    lessonLabel.layer.masksToBounds = YES;
    [cardView addSubview:lessonLabel];
    
    UILabel *titleLabel = [Utility nceLabelWithFrame:CGRectMake(104.f, 11.f, width - 150.f, 26.f)
                                               text:englishTitle
                                               font:[UIFont boldSystemFontOfSize:18.f]
                                              color:[Utility nceTextColor]];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.78f;
    [cardView addSubview:titleLabel];
    
    UILabel *subTitleLabel = [Utility nceLabelWithFrame:CGRectMake(104.f, 40.f, width - 150.f, 22.f)
                                                  text:chineseTitle
                                                  font:[UIFont systemFontOfSize:14.f]
                                                 color:[Utility nceSecondaryTextColor]];
    [cardView addSubview:subTitleLabel];
    
    return headerView;
}

- (void)goLessonWords
{
    WordViewController *wordController = [[WordViewController alloc] initWithBookId:_bookId
                                                                         withLesson:_lesson
                                                                       withFunction:1];
    wordController.titleString = @"单词训练";
    [self.navigationController pushViewController:wordController animated:YES];
}

@end
