//
//  NSString+Extra.m
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "NSString+Extra.h"

@implementation NSString (Extra)

- (NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isCommand
{
    return [self rangeOfString:@"-"].location == 0;
}

- (BOOL)isContainString:(NSString *)subString
{
    if (!subString) return NO;
    
    return [self rangeOfString:subString].location != NSNotFound;
}

- (NSString *)fullPath
{
    return [self stringByStandardizingPath];
}

+ (NSString *)fullPathWithUTF8String:(const char *)cString
{
    NSString *str = [NSString stringWithUTF8String:cString];
    
    return [str stringByStandardizingPath];
}

@end
