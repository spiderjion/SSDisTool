//
//  Model.m
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "Model.h"
#import <objc/runtime.h>

static NSMutableDictionary *ivarDictionay = nil;

@implementation Model

+ (instancetype)model
{
    return [[self alloc] init];
}

- (BOOL)isInfoCompletion {
    return NO;
}

#ifdef DEBUG
- (NSString *)description
{
    Class cls = [self class];
    NSString *className = NSStringFromClass(cls);
    if (ivarDictionay == nil)
        ivarDictionay = [[NSMutableDictionary alloc] init];
    
    if ([ivarDictionay objectForKey:className] == nil)
    {
        NSMutableArray *ivarArray = [[NSMutableArray alloc] init];
        
        unsigned int count = 0;
        do
        {
            Ivar *ivars = class_copyIvarList(cls, &count);
            for (uint i = 0; i < count; i++)
            {
                NSString *ivar = [[NSString alloc] initWithUTF8String:ivar_getName(ivars[i])];
                [ivarArray addObject:ivar];
            }
            free(ivars);
        }
        while ((cls = class_getSuperclass(cls))!= [Model class]);
        
        [ivarDictionay setObject:ivarArray forKey:className];
    }
    
    NSArray *ivarArray = [ivarDictionay objectForKey:className];
    NSMutableDictionary *ivarDict = [[NSMutableDictionary alloc] initWithCapacity:ivarArray.count];
    for (NSString *ivar in ivarArray)
    {
        id value = [self valueForKey:ivar];
        [ivarDict setValue:(value ? value : [NSNull null]) forKey:ivar];
    }
    
    NSString *_description = [ivarDict description];
    return _description ;
}
#endif

@end


@implementation CommandInfo

- (NSMutableDictionary *)commandDic {
    if (!_commandDic) {
        _commandDic = [[NSMutableDictionary alloc] init];
    }
    return _commandDic;
}

- (NSMutableArray *)channels {
    if (!_channels) {
        _channels = [[NSMutableArray alloc] init];
    }
    return _channels;
}


@end

@implementation ProjectInfo

- (BOOL)isInfoCompletion {
    return self.projectName.length > 0 && self.version.length > 0;
}

- (NSMutableArray *)iconArray
{
    if (!_iconArray) {
        _iconArray = [NSMutableArray array];
    }
    return _iconArray;
}

@end

@implementation ChannelInfo

- (NSMutableArray *)iconArray
{
    if (!_iconArray) {
        _iconArray = [NSMutableArray array];
    }
    return _iconArray;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[ChannelInfo class]]) return NO;
    
    return [self.appSign isEqualToString:((ChannelInfo *)object).appSign];
}

@end

@implementation CommandResult

+ (instancetype)resultWithStatus:(int)status info:(NSString *)info {
    CommandResult *rs = [CommandResult model];
    rs.status = status;
    rs.result = info;
    
    return rs;
}

@end