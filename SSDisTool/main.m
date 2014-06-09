//
//  main.m
//  SSDisTool
//
//  Created by sagles on 14-5-31.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#pragma mark - Marco

#define kDistributionOperation @"-d"
#define kDisSettingOperation @"-s"

#define kAnalyzeOperation @"-a"
#define kUnitTestOperation @"-u"

#define kHelpOperation @"-h"

#pragma mark - Keys

static NSString *const kDisplayNameKey = @"displayName";
static NSString *const kAppSignKey = @"appSign";

#pragma mark - Channel Struct

struct Channel {
    const char *displayName;
    const char *appSign;
    
    char iconPaths[2048];
};

#import <Foundation/Foundation.h>

#pragma mark - Static Properties

static NSMutableArray *channels = nil;

static NSString *backupPath = nil;
static NSString *plistPath = nil;
static NSString *configPath = nil;
static NSString *originalImagePath = nil;
static NSString *outputPath = nil;
static struct Channel empty = {0,};
static struct Channel original = {0,};

#pragma mark - Functions

#pragma mark Private
const char *fullPathWithPath(const char *c_path);
NSString *runCommand(NSString *commandToRun, NSString *path);
NSString *trim(NSString *originalString);
BOOL setChannelConfig(struct Channel channel);
void recoveryChannelConfig();

#pragma mark Public
/**
 *  发布
 */
void distributeProject(NSString *projectPath, NSString *projectName,NSString *workspaceName,NSString *scheme);
/**
 *  静态分析
 */
void analyzeProject();
/**
 *  单元测试
 */
void unitTestProject();
/**
 *  帮助文档
 */
void listHelpInfo();
/**
 *  配置自己所需要的东西(定制型)
 */
void setupCustomConfig(NSString *settingPath);

#pragma mark - Main

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        // insert code here...
        NSLog(@"%s",argv[0]);
        
        if (argc > 1) {
            NSString *operation = [NSString stringWithUTF8String:argv[1]];
            
            NSString *(^checkFilePath)(NSString *) = ^(NSString *originalPath){
                NSString *appPath = [[NSBundle mainBundle] bundlePath];
                NSString *resultPath = originalPath;
                if (![resultPath rangeOfString:@"/"].location == 0){
                    if ([resultPath rangeOfString:@"~/"].location == 0)
                        resultPath = [NSHomeDirectory() stringByAppendingPathComponent:[resultPath substringFromIndex:1]];
                    else
                        resultPath = [appPath stringByAppendingPathComponent:resultPath];
                }
                
                return resultPath;
            };
            
            if (argc > 2) {
                
                //获取必要的参数
                NSString *projectPath = checkFilePath([NSString stringWithUTF8String:argv[2]]);
                BOOL isDir = NO;
                if (![[NSFileManager defaultManager] fileExistsAtPath:projectPath isDirectory:&isDir] && isDir) {
                    NSLog(@"the path \"%@\" is not exist or is not a directory",projectPath);
                    return EXIT_FAILURE;
                }
                NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:projectPath];
                NSString *path = nil;
                
                //**************必要参数***************//
                NSString *project = nil;
                NSString *workspace = nil;
                NSString *scheme = nil;
                
                while (path = [enumerator nextObject]) {
                    if ([path rangeOfString:@".svn"].location != NSNotFound ||
                        [path rangeOfString:@".git"].location != NSNotFound ||
                        [path rangeOfString:@"Pods"].location != NSNotFound ||
                        [path rangeOfString:@"XYTTests"].location != NSNotFound) continue;
                    
                    if (([path rangeOfString:@".xcworkspacedata"].location != NSNotFound ||
                         [path rangeOfString:@"xcshareddata"].location != NSNotFound ||
                         [path rangeOfString:@"xcuserdata"].location != NSNotFound)) {
                        if (!scheme &&[[path lastPathComponent] rangeOfString:@".xcscheme"].location != NSNotFound) {
                            scheme = [[[path lastPathComponent] componentsSeparatedByString:@"."] firstObject];
                        }
                    }
                    else {
                        if ([path rangeOfString:@".xcodeproj"].location == NSNotFound &&
                            [[path lastPathComponent] rangeOfString:@".xcworkspace"].location != NSNotFound) {
                            workspace = [path lastPathComponent];
                        }
                        
                        if (!project && [[path lastPathComponent] rangeOfString:@".xcodeproj"].location != NSNotFound) {
                            project = [path lastPathComponent];
                        }
                        
                        if ([[path lastPathComponent] rangeOfString:@"Info.plist"].location != NSNotFound) {
                            plistPath = [NSString stringWithFormat:@"%@/%@",projectPath,path];
                        }
                        if ([[path lastPathComponent] rangeOfString:@"icon"].location != NSNotFound) {
                            if (!originalImagePath) {
                                originalImagePath = [projectPath stringByAppendingFormat:@"/%@",path];
                            }
                        }
                        if ([[path lastPathComponent] rangeOfString:@"Config.h"].location != NSNotFound) {
                            configPath = [NSString stringWithFormat:@"%@/%@",projectPath,path];
                        }
                        
                        if ([[path lastPathComponent] rangeOfString:@"Icon@2x.png"].location != NSNotFound ||
                            [[path lastPathComponent] rangeOfString:@"Icon-small@2x.png"].location != NSNotFound ||
                            [[path lastPathComponent] rangeOfString:@"Icon-small-40@2x.png"].location != NSNotFound ||
                            [[path lastPathComponent] rangeOfString:@"Icon-120@2x.png"].location != NSNotFound) {
                            strcat(original.iconPaths, [[NSString stringWithFormat:@"|%@/%@",projectPath,path] UTF8String]);
                        }
                    }
                }
                
                if ((project || workspace) && scheme && plistPath) {
                    if ([operation isEqualToString:kDistributionOperation]) {
                        
                        NSString *fullPath = nil;
                        if (argc >= 4) {
                            NSString *subOper = [NSString stringWithUTF8String:argv[3]];
                            if ([subOper isEqualToString:kDisSettingOperation]) {
                                char temp[200];
                                
                                if (argc > 4) {
                                    strcpy(temp, argv[4]);
                                }
                                else {
                                    const char *outputPath = argv[0];
                                    sprintf(temp, "%s/..",outputPath);
                                }
                                
                                fullPath = [NSString stringWithUTF8String:fullPathWithPath(temp)];
                                setupCustomConfig(fullPath);
                            }
                            else {
                                NSLog(@"Operation or parameters error");
                                return EXIT_FAILURE;
                            }
                        }
                        else {
                            char o_path[100];
                            sprintf(o_path,"~/Desktop/%s.ipa", [scheme UTF8String]);
                            outputPath = [NSString stringWithUTF8String:fullPathWithPath(o_path)];
                        }
                        
                        if (channels.count > 0 && backupPath.length > 0) {
                            for (NSValue *values in channels) {
                                struct Channel channel = {0,};
                                [values getValue:&channel];
                                
                                if (memcmp(&channel, &empty, sizeof(channel)) > 0) {
                                    if (setChannelConfig(channel)) {
                                        NSString *displayName = [NSString stringWithUTF8String:channel.displayName];
                                        outputPath = [NSString stringWithFormat:@"%@/%@.ipa",fullPath,displayName];
                                        NSLog(@"‼️‼️‼️‼️‼️‼️‼️‼️‼️\n************Info************\nProject:%@\nChannel:%@\nAppSign:%@\n****************************",
                                              project,
                                              [NSString stringWithUTF8String:channel.displayName],
                                              [NSString stringWithUTF8String:channel.appSign]);
                                        distributeProject(projectPath,project,workspace,scheme);
                                        recoveryChannelConfig();
                                    }
                                }
                            }
                        }
                        else {
                            distributeProject(projectPath,project,workspace,scheme);
                        }
                        
                    }
                    else if ([operation isEqualToString:kAnalyzeOperation]) {
                        
                    }
                    else if ([operation isEqualToString:kUnitTestOperation]) {
                        
                    }
                    else {
                        NSLog(@"Needs operation parameter!");
                        return EXIT_FAILURE;
                    }
                }
                else {
                    NSLog(@"Obtain shell script parameters error or the path of project not correct");
                    return EXIT_FAILURE;
                }
            }
            else if ([operation isEqualToString:kHelpOperation]) {
                listHelpInfo();
            }
            else {
                NSLog(@"Command line tool needs operation parameters!");
                return EXIT_FAILURE;
            }
            
        }
        else {
            listHelpInfo();
        }
    }
    return 0;
}

#pragma mark - Functions implementation

void distributeProject(NSString *projectPath,NSString *projectName,NSString *workspaceName,NSString *scheme)
{
    //获取sdk信息
    NSString *sdk = runCommand([NSString stringWithFormat:@"xcodeproj show %@/%@|grep SDKROOT:|awk '{print $2}'|uniq",
                                projectPath,
                                projectName],nil);
    NSString *sdkVersion = runCommand([NSString stringWithFormat:@"xcodeproj show %@/%@|grep IPHONEOS_DEPLOYMENT_TARGET |awk -F \'[\\t:\'\\\'\']\' \'{print $3}\'|uniq",
                                       projectPath,
                                       projectName],nil);
    
    NSString *buildSdk = [NSString stringWithFormat:@"%@%@",trim(sdk),trim(sdkVersion)];
    
    NSString *command = nil;
    if (workspaceName.length > 0 && scheme.length > 0) {
        command = [NSString stringWithFormat:
                   @"xcodebuild -workspace %@ -scheme %@ -configuration Release clean build|grep Validate |awk '{print $2}'",workspaceName,scheme];
    }
    else if (projectName.length > 0)
    {
        command = [NSString stringWithFormat:
                   @"xcodebuild -project %@ -sdk %@ clean build|grep Validate |awk '{print $2}'",projectName,buildSdk];
    }
    NSLog(@"Packing ipa wait a moment...");
    if (command.length > 0) {
        NSString *appPath = runCommand(command, projectPath);
        
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:appPath isDirectory:&isDir] && isDir) {
            NSLog(@"the path \"%@\" is not exist or is not a directory",projectPath);
            exit(EXIT_FAILURE);
        }
        
        //TODO 保存dSYM文件
        
        //打包ipa
        command = [NSString stringWithFormat:@"xcrun -sdk %@ PackageApplication -o %@ -v %@",trim(sdk),outputPath,appPath];
        runCommand(command, nil);
    }
    NSLog(@"End packing ipa.");
}

void analyzeProject()
{
    
}

void unitTestProject()
{
    
}

void listHelpInfo()
{
    NSLog(@"%@",
          @"\n//////////////////SSDisTool////////////////////\n"
          "// * -d 发布命令，后面接工程目录参数\n"
          "//      -s 配置渠道信息（强定制化），后面接配置目录。\n"
          "//         当需要使用渠道配置时，Info-plist里面的CFBundleDisplayName（Bundle display name）不能为系统默认的宏\n"
          "//         PlistBuddy 不支持\n"
          "//         修改appSign，sed命令会重新创建一个新Config.h文件，并且以新时间覆盖。此时版本控制会提示修改，revert即可\n"
          "// * -a for analyze project and output in shell window\n"
          "// * -u for unit test prject and output\n"
          "// * -h for help information\n"
          "// ****************************\n"
          "// 例子:\n"
          "//   普通发布：SSDisTool -d ~/Desktop/Project\n"
          "//   渠道发布：SSDisTool -d ~/Desktop/Project -s ~/Desktop/Config\n"
          "//////////////////help info////////////////////");
}

void setupCustomConfig(NSString *settingPath)
{
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:settingPath isDirectory:&isDir] && isDir) {
        NSLog(@"the path \"%@\" is not exist or is not a directory",settingPath);
        return;
    }
    
    backupPath = [NSString stringWithFormat:@"%@/backup",settingPath];
    
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:settingPath];
    NSString *path = nil;
    NSString *localName = nil;
    int complate = 0;
    struct Channel channel = {0,};
    channels = [[NSMutableArray alloc] init];
    while (path = [enumerator nextObject]) {
        
        if ([path rangeOfString:@".DS_Store"].location != NSNotFound ||
            [[path lastPathComponent] rangeOfString:@"SSDisTool"].location != NSNotFound) continue;
        
        if ([path rangeOfString:@"/"].location == NSNotFound) {
            localName = path;
            channel = empty;
            channel.displayName = [localName UTF8String];
            complate = 1;
        }
        int result = memcmp(&channel, &empty, sizeof(channel));
        if (localName.length > 0 && result > 0) {
            if ([path rangeOfString:localName].location != NSNotFound) {
                
                //icon
                if ([path rangeOfString:@"/icon"].location != NSNotFound) {
                    if ([[path lastPathComponent] rangeOfString:@"Icon@2x.png"].location != NSNotFound ||
                        [[path lastPathComponent] rangeOfString:@"Icon-small@2x.png"].location != NSNotFound ||
                        [[path lastPathComponent] rangeOfString:@"Icon-small-40@2x.png"].location != NSNotFound ||
                        [[path lastPathComponent] rangeOfString:@"Icon-120@2x.png"].location != NSNotFound) {
                        strcat(channel.iconPaths, [[NSString stringWithFormat:@"|%@/%@",settingPath,path] UTF8String]);
                        complate = complate << 1;
                    }
                    continue;
                }
                else {
                    complate = 16;
                }
                
                //plist
                if ([[path lastPathComponent] rangeOfString:@".plist"].location != NSNotFound) {
                    NSString *plistPath = [settingPath stringByAppendingFormat:@"/%@",path];
                    NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                                         kDisplayNameKey,plistPath];
                    NSString *result = trim(runCommand(command, nil));
                    if (result.length > 0) {
                        channel.displayName = [result UTF8String];
                    }
                    command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print %@\" \"%@\"",
                               kAppSignKey,plistPath];
                    result = trim(runCommand(command, nil));
                    if (result.length > 0) {
                        channel.appSign = [result UTF8String];
                    }
                    complate = complate << 1;
                }
                
                if ((complate & 32) != 0) {
                    [channels addObject:[NSValue value:&channel withObjCType:@encode(struct Channel)]];
                }
            }
        }
    }
}

#pragma mark - Private methods

const char *fullPathWithPath(const char *c_path)
{
    NSString *path = [NSString stringWithUTF8String:c_path];
    
    path = [path stringByStandardizingPath];
    
    return [path UTF8String];
}

NSString *runCommand(NSString *commandToRun,NSString *path)
{
    NSMutableArray *commands = [NSMutableArray arrayWithObject:@"-c"];
    
    [commands addObject:commandToRun];
    
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    if (path.length > 0) {
        [task setCurrentDirectoryPath:path];
    }
    
    [task setArguments: commands];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *output;
    output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

NSString *trim(NSString *originalString)
{
    return [originalString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

BOOL setChannelConfig(struct Channel channel)
{
    //backup
    if (backupPath.length > 0) {
        BOOL isDir = NO;
        if (![[NSFileManager defaultManager] fileExistsAtPath:backupPath isDirectory:&isDir]) {
            NSLog(@"the path \"%@\" is not exist or is not a directory",backupPath);
            NSString *command = [NSString stringWithFormat:@"mkdir %@/",backupPath];
            runCommand(command, nil);
        }
    }
    else {
        NSLog(@"There is not backupPath");
        return NO;
    }
    
    NSString *paths = [NSString stringWithUTF8String:original.iconPaths];
    NSMutableArray *array = [[paths componentsSeparatedByString:@"|"] mutableCopy];
    
    //过滤掉空字符串
    for (NSInteger i = array.count-1; i>=0; i--) {
        if ([array[i] length] == 0) {
            [array removeObjectAtIndex:i];
        }
    }
    
    //backup icon
    if (array.count == 4) {
        for (NSString *path in array) {
            if (path.length > 0) {
                NSString *command = [NSString stringWithFormat:@"cp %@ %@",path,backupPath];
                runCommand(command, nil);
            }
        }
    }
    else {
        return NO;
    }
    
    //backup dispalyName
    if (plistPath.length > 0) {
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Print CFBundleDisplayName\" \"%@\"",plistPath];
        original.displayName = [trim(runCommand(command, nil)) UTF8String];
    }
    else {
        return NO;
    }
    
    //backup appsign
    if (configPath.length > 0) {
        NSString *command = [NSString stringWithFormat:
                             @"cat %@ |grep \"#define kAppSign\"|sed \'s/#define kAppSign @\"\\(.*\\)\"/\\1/g\'",
                             configPath];
        original.appSign = [trim(runCommand(command, nil)) UTF8String];
    }
    else {
        return NO;
    }
    
    //set
    paths = [NSString stringWithUTF8String:channel.iconPaths];
    array = [[paths componentsSeparatedByString:@"|"] mutableCopy];
    
    //过滤掉空字符串
    for (NSInteger i = array.count-1; i>=0; i--) {
        if ([array[i] length] == 0) {
            [array removeObjectAtIndex:i];
        }
    }
    
    //set icon
    if (array.count == 4) {
        for (NSString *path in array) {
            if (path.length > 0) {
                NSString *command = [NSString stringWithFormat:@"mv %@ %@",path,originalImagePath];
                runCommand(command, nil);
            }
        }
    }
    
    //set plist
    if (plistPath.length > 0) {
        NSString *displayName = [NSString stringWithUTF8String:channel.displayName];
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Set :CFBundleDisplayName %@\" \"%@\"",
                             displayName,plistPath];
        runCommand(command, nil);
    }
    
    //set appSign
    if (configPath.length > 0) {
        NSString *oldSign = [NSString stringWithUTF8String:original.appSign];
        NSString *newSign = [NSString stringWithUTF8String:channel.appSign];
        NSString *command = [NSString stringWithFormat:@"sed -ie 's/%@/%@/g' %@",oldSign,newSign,configPath];
        runCommand(command, nil);
    }
    
    return YES;
}

void recoveryChannelConfig()
{
    //backup
    NSString *paths = [NSString stringWithUTF8String:original.iconPaths];
    NSMutableArray *array = [[paths componentsSeparatedByString:@"|"] mutableCopy];
    
    //过滤掉空字符串
    for (NSInteger i = array.count-1; i>=0; i--) {
        if ([array[i] length] == 0) {
            [array removeObjectAtIndex:i];
        }
    }
    
    for (NSString *path in array) {
        if (path.length > 0) {
            NSString *backupImagePath = [NSString stringWithFormat:@"%@/%@",backupPath,[path lastPathComponent]];
            NSString *command = [NSString stringWithFormat:@"mv %@ %@",backupImagePath,originalImagePath];
            runCommand(command, nil);
        }
    }
    
    if (plistPath.length > 0) {
        NSString *displayName = [NSString stringWithUTF8String:original.displayName];
        NSString *command = [NSString stringWithFormat:@"/usr/libexec/PlistBuddy -c \"Set :CFBundleDisplayName '%@'\" \"%@\"",
                             displayName,plistPath];
        runCommand(command, nil);
    }
    
    if (configPath.length > 0) {
        NSString *command = [NSString stringWithFormat:
                             @"cat %@ |grep \"#define kAppSign\"|sed \'s/#define kAppSign @\"\\(.*\\)\"/\\1/g\'",
                             configPath];
        NSString *oldSign = trim(runCommand(command, nil));
        
        NSString *newSign = [NSString stringWithUTF8String:original.appSign];
        command = [NSString stringWithFormat:@"sed -ie 's/%@/%@/g' %@",oldSign,newSign,configPath];
        runCommand(command, nil);
    }
    
    //去掉sed命令的备份文件
    NSString *path = [NSString stringWithFormat:@"%@e",configPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
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
