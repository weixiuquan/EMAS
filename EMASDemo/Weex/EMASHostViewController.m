//
//  DemoWeexViewController.m
//  EMASDemo
//
//  Created by daoche.jb on 2018/6/28.
//  Copyright © 2018年 EMAS. All rights reserved.
//

#import "EMASHostViewController.h"
#import <objc/message.h>
#import <WeexSDK/WXDebugTool.h>
#import "UIViewController+EMASWXNaviBar.h"

@interface EMASHostViewController()

@property (nonatomic, copy) NSString *resourceUrlString;
@property (nonatomic, strong) UIWebView *webView;

@end

@implementation EMASHostViewController

- (void)dealloc {
    if (self.wxViewController) {
        [self.wxViewController removeFromParentViewController];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self = [self initWithNavigatorURL:[NSURL URLWithString:@""]];
    }
    return self;
}

- (instancetype)initWithNavigatorURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        if (!URL) {
            URL = [NSURL URLWithString:@""];
        }
        self.resourceUrlString = URL.absoluteString;
        NSString * urlString = self.resourceUrlString;//[[DynamicConfigurationManager sharedInstance] redirectUrl:[URL absoluteString]];
        self.wxViewController = [[EMASWXRenderViewController alloc] initWithNavigatorURL:[NSURL URLWithString:urlString] withCustomOptions:@{@"bundleUrl":urlString} withInitData:nil withViewController:self];
        //渲染容器的外部代理。
        self.wxViewController.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNaviBar];
    
    //务必设置这个属性，它与导航栏隐藏属性相关。
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    //在宿主容器中添加渲染容器和视图。
    [self.view addSubview:self.wxViewController.view];
    [self addChildViewController:self.wxViewController];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationRefreshInstance:) name:@"RefreshInstance" object:nil];
}

# pragma mark WXViewController Delegate

//内存报警时销毁非当前实例, 是否销毁通过配置下发。
- (void)wxDidReceiveMemoryWarning {
    id weex_memory_warning_destroy = @"1";
    if (weex_memory_warning_destroy && [@"1" isEqualToString:weex_memory_warning_destroy]) {
        if (self.wxViewController.isViewLoaded && [self.view window] == nil ) {
            [self.wxViewController.instance destroyInstance];
            self.wxViewController.instance = nil;
        }
    }
}

- (void)wxFinishCreateInstance {
    //Weex Instance创建成功
    [self.webView removeFromSuperview];
}

- (void)wxFailCreateInstance:(NSError *)error {
    //Weex Instance创建失败
//    if ([error.localizedDescription containsString:@"404"]) {
//        [[DynamicConfigurationManager sharedInstance] deleteConfigurationForGoalUrl:self.resourceUrlString];
//    }
}

- (void)wxFinishRenderInstance {
    //Weex Instance渲染完成
}

- (void)wxDegradeToH5:(NSString *)url
{
    [self.wxViewController.instance destroyInstance];
    [self.wxViewController.weexView removeFromSuperview];
    [self.webView removeFromSuperview];
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self.view addSubview:self.webView];
}


#pragma mark - websocket
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    if ([@"refresh" isEqualToString:message]) {
        [self.wxViewController refreshWeex];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    
}

#pragma mark - notification
- (void)notificationRefreshInstance:(NSNotification *)notification {
    [self.wxViewController refreshWeex];
}

@end


