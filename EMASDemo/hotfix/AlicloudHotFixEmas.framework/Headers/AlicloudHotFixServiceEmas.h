//
//  AlicloudHotFixService.h
//  hotfix-ios-sdk
//
//  Created by junmo on 2017/9/12.
//  Copyright © 2017年 junmo. All rights reserved.
//

#ifndef AlicloudHotFixServiceEmas_h
#define AlicloudHotFixServiceEmas_h

#import <Foundation/Foundation.h>

typedef void (^HotFixCallbackHandler)(BOOL res, id data, NSError *error);

@interface AlicloudHotFixServiceEmas : NSObject

/**
 获取热修复实例
 */
+ (instancetype)sharedInstance;

/**
 初始化SDK

 @param appId           应用AppId
 @param appSecret       应用AppSecret
 @param callback        回调
 */
- (void)initWithAppId:(NSString *)appId
            appSecret:(NSString *)appSecret
             callback:(HotFixCallbackHandler)callback;

/**
 手动设置补丁拉取时的App版本号，SDK初始化前调用
 (默认获取"CFBundleShortVersionString")
 
 @param appVersion App版本号
 */
- (void)setAppVersion:(NSString *)appVersion;

/**
 打开日志开关

 @param enabled YES: 打开日志； NO：关闭日志
 */
- (void)setLogEnabled:(BOOL)enabled;

/**
 从服务端加载补丁

 @param callback 回调
 */
- (void)loadPatch:(HotFixCallbackHandler)callback;

/**
 清空本地存储补丁
 */
- (void)cleanPatch;

/**
 设置服务地址
 */
- (void)setServerURL:(NSString *)url;

@end

#endif /* AlicloudHotFixServiceEmas_h */
