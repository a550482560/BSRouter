//
//  BSComponentProtocol.h
//  BSRouter
//
//  Created by LUU on 2021/12/10.
//

#import <UIKit/UIKit.h>

/**
 * 组件协议声明接口。该接口声明了做为一个组件
*/
@protocol BSComponentProtocol <NSObject>
 

- (NSString*)componentId;

//该组件注册入口类名
- (NSString*)componentName;

//该组件版本
- (NSString*)componentVersion;

//该组件描述
- (NSString*)componentDescription;

//该组件 控制器或view对应标识  如：@[@{key:value}...]  key:类名  value:标识
- (NSArray*)componentViewControllers;

@optional
//组件 load 时config参数
- (void)receiveLoadComponentConfigData:(NSDictionary*)data;
//是否是主框架
- (BOOL)isAppMainFramework;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
/// 加载聊天消息扩展
- (void)loadChatExtension;
@end

