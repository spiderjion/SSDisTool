//
//  NSString+Extra.h
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extra)

- (NSString *)trim;

- (BOOL)isCommand;

- (BOOL)isContainString:(NSString *)subString;

- (NSString *)fullPath;

+ (NSString *)fullPathWithUTF8String:(const char *)cString;

@end
