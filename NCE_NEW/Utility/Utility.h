//
//  Utility.h
//  NCE2
//
//  Created by Lizi on 15/11/28.
//  Copyright (c) 2015年 PalmGame. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Utility : NSObject

+ (BOOL)isPad;
+ (BOOL)isPlus;
+ (BOOL)is35InchScreen;

+ (UIColor *)nceBrandColor;
+ (UIColor *)nceBrandSoftColor;
+ (UIColor *)nceAccentColor;
+ (UIColor *)nceBackgroundColor;
+ (UIColor *)nceTextColor;
+ (UIColor *)nceSecondaryTextColor;
+ (UIColor *)nceLineColor;
+ (UIView *)nceCardViewWithFrame:(CGRect)frame;
+ (UILabel *)nceLabelWithFrame:(CGRect)frame
                           text:(NSString *)text
                           font:(UIFont *)font
                          color:(UIColor *)color;
+ (UIButton *)nceTextButtonWithFrame:(CGRect)frame
                                text:(NSString *)text
                     backgroundColor:(UIColor *)backgroundColor
                            textColor:(UIColor *)textColor;
+ (UIButton *)nceCircleIconButtonWithFrame:(CGRect)frame
                                systemName:(NSString *)systemName
                              fallbackText:(NSString *)fallbackText
                                 iconColor:(UIColor *)iconColor
                           backgroundColor:(UIColor *)backgroundColor;
+ (NSString *)nceDatabasePath;
+ (NSDictionary *)nceStudyStats;
+ (NSSet *)nceCompletedLessonIds;
+ (void)nceSaveLastLessonId:(NSString *)lessonId lessonName:(NSString *)lessonName;
+ (void)nceMarkLessonIdCompleted:(NSString *)lessonId lessonName:(NSString *)lessonName;
+ (NSDictionary *)nceLastLesson;

@end
