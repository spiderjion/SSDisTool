//
//  main.m
//  SSDisTool
//
//  Created by sagles on 14-5-31.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#pragma mark - Marco

#define TASK_SUCCSEE_VALUE 0

#pragma mark - Command

static NSString *const kDistributionOperation = @"-d";
static NSString *const kDisSettingOperation = @"-s";
static NSString *const kDisVersionOperation = @"-v";
static NSString *const kDisOutputOperation = @"-o";

static NSString *const kHelpOperation = @"-h";

#pragma mark - Keys

static NSString *const kCFBundleVersionStringKey = @"CFBundleShortVersionString";
static NSString *const kCFBundleDisplayNameKey = @"CFBundleDisplayName";

static NSString *const kDisplayNameKey = @"displayName";
static NSString *const kAppSignKey = @"appSign";

static NSString *const kBackupPath = @"backup";
static NSString *const kIpaPath = @"SSDisTool_ipa";

#import <Foundation/Foundation.h>
#import "Model.h"
#import "NSString+Extra.h"
#import "NSArray+Extra.h"

#pragma mark - Static Propertie

static NSString *backupPath = nil;
static NSString *outputPath = nil;


static CommandInfo *commandInfo = nil;
static ProjectInfo *projectInfo = nil;
static NSArray *iconNameArray = nil;


#pragma mark - Functions

#pragma mark Private
CommandResult *runCommand(NSString *commandToRun, NSString *path);
BOOL isChannelReiterant(ChannelInfo *channel);

#pragma mark Public
/**
 *  发布
 */
void distributeProject(ChannelInfo *info);
/**
 *  帮助文档
 */
void listHelpInfo();

//将命令参数放进去字典
void parseLaunchCommand(int argc, const char * argv[]);
//配置项目版本（git 版本）
void setProjectVersion(NSString *version);
//将工程参数设置进去model
void setupProjectInfo();
//获取channel信息
void setupChannelInfo(NSString *settingPath);
//备份工程信息
BOOL backupProjectInfo();
//设置渠道配置
BOOL setChannelConfig(ChannelInfo *channel);
//还原配置
void resetChannelConfig();
//退出程序
void ssExit(NSString *info, int status);
//设置输出目录
void setupOutputPath(ChannelInfo *info);

#pragma mark - Main

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        
        commandInfo = [CommandInfo model];
        projectInfo = [ProjectInfo model];
        
        // insert code here...
        NSLog(@"%s",argv[0]);
        
        parseLaunchCommand(argc, argv);
        
        if (argc > 1) {
            
            NSString *operation = [NSString stringWithUTF8String:argv[1]];
            
            if ([operation isCommand]) {
                
                if (argc > 2) {
                    NSString *path = [NSString fullPathWithUTF8String:argv[2]];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                        commandInfo.projectPath = path;
                    }
                    else {
                        ssExit([NSString stringWithFormat:@"project path '%@' is not exists",path], EXIT_FAILURE);
                    }
                }
                
                iconNameArray = @[@"Icon.png",@"Icon@2x.png",
                                  @"Icon-small.png",@"Icon-small@2x.png",
                                  @"Icon-small-40.png",@"Icon-small-40@2x.png",
                                  @"Icon-120.png",@"Icon-120@2x.png"];
                
                if ([operation isEqualToString:kDistributionOperation]) {
                    setupProjectInfo();
                    
                    //先判断工程版本
                    NSString *version = commandInfo.commandDic[kDisVersionOperation];
                    if (version.length > 0) {
                        setProjectVersion(version);
                    }
                    else {
                        ssExit(@"needs -v command and the value of version", EXIT_FAILURE);
                    }
                    
                    //channel info
                    NSString *settingPath = commandInfo.commandDic[kDisSettingOperation];
                    if (settingPath && settingPath.length == 0) {
                        NSString *toolPath = [NSString stringWithFormat:@"%@/..",[NSString stringWithUTF8String:argv[0]]];
                        settingPath = toolPath.fullPath;
                    }
                    setupChannelInfo(settingPath);
                    
                    if (commandInfo.channels.count > 0) {
                        for (ChannelInfo *info in commandInfo.channels) {
                            if (backupProjectInfo()) {
                                if (setChannelConfig(info)) {
                                    
                                    //设置输出目录
                                    setupOutputPath(info);
                                    
                                    NSLog(@"\n"
                                          "‼️‼️‼️‼️‼️‼️‼️‼️‼️\n"
                                          "Star to distribute project\n"
                                          "************Info************\n"
                                          "Project:%@\n"
                                          "Channel:%@\n"
                                          "AppSign:%@\n"
                                          "****************************\n",
                                          projectInfo.projectName,
                                          info.displayName,
                                          info.appSign);
                                    
                                    distributeProject(info);
                                    
                                    resetChannelConfig();
                                }
                                else {
                                    NSLog(@"\n"
                                          "‼️‼️‼️‼️‼️‼️‼️‼️‼️\n"
                                          "************Info************\n"
                                          "Project:%@\n"
                                          "Channel:%@\n"
                                          "AppSign:%@\n"
                                          "****************************\n"
                                          "Set channel info fail and no ipa output\n",
                                          projectInfo.projectName,
                                          info.displayName,
                                          info.appSign);
                                }
                            }
                            else {
                                NSLog(@"\n"
                                      "‼️‼️‼️‼️‼️‼️‼️‼️‼️\n"
                                      "************Info************\n"
                                      "Project:%@\n"
                                      "Workspace:%@\n"
                                      "Scheme:%@\n"
                                      "AppSign:%@\n"
                                      "DisplayName:%@\n"
                                      "iconCount:%lu\n"
                                      "****************************\n"
                                      "Backup project info fail\n",
                                      projectInfo.projectName,
                                      projectInfo.workspaceName,
                                      projectInfo.scheme,
                                      projectInfo.backupAppSign,
                                      projectInfo.backDisplayName,
                                      (unsigned long)projectInfo.iconArray.count);
                            }
                        }
                    }
                    else {
                        NSLog(@"\n"
                              "‼️‼️‼️‼️‼️‼️‼️‼️‼️\n"
                              "Star to distribute project\n");
                        
                        distributeProject(nil);
                    }
                    
                }
                else if ([operation isEqualToString:kHelpOperation]) {
                    listHelpInfo();
                }
                else {
                    ssExit(@"command unsupport", EXIT_FAILURE);
                }
            }
            else {
                ssExit(@"command unsupport", EXIT_FAILURE);
            }
        }
    }
    return 0;
}

#pragma mark - Functions implementation

void distributeProject(ChannelInfo *info)
{
    //获取sdk信息
    NSString *command = [NSString stringWithFormat:@"xcodeproj show %@/%@|grep SDKROOT:|awk '{print $2}'|uniq",
                         commandInfo.projectPath,
                         projectInfo.projectName];
    CommandResult *rs = runCommand(command,nil);
    if (rs.status != TASK_SUCCSEE_VALUE) {
        ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
    }
    NSString *sdk = rs.result.trim;
    
    command = [NSString stringWithFormat:@"xcodeproj show %@/%@|grep IPHONEOS_DEPLOYMENT_TARGET |awk -F \'[\\t:\'\\\'\']\' \'{print $3}\'|uniq",
               commandInfo.projectPath,
               projectInfo.projectName];
    rs = runCommand(command,nil);
    if (rs.status != TASK_SUCCSEE_VALUE) {
        ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
    }
    
    NSString *sdkVersion = rs.result.trim;
    NSString *buildSdk = [NSString stringWithFormat:@"%@%@",sdk,sdkVersion];
    
    //构建
    command = nil;
    if (projectInfo.workspaceName.length > 0 && projectInfo.scheme.length > 0) {
        command = [NSString stringWithFormat:
                   @"xcodebuild -workspace %@ -scheme %@ "
                   "-configuration Release clean build|grep Validate |awk '{print $2}'",
                   projectInfo.workspaceName,projectInfo.scheme];
    }
    else if (projectInfo.projectName.length > 0)
    {
        command = [NSString stringWithFormat:
                   @"xcodebuild -project %@ -sdk %@ clean build|grep Validate |awk '{print $2}'",
                   projectInfo.projectName,buildSdk];
    }
    
    if (command.length > 0) {
        rs = runCommand(command, commandInfo.projectPath);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
        }
        NSString *appPath = rs.result.trim;
        if (![[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
            ssExit([NSString stringWithFormat:@"the path \"%@\" is not exist or is not a directory",
                    commandInfo.projectPath], EXIT_FAILURE);
        }
        
        if (outputPath.length == 0) {
            setupOutputPath(nil);
        }
        
        
        //保存dSYM文件
//        NSString *dSYM = [NSString stringWithFormat:@"%@.dSYM",appPath];
//        command = [NSString stringWithFormat:@"cp -r %@ %@",dSYM,outputPath];
//        rs = runCommand(command, nil);
//        if (rs.status != TASK_SUCCSEE_VALUE) {
//            NSLog(@"SSDisTool: copy dSYM file failed");
//        }
        
        //打包ipa
        NSString *name = info ? info.appSign : [projectInfo.projectName stringByDeletingPathExtension];
        NSString *extension = [projectInfo.projectName isContainString:@"XYT"] ? @"_teacher" : @"";
        
        NSString *ipa = [NSString stringWithFormat:@"%@/%@%@.ipa",
                         outputPath,name,extension];
        command = [NSString stringWithFormat:@"xcrun -sdk %@ PackageApplication -o %@ -v %@",sdk,ipa,appPath];
        rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
        }
        
        NSLog(@"\n"
              "‼️End distribution‼️\n"
              "ipa path : %@",ipa);
    }
    else {
        ssExit(@"Get workspaceName、scheme or projectName Error", EXIT_FAILURE);
    }
}

void listHelpInfo()
{
    NSLog(@"%@",
          @"\n******************SSDisTool******************\n"
          "*This tool is an auto distribution tool for xcode\n"
          "*project.\n"
          "\n"
          "*Usage: SSDistool [command] [optional] [optional]\n"
          "\n"
          "*Command:\n"
          "** -d distribute xcode project.It must set the path\n"
          "*of project follow behind it.\n"
          "\n"
          "*Optional:\n"
          "\n"
          "** -s custom channel config,the value of this command\n"
          "*is a path,which contain the channel info.Or empty \n"
          "*that will use the path contain SSDistool.\n"
          "\n"
          "** -v the project distribution version.It must not be\n"
          "*nil.When tool find that the version of the project is\n"
          "*not same to this version,it will find the version in git\n"
          "*and checkout it while find one is same.\n"
          "\n"
          "** -o the output path.if not set,the output path will \n"
          "*be the channel path if there is channel info,or will \n"
          "*be the path ~/Desktop\n"
          "******************help info******************");
}

#pragma mark - Private methods

void parseLaunchCommand(int argc, const char * argv[]) {
    
    if (argc > 1) {
        BOOL isCommand = NO;
        NSString *key = nil;
        NSString *values = nil;
        for (int i=2; i<argc; i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            
            if (i == argc-1) {
                if ([arg isCommand]) {
                    if ([key isCommand] && isCommand) {
                        commandInfo.commandDic[key] = @"";
                    }
                    
                    commandInfo.commandDic[arg] = @"";
                }
                else {
                    if ([key isCommand]) {
                        commandInfo.commandDic[key] = arg;
                    }
                }
                continue;
            }
            
            if ([arg isCommand]) {
                if (isCommand) {
                    commandInfo.commandDic[key] = @"";
                }
                
                key = arg;
                isCommand = YES;
            }
            else {
                values = arg;
                
                if (isCommand) {
                    commandInfo.commandDic[key] = values;
                }
                
                isCommand = NO;
            }
            
        }
    }
    else {
        listHelpInfo();
    }
}

void setProjectVersion(NSString *version) {
    if (![version isEqualToString:projectInfo.version]) {
        
        NSString *gitPath = [NSString stringWithFormat:@"%@/..",commandInfo.projectPath].fullPath;
        
        NSString *command = @"git tag";
        CommandResult *rs = runCommand(command, gitPath);
        if (rs.status == TASK_SUCCSEE_VALUE) {
            NSArray *tagArray = [rs.result componentsSeparatedByString:@"\n"];
            NSLog(@"SSDisTool: project git tags are '%@'",tagArray);
            
            if ([tagArray containsString:version]) {
                command = [NSString stringWithFormat:@"git checkout %@",version];
                rs = runCommand(command, gitPath);
                if (rs.status != TASK_SUCCSEE_VALUE) {
                    ssExit(@"checkout tag fail,project version is different to verion value", EXIT_FAILURE);
                }
            }
        }
        else {
            NSLog(@"SSDisTool: get project git tag fail");
        }
    }
}

void setupProjectInfo() {
    NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtPath:commandInfo.projectPath];
    NSString *path = nil;
    while (path = [enumerator nextObject]) {
        if ([path isContainString:@".svn"] ||
            [path isContainString:@".git"] ||
            [path isContainString:@"Pods"] ||
            [path isContainString:@"Tests"] ||
            [path isContainString:@".DS_Store"]) continue;
        
        if (([path isContainString:@".xcworkspacedata"] ||
             [path isContainString:@"xcshareddata"] ||
             [path isContainString:@"xcuserdata"])) {
            if (!projectInfo.scheme &&[[path lastPathComponent] isContainString:@".xcscheme"]) {
                projectInfo.scheme = [path lastPathComponent].stringByDeletingPathExtension;
            }
            continue;
        }
        else {
            if (![path isContainString:@".xcodeproj"] &&
                [[path lastPathComponent] isContainString:@".xcworkspace"]) {
                projectInfo.workspaceName = [path lastPathComponent];
                continue;
            }
            
            if (!projectInfo.projectName && [[path lastPathComponent] isContainString:@".xcodeproj"]) {
                projectInfo.projectName = [path lastPathComponent];
                continue;
            }
            
            if ([[path lastPathComponent] isContainString:@"Info.plist"]) {
                projectInfo.infoPlistPath = [NSString stringWithFormat:@"%@/%@",commandInfo.projectPath,path];
                continue;
            }
            
            if ([iconNameArray containsString:[path lastPathComponent]]) {
                if (!projectInfo.iconImagePath) {
                    NSString *upPath = [NSString stringWithFormat:@"%@/%@/..",commandInfo.projectPath,path];
                    projectInfo.iconImagePath = upPath.fullPath;
                }
                [projectInfo.iconArray addObject:[NSString stringWithFormat:@"%@/%@",commandInfo.projectPath,path]];
                continue;
            }
            
            if ([[path lastPathComponent] isContainString:@"Config.h"]) {
                projectInfo.configPath = [NSString stringWithFormat:@"%@/%@",commandInfo.projectPath,path];
            }
        }
    }
    
    //获取version
    if (projectInfo.infoPlistPath.length > 0) {
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                             kCFBundleVersionStringKey,projectInfo.infoPlistPath];
        CommandResult *rs = runCommand(command, nil);
        if (rs.status == TASK_SUCCSEE_VALUE) {
            projectInfo.version = rs.result.trim;
        }
        else {
            ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
        }
    }
}

void setupChannelInfo(NSString *settingPath) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingPath]) {
        
        NSMutableDictionary *channelDic = [NSMutableDictionary dictionary];
        NSString *key = nil;
        NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:settingPath];
        NSString *path = nil;
        while (path = [enumerator nextObject]) {
            if ([path isContainString:@".DS_Store"] ||
                [path isContainString:@"SSDisTool"] ||
                [path isContainString:kBackupPath] ||
                [path isContainString:kIpaPath]) {
                continue;
            }
            
            if (![path isContainString:@"/"]) {
                key = [path copy];
                ChannelInfo *info = [ChannelInfo model];
                info.path = [NSString stringWithFormat:@"%@/%@",settingPath,path];
                channelDic[key] = info;
            }
            else {
                ChannelInfo *info = channelDic[key];
                
                if (info) {
                    if ([iconNameArray containsString:path.lastPathComponent]) {
                        [info.iconArray addObject:[NSString stringWithFormat:@"%@/%@",settingPath,path]];
                        continue;
                    }
                    
                    if ([[path lastPathComponent] isContainString:@".plist"]) {
                        NSString *plistPath = [NSString stringWithFormat:@"%@/%@",settingPath,path];
                        
                        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                                             kDisplayNameKey,plistPath];
                        CommandResult *rs = runCommand(command, nil);
                        if (rs.status == TASK_SUCCSEE_VALUE) {
                            info.displayName = rs.result.trim;
                        }
                        
                        command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                                   kAppSignKey,plistPath];
                        rs = runCommand(command, nil);
                        if (rs.status == TASK_SUCCSEE_VALUE) {
                            info.appSign = rs.result.trim;
                            
                            if (isChannelReiterant(info)) {
                                exit(EXIT_FAILURE);
                            }
                        }
                        continue;
                    }
                }
            }
        }
        
        [commandInfo.channels addObjectsFromArray:channelDic.allValues];
        
        commandInfo.backupPath = [NSString stringWithFormat:@"%@/%@",settingPath,kBackupPath];
    }
    else {
        NSLog(@"SSDisTool: The path '%@' of channel info is not exists",settingPath);
    }
}

BOOL backupProjectInfo() {
    
    if (commandInfo.backupPath.length > 0) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:commandInfo.backupPath]) {
            NSString *command = [NSString stringWithFormat:@"mkdir %@",commandInfo.backupPath];
            CommandResult *rs = runCommand(command, nil);
            if (rs.status != TASK_SUCCSEE_VALUE) {
                NSLog(@"SSDisTool: create dir '%@'\nerror %d",commandInfo.backupPath,rs.status);
            }
        }
        
        for (NSString *path in projectInfo.iconArray) {
            if (path.length > 0) {
                NSString *command = [NSString stringWithFormat:@"cp %@ %@",path,commandInfo.backupPath];
                CommandResult *rs = runCommand(command, nil);
                if (rs.status != TASK_SUCCSEE_VALUE) {
                    NSLog(@"SSDisTool: backup icon '%@' failed",path);
                }
            }
        }
    }
    else {
        return NO;
    }
    
    if (projectInfo.infoPlistPath.length > 0) {
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                             kCFBundleDisplayNameKey,projectInfo.infoPlistPath];
        CommandResult *rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            NSLog(@"SSDisTool: backup displayName failed");
            return NO;
        }
        projectInfo.backDisplayName = rs.result.trim;
    }
    
    if (projectInfo.configPath.length > 0) {
        NSString *command = [NSString stringWithFormat:
                             @"cat %@ |grep \"#define kAppSign\"|sed \'s/#define kAppSign @\"\\(.*\\)\"/\\1/g\'",
                             projectInfo.configPath];
        CommandResult *rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            NSLog(@"SSDisTool: backup appSign failed");
            return NO;
        }
        projectInfo.backupAppSign = rs.result.trim;
    }
    
    return YES;
}

BOOL setChannelConfig(ChannelInfo *channel)
{
    if (channel.displayName.length == 0 && channel.appSign.length == 0) {
        return NO;
    }
    
    CommandResult *rs = nil;
    //set icon
    for (NSString *path in channel.iconArray) {
        if (path.length > 0) {
            NSString *command = [NSString stringWithFormat:@"cp %@ %@",path,projectInfo.iconImagePath];
            rs = runCommand(command, nil);
            if (rs.status != TASK_SUCCSEE_VALUE) {
                NSLog(@"SSDisTool: set channel icon '%@' failed",path);
            }
        }
    }
    
    //set plist
    if (channel.displayName.length > 0) {
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Set :%@ %@\" \"%@\"",
                             kCFBundleDisplayNameKey,channel.displayName,projectInfo.infoPlistPath];
        rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            NSLog(@"SSDisTool: set channel displayName '%@' failed",channel.displayName);
        }
    }
    
    //set appSign
    if (projectInfo.configPath.length > 0) {
        NSString *command = [NSString stringWithFormat:@"sed -ie 's/%@/%@/g' %@",
                             projectInfo.backupAppSign,channel.appSign,projectInfo.configPath];
        rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            NSLog(@"SSDisTool: set channel appSign '%@' failed",channel.appSign);
        }
    }
    
    return YES;
}

void resetChannelConfig()
{
    CommandResult *rs = nil;
    for (NSString *path in projectInfo.iconArray) {
        if (path.length > 0) {
            NSString *backupImagePath = [NSString stringWithFormat:@"%@/%@",commandInfo.backupPath,[path lastPathComponent]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:backupImagePath]) {
                NSString *command = [NSString stringWithFormat:@"mv %@ %@",backupImagePath,projectInfo.iconImagePath];
                rs = runCommand(command, nil);
                if (rs.status != TASK_SUCCSEE_VALUE) {
                    ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
                }
            }
        }
    }
    
    if (projectInfo.infoPlistPath.length > 0) {
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Set :%@ '%@'\" \"%@\"",
                             kCFBundleDisplayNameKey,projectInfo.backDisplayName,projectInfo.infoPlistPath];
        rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
        }
    }
    
    if (projectInfo.configPath.length > 0) {
        NSString *command = [NSString stringWithFormat:
                             @"cat %@ |grep \"#define kAppSign\"|sed \'s/#define kAppSign @\"\\(.*\\)\"/\\1/g\'",
                             projectInfo.configPath];
        rs = runCommand(command, nil);
        NSString *oldSign = rs.status == 0 ? rs.result.trim : nil;
        
        if (oldSign) {
            command = [NSString stringWithFormat:@"sed -ie 's/%@/%@/g' %@",
                       oldSign,projectInfo.backupAppSign,projectInfo.configPath];
            rs = runCommand(command, nil);
            
            if (rs.status != TASK_SUCCSEE_VALUE) {
                ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
            }
        }
        else {
            ssExit(@"get current appSign fail", EXIT_FAILURE);
        }
    }
    
    //去掉sed命令的备份文件
    NSString *path = [NSString stringWithFormat:@"%@e",projectInfo.configPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    //去掉backup文件夹
    if ([[NSFileManager defaultManager] fileExistsAtPath:commandInfo.backupPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:commandInfo.backupPath error:nil];
    }
}

CommandResult *runCommand(NSString *commandToRun,NSString *path)
{
    NSMutableArray *commands = [NSMutableArray arrayWithObject:@"-c"];
    
    [commands addObject:commandToRun];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    if (path.length > 0) {
        [task setCurrentDirectoryPath:path];
    }
    [task setArguments: commands];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    
    NSData *data = [file readDataToEndOfFile];
    
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [CommandResult resultWithStatus:status info:output];
}

BOOL isChannelReiterant(ChannelInfo *channel)
{
    ChannelInfo *info = nil;
    for (info in commandInfo.channels) {
        if ([info isEqual:channel]) {
            
            NSLog(@"\n‼️‼️‼️‼️重复配置‼️‼️‼️‼️\n"
                  "///////information////////\n"
                  "//path:%@\n"
                  "//path:%@\n"
                  "//里面的setting.plist配置appSign重复，\n"
                  "//请检查后重新运行脚本\n"
                  "//////////////////////////",
                  info.path,
                  channel.path);
            
            return YES;
        }
    }
    
    return NO;
}

void ssExit(NSString *info, int status) {
    NSLog(@"SSDisTool: %@\ncode %d",info,status);
    exit(status);
}

void setupOutputPath(ChannelInfo *info) {
    NSString *path = nil;
    NSString *o_path = commandInfo.commandDic[kDisOutputOperation];
    if (o_path.length > 0) {
        path = [NSString stringWithFormat:@"%@/%@",o_path,kIpaPath].fullPath;
    }
    else {
        if (info) {
            o_path = [NSString stringWithFormat:@"%@/..",info.path].fullPath;
            path = [NSString stringWithFormat:@"%@/%@",o_path,kIpaPath].fullPath;
        }
        else {
            path = [NSString stringWithFormat:@"~/Desktop/%@",kIpaPath].fullPath;
        }
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *command = [NSString stringWithFormat:@"mkdir %@",path];
        CommandResult *rs = runCommand(command, nil);
        if (rs.status != TASK_SUCCSEE_VALUE) {
            ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
        }
        else {
            outputPath = info ? [NSString stringWithFormat:@"%@/%@",path,info.appSign] : [path copy];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
                NSString *command = [NSString stringWithFormat:@"mkdir %@",outputPath];
                CommandResult *rs = runCommand(command, nil);
                if (rs.status != TASK_SUCCSEE_VALUE) {
                    ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
                }
            }
        }
    }
    else {
        outputPath = info ? [NSString stringWithFormat:@"%@/%@",path,info.appSign] : [path copy];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
            NSString *command = [NSString stringWithFormat:@"mkdir %@",outputPath];
            CommandResult *rs = runCommand(command, nil);
            if (rs.status != TASK_SUCCSEE_VALUE) {
                ssExit([NSString stringWithFormat:@"run command '%@' fail",command], EXIT_FAILURE);
            }
        }
    }
}

#pragma mark - Keychain

//static const UInt8 kKeychainItemIdentifier[]    = "com.apple.dts.KeychainUI\0";

//    NSData *keychainItemID = [NSData dataWithBytes:kKeychainItemIdentifier
//                                            length:strlen((const char *)kKeychainItemIdentifier)];
//
//    CFArrayRef items;
//    NSDictionary *queryDic = @{(__bridge id)kSecClass: (__bridge NSString *)kSecClassCertificate,
//                               (__bridge id)kSecAttrGeneric: keychainItemID,
//                               (__bridge id)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
//                               (__bridge id)kSecMatchLimit: (__bridge id)kSecMatchLimitAll};
//
//    OSStatus resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)queryDic, (CFTypeRef *)&items);
//    if (resultCode == errSecSuccess) {
//
//        NSArray *array = (__bridge_transfer NSArray *)items;
//        for (id cert in array) {
//            NSMutableDictionary *dic = secItemFormatToDictionary(cert);
//            NSLog(@"%@",dic);
//        }
//    }

//// Implement the secItemFormatToDictionary: method, which takes the attribute dictionary
////  obtained from the keychain item, acquires the password from the keychain, and
////  adds it to the attribute dictionary:
//NSMutableDictionary *secItemFormatToDictionary(NSDictionary *dictionaryToConvert)
//{
//    // This method must be called with a properly populated dictionary
//    // containing all the right key/value pairs for the keychain item.
//    
//    // Create a return dictionary populated with the attributes:
//    NSMutableDictionary *returnDictionary = [NSMutableDictionary
//                                             dictionaryWithDictionary:dictionaryToConvert];
//    
//    // To acquire the password data from the keychain item,
//    // first add the search key and class attribute required to obtain the password:
//    [returnDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
//    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
//    // Then call Keychain Services to get the password:
//    CFDataRef passwordData = NULL;
//    OSStatus keychainError = noErr; //
//    keychainError = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary,
//                                        (CFTypeRef *)&passwordData);
//    if (keychainError == noErr)
//    {
//        // Remove the kSecReturnData key; we don't need it anymore:
//        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
//        
//        // Convert the password to an NSString and add it to the return dictionary:
//        NSString *password = [[NSString alloc] initWithBytes:[(__bridge_transfer NSData *)passwordData bytes]
//                                                      length:[(__bridge NSData *)passwordData length] encoding:NSUTF8StringEncoding];
//        [returnDictionary setObject:password forKey:(__bridge id)kSecValueData];
//    }
//    // Don't do anything if nothing is found.
//    else if (keychainError == errSecItemNotFound) {
////        NSAssert(NO, @"Nothing was found in the keychain.\n");
//        if (passwordData) CFRelease(passwordData);
//    }
//    // Any other error is unexpected.
//    else
//    {
////        NSAssert(NO, @"Serious error.\n");
//        if (passwordData) CFRelease(passwordData);
//    }
//    
//    return returnDictionary;
//}
