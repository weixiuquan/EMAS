//
//  AppDelegate.m
//  EMASDemo
//
//  Created by EMAS on 2017/12/7.
//  Copyright © 2017年 EMAS. All rights reserved.
//

#import "AppDelegate.h"

// --自初始化头文件
#import <AliEMASConfigure/AliEMASConfigure.h>

// --基础库头文件
#import <UT/UTAnalytics.h>
#import <UT/AppMonitor.h>
#import <NetworkSDK/NetworkCore/NWNetworkConfiguration.h>
#import <NetworkSDK/NetworkCore/NetworkDemote.h>
#import <NetworkSDK/NetworkCore/NWuserLoger.h>
#import <NetworkSDK/AliReachability/NWLog.h>

// --ACCS头文件
#import <TBAccsSDK/TBAccsManager.h>

// --PUSH头文件
#import <PushCenterSDK/TBSDKPushCenterConfiguration.h>
#import <PushCenterSDK/TBSDKPushCenterEngine.h>

// --高可用头文件
#import <AliHAAdapter4poc/AliHAAdapter.h>
#import <AliHASecurity/AliHASecurity.h>
#import <TRemoteDebugger/TRDManagerService.h>
#import <TBRest/TBRestSendService.h>

// --网关头文件
#import <MtopSDK/MtopSDK.h>
#import <MtopCore/MtopService.h>
#import <MtopCore/TBSDKConfiguration.h>

#import "EMASWXSubSDKEngine.h"

// --weex灰度头文件
#import <DynamicConfigurationAdaptor/DynamicConfigurationAdaptorManager.h>

// --远程配置
#import <orange/orange.h>
#import <orange/OrangeLog.h>

// --读取配置
#import "EMASService.h"

// --ZCache
#import <ZCache/ZCache.h>

// --ViewController
#import "EMASHostViewController.h"
#import "EMASTabBarController.h"
#import "EMASNativeViewController.h"
#import "EMASBaseNavigationController.h"
#import "EMASWeexContainerService.h"

@interface MyPolicyCenter : NSObject <NWPolicyDelegate>
@end

@implementation MyPolicyCenter

- (nullable NWPolicy *)queryPolicy:(nonnull NSString *)host
                        withScheme:(nonnull NSString *)scheme
                  withAcceleration:(BOOL)acceleration
                  withSuccessAisle:(BOOL)success {
    if ([host isEqualToString:[[EMASService shareInstance] ACCSDomain]] && acceleration==YES) {
        
        NSString *strategy = [[[EMASService shareInstance] IPStrategy] objectForKey:host];
        NSArray *ipPort = [strategy componentsSeparatedByString:@":"];
        if ([ipPort count] != 2)
        {
            return nil;
        }
        NSString *ip = [ipPort objectAtIndex:0];
        NSString *port = [ipPort objectAtIndex:1];
        NWAisle *aisle = [NWAisle new];
        aisle.protocol = @"http2";
        aisle.ip = ip;
        aisle.port = [port intValue];
        aisle.encrypt = YES;
        aisle.auth = YES;
        aisle.publickey = @"emas";
        
        NWPolicy *policy = [NWPolicy new];
        policy.type = kNWAislePolicy;
        policy.host = host;
        policy.aisles = @[ aisle ];
        
        return policy;
    }
    
    return nil;
}

- (nullable NSString *)queryScheme:(nonnull NSString *)host {
    // 如果需要对该域名的所有请求的url的scheme进行修改，可以在这里进行
    
    // 所有 www.abc.com 的域名使用 https
    if ([host isEqualToString:[[EMASService shareInstance] ACCSDomain]]) {
        return @"https";
    }
    // 所有 www.xyz.com 的域名使用 http
    if ([host isEqualToString:[[EMASService shareInstance] MTOPDomain]]) {
        return @"http";
    }
    // 没有需求的直接返回nil
    return nil;
}

- (nonnull NSString *)queryCname:(nonnull NSString *)host {
    return host;
}

- (void)updateAisleStatus:(nonnull NWAisle *)aisle
                 withHost:(NSString*)host
               withStatus:(NWAisleStatus)status {
    // do something
}

- (nullable NWPolicy *)queryPolicy:(nonnull NSString *)host {
    return nil;
}

@end

@interface AppDelegate ()
@property(nonatomic,strong) MyPolicyCenter *policyCenter;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [AliEMASConfigure configure];
    
    self.window.backgroundColor = [UIColor whiteColor];
    
    // 0. 打开网络库日志
    [NWLog setLogLevel:NW_LOG_DEBUG];
    
    // 1. 先初始化基础库
    [self initCommonConfig];
    
    // 2. 初始化高可用，高可用依赖基础库和ACCS，因此高可用的初始化顺序为，基础库->ACCS->高可用
    [self initAccsConfig];
    [self initHAConfig];
    
    // 3. 初始化Weex，Weex依赖基础库、网关和高可用，因此Weex的初始化顺序为，基础库->高可用->网关->远程配置->ZCache->Weex
    //[self initRemoteConfig];
    [self initMtopConfig];
    [self initZCacheConfig];
    
    // 4. 初始化PUSH
    [self initPushConfig];
    
    [EMASWXSubSDKEngine setup];
    
    [self initDyConfig];
    
    [self showMainViewController];
    
    return YES;
}

#pragma mark -
#pragma mark 显示视图

- (void)showMainViewController
{
    NSNumber *tabSize = [[EMASWeexContainerService shareInstance] tabSize];
    NSInteger tabSizeInt = tabSize.integerValue;
    if (!tabSize || tabSizeInt < 0) {
        //Native脚手架
    } else if (tabSizeInt == 0) {
        [self showBlankViewController];
    } else if (tabSizeInt == 1) {
        [self showSingleViewController];
    } else {
        [self showTabBarViewController];
    }
}

- (void)showSingleViewController
{
    NSDictionary *jsSourceDic = [[EMASWeexContainerService shareInstance] jsSource];
    NSString *url = [jsSourceDic objectForKey:@"0"];
    
    EMASHostViewController *viewController = [[EMASHostViewController alloc] initWithNavigatorURL:[NSURL URLWithString:url]];
    self.window.rootViewController = [[WXRootViewController alloc] initWithRootViewController:viewController];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

- (void)showTabBarViewController
{
    EMASTabBarController *tabBarViewController = [[EMASTabBarController alloc] init];
    [self.window setRootViewController:tabBarViewController];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

- (void)showBlankViewController
{
    EMASNativeViewController *viewController = [[EMASNativeViewController alloc] init];
    self.window.rootViewController = [[EMASBaseNavigationController alloc] initWithRootViewController:viewController];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
}

#pragma mark -
#pragma mark SDK初始化

// 基础库
- (void)initCommonConfig
{
    NSString *scheme = @"https";
    if ([[EMASService shareInstance] useHTTP])
    {
        scheme = @"http";
    }
    
    // UT初始化部分
    [[UTAnalytics getInstance] turnOffCrashHandler];
    [[UTAnalytics getInstance] turnOnDebug]; // 打开调试日志
    [[UTAnalytics getInstance] setTimestampHost:[[EMASService shareInstance] HATimestampHost] scheme:scheme];
    [[UTAnalytics getInstance] setAppKey:[[EMASService shareInstance] appkey] secret:[[EMASService shareInstance] appSecret]];
    [[UTAnalytics getInstance] setChannel:[[EMASService shareInstance] ChannelID]];
    [[UTAnalytics getInstance] setAppVersion:[[EMASService shareInstance] getAppVersion]];
    [AppMonitor disableSample]; // 调试使用，上报不采样，建议正式发布版本不要这么做
}

// ACCS
- (void)initAccsConfig
{
    // ACCS初始化部分
    void tbAccsSDKSwitchLog(BOOL logCtr);
    tbAccsSDKSwitchLog(YES); // 打开调试日志
    
    // ACCS 通过配置文件自初始化
    TBAccsManager *accsManager = [TBAccsManager accsManagerByConfigureName:nil];
    [accsManager startAccs];
    
    [accsManager bindAppWithAppleToken: nil
                              callBack:^(NSError *error, NSDictionary *resultsDict) {
                                  if (error) {
                                      NSLog(@"\n\n绑定App出错了 %@\n\n", error);
                                  }
                                  else {
                                      NSLog(@"\n\n绑定App成功了\n\n");
                                  }
                              }];
}

// PUSH
- (void)initPushConfig
{
    // PUSH 通过配置文件自初始化
    TBSDKPushCenterEngine *pce = [TBSDKPushCenterEngine sharedInstanceWithDefaultConfigure];
    [pce start];
    
    // register notification setting
    [self registerNotificationSetting];
}

- (void)registerNotificationSetting {
    //registerUserNotificationSettings function must be used from main thread only
    [[UIApplication sharedApplication] registerUserNotificationSettings:
         [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge)
                                           categories:nil]];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    NSLog(@"[APNS] registerNotificationSetting");
}

//-- 高可用
- (void)initHAConfig
{
    NSString *scheme = @"https";
    if ([[EMASService shareInstance] useHTTP])
    {
        scheme = @"http";
    }
    
    // 高可用初始化部分
    // 如果需要重公钥，请一定要放到初始化前！！！
    NSString *rasPublicKey = [[EMASService shareInstance] HARSAPublicKey];
    if (rasPublicKey.length)
    {
        [[AliHASecurity sharedInstance] initWithRSAPublicKey:rasPublicKey];
    }
    [AliHAAdapter initWithAppKey:[[EMASService shareInstance] appkey]
                      appVersion:[[EMASService shareInstance] getAppVersion]
                         channel:[[EMASService shareInstance] ChannelID]
                         plugins:nil
                            nick:@"emas-ha"]; // nick根据app实际情况填写
    [AliHAAdapter configOSS:[[EMASService shareInstance] HAOSSBucketName]];
    [AliHAAdapter setupAccsChannel:[[EMASService shareInstance] ACCSDomain] serviceId:[[EMASService shareInstance] HAServiceID]];
    [AliHAAdapter setupRemoteDebugRPCChannel:[[EMASService shareInstance] HAUniversalHost] scheme:scheme];
    
    TBRestConfiguration *restConfiguration = [[TBRestConfiguration alloc] init];
    restConfiguration.appkey = [[EMASService shareInstance] appkey];
    restConfiguration.appVersion = [[EMASService shareInstance] getAppVersion];
    restConfiguration.channel = [[EMASService shareInstance] ChannelID];
    restConfiguration.usernick = @"emas-ha"; // nick根据app实际情况填写
    if ([[EMASService shareInstance] useHTTP])
    {
        restConfiguration.dataUploadScheme = @"http";
    }
    restConfiguration.dataUploadHost = [[EMASService shareInstance] HAUniversalHost];
    [[TBRestSendService shareInstance] configBasicParamWithTBConfiguration:restConfiguration];
}

// 网关
- (void)initMtopConfig
{
    // MTOP初始化部分
    TBSDKConfiguration *config = [TBSDKConfiguration shareInstanceDisableDeviceID:YES andSwitchOffServerTime:YES];
    config.environment = TBSDKEnvironmentRelease;
    if ([[EMASService shareInstance] useHTTP])
    {
        config.enableHttps = NO;
    }
    config.safeSecret = NO;
    config.appKey = [[EMASService shareInstance] appkey];
    config.appSecret = [[EMASService shareInstance] appSecret];
    config.wapAPIURL = [[EMASService shareInstance] MTOPDomain];//设置全局自定义域名
    config.wapTTID = [[EMASService shareInstance] ChannelID]; //渠道ID
    openSDKSwitchLog(YES); // 打开调试日志
}

- (void)initZCacheConfig
{
#ifdef DEBUG
    [ZCache setDebugMode:YES]; // 打开调试日志
#endif
    [ZCache setupWithMtop];
    [ZCache defaultCommonConfig].packageZipPrefix = [[EMASService shareInstance] ZCacheURL];
}

// -- dy 初始化
- (void)initDyConfig
{
    NSString * logicIdentifier = [NSString stringWithFormat:@"%@@%@",[[EMASService shareInstance] appkey],[self isDeviceIphone]?@"iphoneos":@"iPad"];
    [[DynamicConfigurationAdaptorManager sharedInstance] setUpWithMaxUpateTimesPerDay:10 AndIdentifier:logicIdentifier];
}

// 初始化Orange

- (void)initRemoteConfig {
    EMASService *service = [EMASService shareInstance];
    openOrangeLog(OrangeLogLevel_ALL);
    [Orange setOrangeDataCenterOnlineHost:service.RemoteConfigHost debugHost:service.RemoteConfigHost dailyHost:service.RemoteConfigHost];
    [Orange setOrangeBetaModeAccsHost:@[service.ACCSDomain,service.ACCSDomain,service.ACCSDomain]];
    [Orange runMode:OrangeUpateModeEvent];

    
}

#pragma mark -
#pragma mark app生命周期

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // 收到APNS token时回调
    NSLog(@"[APNS] device token: %@", deviceToken);
    
    TBSDKPushCenterEngine *pce = [TBSDKPushCenterEngine sharedInstanceWithDefaultConfigure];
    [pce upLoaderDeviceToken:deviceToken userInfo:nil callback:^(NSDictionary *result, NSError *error){
        if ( error ) {
            NSLog(@"[APNS] update token error: %@", error);
        }
        else {
            NSLog(@"[APNS] update token successfully!");
        }
    }];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"[APNS] register error: %@", error);
}

#pragma mark - distinguish device
- (BOOL) isDeviceIphone {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return NO;
    }
    return YES;
}

@end

