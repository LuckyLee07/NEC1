//
//  WordViewController.h
//  NCE1
//
//  Created by Lizi on 02/14/26.
//  Copyright © 2026年 FancyGame. All rights reserved.
//

#import "BaseViewController.h"

@interface WordViewController : BaseViewController

- (id)initWithBookId:(int)bookId withLesson:(NSDictionary *)lesson withFunction:(int)function;

- (id)initWithData:(NSArray *)data withIndex:(int)index;

@end
