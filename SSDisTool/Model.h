//
//  Model.h
//  SSDisTool
//
//  Created by sagles on 14-6-16.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Model : NSObject

+ (instancetype)model;

- (BOOL)isInfoCompletion;

@end

@interface CommandInfo : Model

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *projectPath;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *backupPath;

/**
 *  <#Description#>
 */
@property (nonatomic, strong) NSMutableDictionary *commandDic;

/**
 *  <#Description#>
 */
@property (nonatomic, strong) NSMutableArray *channels;

@end

@interface ProjectInfo : Model

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *projectName;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *workspaceName;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *scheme;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *testScheme;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *version;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *iconImagePath;



/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *backupAppSign;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *backDisplayName;

/**
 *  <#Description#>
 */
@property (nonatomic, strong) NSMutableArray *iconArray;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *infoPlistPath;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *configPath;

@end

@interface ChannelInfo : Model

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *path;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *appSign;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *displayName;

/**
 *  <#Description#>
 */
@property (nonatomic, strong) NSMutableArray *iconArray;

@end


@interface CommandResult : Model

/**
 *  <#Description#>
 */
@property (nonatomic, assign) int status;

/**
 *  <#Description#>
 */
@property (nonatomic, copy) NSString *result;

+ (instancetype)resultWithStatus:(int)status info:(NSString *)info;

@end