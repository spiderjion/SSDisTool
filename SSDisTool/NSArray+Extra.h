//
//  NSArray+Extra.h
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Extra)

- (id)safeGetObjectAtIndex:(NSInteger)index;

- (BOOL)containsString:(NSString *)string;

@end
