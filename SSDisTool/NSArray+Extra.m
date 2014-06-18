//
//  NSArray+Extra.m
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "NSArray+Extra.h"

@implementation NSArray (Extra)

- (id)safeGetObjectAtIndex:(NSInteger)index
{
    if (index < 0 || index > self.count-1) return nil;
    
    return self[index];
}

- (BOOL)containsString:(NSString *)string
{
    for (NSString *str in self) {
        if (![str isKindOfClass:[NSString class]]) return NO;
        
        if ([string isEqualToString:str]) {
            return YES;
        }
    }
    return NO;
}

@end
