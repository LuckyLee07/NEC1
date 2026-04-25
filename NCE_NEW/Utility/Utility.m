//
//  Utility.m
//  NCE2
//
//  Created by Lizi on 15/11/28.
//  Copyright (c) 2015年 PalmGame. All rights reserved.
//

#import "Utility.h"
#import "sqlite3.h"

static NSString * const kNCECompletedLessonIdsKey = @"NCECompletedLessonIds";
static NSString * const kNCELastLessonIdKey = @"NCELastLessonId";
static NSString * const kNCELastLessonNameKey = @"NCELastLessonName";

@implementation Utility

+ (BOOL)isPad
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) return NO;
    return YES;
}

+ (BOOL)isPlus
{
    CGSize screensize = [[UIScreen mainScreen] bounds].size;
    if (screensize.height >= 736) return YES;
    return NO;
}

+ (BOOL)is35InchScreen
{
    CGSize screensize = [[UIScreen mainScreen] bounds].size;
    if (screensize.height >= 568) return NO;
    return YES;
}

+ (UIColor *)nceBrandColor
{
    return [UIColor colorWithRed:73/255.f green:198/255.f blue:165/255.f alpha:1.f];
}

+ (UIColor *)nceBrandSoftColor
{
    return [UIColor colorWithRed:224/255.f green:248/255.f blue:241/255.f alpha:1.f];
}

+ (UIColor *)nceAccentColor
{
    return [UIColor colorWithRed:255/255.f green:137/255.f blue:100/255.f alpha:1.f];
}

+ (UIColor *)nceBackgroundColor
{
    return [UIColor colorWithRed:248/255.f green:250/255.f blue:247/255.f alpha:1.f];
}

+ (UIColor *)nceTextColor
{
    return [UIColor colorWithRed:36/255.f green:48/255.f blue:52/255.f alpha:1.f];
}

+ (UIColor *)nceSecondaryTextColor
{
    return [UIColor colorWithRed:118/255.f green:132/255.f blue:137/255.f alpha:1.f];
}

+ (UIColor *)nceLineColor
{
    return [UIColor colorWithRed:226/255.f green:235/255.f blue:232/255.f alpha:1.f];
}

+ (CGFloat)nceReadableContentWidthForViewWidth:(CGFloat)viewWidth
{
    CGFloat horizontalInset = [self isPad] ? 48.f : 18.f;
    CGFloat contentWidth = MAX(0.f, viewWidth - horizontalInset * 2.f);
    if ([self isPad] && viewWidth >= 700.f) {
        contentWidth = MIN(contentWidth, 840.f);
    }
    return contentWidth;
}

+ (CGFloat)nceReadableContentXForViewWidth:(CGFloat)viewWidth
{
    CGFloat contentWidth = [self nceReadableContentWidthForViewWidth:viewWidth];
    return floorf((viewWidth - contentWidth) / 2.f);
}

+ (UIView *)nceCardViewWithFrame:(CGRect)frame
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor whiteColor];
    view.layer.cornerRadius = 10.f;
    view.layer.shadowColor = [UIColor colorWithWhite:0.f alpha:0.08f].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.f, 4.f);
    view.layer.shadowOpacity = 1.f;
    view.layer.shadowRadius = 12.f;
    return view;
}

+ (UILabel *)nceLabelWithFrame:(CGRect)frame
                           text:(NSString *)text
                           font:(UIFont *)font
                          color:(UIColor *)color
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.text = text;
    label.font = font;
    label.textColor = color;
    return label;
}

+ (UIButton *)nceTextButtonWithFrame:(CGRect)frame
                                text:(NSString *)text
                     backgroundColor:(UIColor *)backgroundColor
                            textColor:(UIColor *)textColor
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    button.backgroundColor = backgroundColor;
    button.layer.cornerRadius = CGRectGetHeight(frame) / 2.f;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
    [button setTitle:text forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    return button;
}

+ (UIButton *)nceCircleIconButtonWithFrame:(CGRect)frame
                                systemName:(NSString *)systemName
                              fallbackText:(NSString *)fallbackText
                                 iconColor:(UIColor *)iconColor
                           backgroundColor:(UIColor *)backgroundColor
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    button.backgroundColor = backgroundColor ?: [UIColor whiteColor];
    button.layer.cornerRadius = CGRectGetHeight(frame) / 2.f;
    button.layer.borderWidth = 0.5f;
    button.layer.borderColor = [[UIColor colorWithWhite:1.f alpha:0.78f] CGColor];
    button.clipsToBounds = YES;
    
    UIColor *tintColor = iconColor ?: [self nceBrandColor];
    if (@available(iOS 13.0, *)) {
        UIImage *iconImage = systemName.length > 0 ? [UIImage systemImageNamed:systemName] : nil;
        if (iconImage) {
            CGFloat iconSide = MIN(CGRectGetWidth(frame), CGRectGetHeight(frame)) * 0.54f;
            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame) - iconSide) / 2.f,
                                                                                  (CGRectGetHeight(frame) - iconSide) / 2.f,
                                                                                  iconSide,
                                                                                  iconSide)];
            iconView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            iconView.tintColor = tintColor;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.userInteractionEnabled = NO;
            [button addSubview:iconView];
            return button;
        }
    }
    
    [button setTitle:fallbackText forState:UIControlStateNormal];
    [button setTitleColor:tintColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:17.f];
    return button;
}

+ (NSString *)nceDatabasePath
{
    NSString *documentPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"NCE.db"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        return documentPath;
    }
    return [[NSBundle mainBundle] pathForResource:@"data/NCE" ofType:@"db"];
}

+ (NSInteger)nceIntegerForSQL:(NSString *)sql
{
    sqlite3 *database = NULL;
    NSInteger value = 0;
    NSString *dbPath = [self nceDatabasePath];
    if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK) {
        if (database) sqlite3_close(database);
        return value;
    }
    
    sqlite3_stmt *statement = NULL;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, nil) == SQLITE_OK &&
        sqlite3_step(statement) == SQLITE_ROW) {
        value = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
    return value;
}

+ (NSDictionary *)nceStudyStats
{
    NSInteger totalLessons = [self nceIntegerForSQL:@"select count(*) from play_list_lessons where book_id=1"];
    NSInteger totalWords = [self nceIntegerForSQL:@"select count(*) from words where book_id=1"];
    NSInteger masteredWords = [self nceIntegerForSQL:@"select count(*) from words where book_id=1 and word_status=2"];
    NSInteger familiarWords = [self nceIntegerForSQL:@"select count(*) from words where book_id=1 and word_status in (2,3)"];
    NSInteger wordBookCount = [self nceIntegerForSQL:@"select count(*) from word_book"];
    NSInteger wrongWords = [self nceIntegerForSQL:@"select count(*) from words where book_id=1 and wrong=1"];
    NSInteger completedLessons = [self nceCompletedLessonIds].count;
    
    return @{@"totalLessons": @(totalLessons),
             @"completedLessons": @(completedLessons),
             @"totalWords": @(totalWords),
             @"masteredWords": @(masteredWords),
             @"familiarWords": @(familiarWords),
             @"wordBookCount": @(wordBookCount),
             @"wrongWords": @(wrongWords)};
}

+ (NSSet *)nceCompletedLessonIds
{
    NSArray *lessonIds = [[NSUserDefaults standardUserDefaults] objectForKey:kNCECompletedLessonIdsKey];
    if (![lessonIds isKindOfClass:[NSArray class]]) {
        return [NSSet set];
    }
    return [NSSet setWithArray:lessonIds];
}

+ (void)nceSaveLastLessonId:(NSString *)lessonId lessonName:(NSString *)lessonName
{
    if (lessonId.length == 0) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lessonId forKey:kNCELastLessonIdKey];
    if (lessonName.length > 0) {
        [defaults setObject:lessonName forKey:kNCELastLessonNameKey];
    }
    [defaults synchronize];
}

+ (void)nceMarkLessonIdCompleted:(NSString *)lessonId lessonName:(NSString *)lessonName
{
    if (lessonId.length == 0) {
        return;
    }
    
    NSMutableSet *completedLessonIds = [[self nceCompletedLessonIds] mutableCopy];
    [completedLessonIds addObject:lessonId];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:completedLessonIds.allObjects forKey:kNCECompletedLessonIdsKey];
    [defaults synchronize];
    [self nceSaveLastLessonId:lessonId lessonName:lessonName];
}

+ (NSDictionary *)nceLastLesson
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lessonId = [defaults objectForKey:kNCELastLessonIdKey];
    NSString *lessonName = [defaults objectForKey:kNCELastLessonNameKey];
    if (lessonId.length == 0 || lessonName.length == 0) {
        return nil;
    }
    return @{@"id": lessonId, @"name": lessonName};
}

@end
