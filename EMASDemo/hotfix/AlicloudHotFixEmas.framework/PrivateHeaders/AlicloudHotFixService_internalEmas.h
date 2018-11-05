//
//  AlicloudHotFixService_internal.h
//  hotfix-ios-sdk
//
//  Created by junmo on 2017/9/13.
//  Copyright © 2017年 junmo. All rights reserved.
//

#ifndef AlicloudHotFixService_internalEmas_h
#define AlicloudHotFixService_internalEmas_h

#import "AlicloudEmasConfiguration.h"

#import "AlicloudHotFixServiceEmas.h"
#import "HFXStore.h"

// 保证callback不为空且回调不在主线程上执行
#define NotNilCallback(callback, param1, param2, param3)\
if (callback) {\
if ([NSThread isMainThread]) {\
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\
callback(param1, param2, param3);\
});\
} else {\
callback(param1, param2, param3);\
}\
}

@interface AlicloudHotFixServiceEmas ()

- (void)setSDKEnvironment:(HFX_ENV_TYPE)env;
- (void)queryPatchByQrcodeURI:(NSString *)uri callback:(HotFixCallbackHandler)callback;
- (NSError *)loadLocalLuaFile:(NSString *)luaFilePath;
- (void)disableUserCheck;

@end

#endif /* AlicloudHotFixService_internalEmas_h */
