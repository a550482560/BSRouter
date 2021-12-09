//
//  BSRouter.h
//  BSKit
//
//  Created by LUU on 2021/11/11.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


/// 获取应用当前的控制器
UIViewController * _Nullable YHCurrentViewController(void);
extern NSString * _Nonnull const kSwiftTargetModuleName;


NS_ASSUME_NONNULL_BEGIN


#pragma mark - -------------------


@protocol BSRouterProtocol <NSObject>

@optional
/** 需要传参的时候 下方实现一个就可*/
/** 实例*/
+ (instancetype)bs_routerCreateViewController:(id)parameters;

/// 配置参数
- (void)bs_routerPassParamViewController:(id)parameters;

/// 接收或者更新数据
- (void)bs_updateParamToParameters:(id)parameters;

/// 该页面是否要显示 将要显示控制器 配置参数
/// 比如：如果当前再订单详情页 当前订单界面是否刷新还是再叠加一个新的界面
- (BOOL)bs_routerReloadViewController_shoudShowNext:(id)parameters;

/// 是否需要登录
- (BOOL)bs_routerNeedLogin;


@end







#pragma mark - -------------------

typedef void(^BSRouterCallBlock)(id _Nullable passResult);

/** 弹出控制器的回调*/
@interface UIViewController (YHBRouter)<BSRouterProtocol>

/** 回调*/
@property (nonatomic, copy) BSRouterCallBlock routerCallBlock;


@end


/** 弹出控制器的回调*/
@interface UIView (YHBRouter)<BSRouterProtocol>

/** 回调*/
@property (nonatomic, copy) BSRouterCallBlock routerCallBlock;


@end


#pragma mark - -------------------



/** 跳转路由*/
@interface BSRouter : NSObject

@property (nonatomic, weak) UINavigationController * currentNavigationController;
@property (nonatomic, weak) UIViewController * currentViewController;

/**
 在传入 URL的情况下
 如果有设置 不是这个scheme类型 都过滤掉
 未 设置不做过滤
 */
@property (copy, nonatomic) NSString * url_scheme;

/// present视图加载导航条控制器 要是Navigation子类 不设置 默认UINavigationController
@property (assign, nonatomic) Class presentNavcClass;

/// 需要的控制器 去登录状态判断
/// BOOL 返回当前登录的状态
@property (copy, nonatomic) BOOL (^needLoginBlock)(void);

/// 外部链接打开 判断这个host是否需要单独处理
/// BOOL 返回是否继续下一步跳转控制器处理
@property (copy, nonatomic) BOOL (^URLOpenHostContinuePushBlock)(NSString * vchost, NSDictionary * params);

/// 打开链接 可通过该key查找控制器名字 如果为空取链接的host信息
@property (copy, nonatomic) NSString * linkURLPageKey;


+ (instancetype)sharedRouter;

/// 跳转控制器映射
/// mapKey 可以是字符串 可以是 number类型 可以是包含字符串和number的数组
- (void)addMapperVC:(NSString *)vcName mapKey:(id)mapKey;
- (void)addMapperDic:(NSDictionary<NSString *, id> *)mapperDic;


//===================

+ (id)bs_pushVCName:(NSString *)vcName;
+ (id)bs_pushVCName:(NSString *)vcName params:(id _Nullable)passParams callBlock:(BSRouterCallBlock _Nullable)callBlock;

+ (id)bs_presentVCName:(NSString *)vcName;
+ (id)bs_presentVCName:(NSString *)vcName params:(id _Nullable)passParams callBlock:(BSRouterCallBlock _Nullable)callBlock;

//=================== URL

/**
 通过URL跳转 内部含 控制器名称的参数信息
 [BSRouter bs_openSchemeURL:@"mocr://quick?id=12&type=22"];
 quick是key 映射BSRouterMapper 后面是参数
 */
+ (id)bs_openSchemeURL:(NSString *)routePattern isPush:(BOOL)isPush;

/**
 通过URL跳转 内部含 控制器名称的参数信息
 https://host?page=helpCenter
 跳转page
 */
+ (id)bs_openLinkURL:(NSString *)routePattern;

/// 获取控件 不做跳转
+ (id)bs_getVCKey:(NSString *)vcKey params:(id _Nullable)passParams callBlock:(BSRouterCallBlock _Nullable)callBlock;

/// 给组件更新或者传递新的数据
+ (void)bs_sendParameterControl:(id _Nullable)control
                         params:(id _Nullable)passParams;


// 远程App调用入口
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion;
// 本地组件调用入口
- (id _Nullable )performTarget:(NSString * _Nullable)targetName action:(NSString * _Nullable)actionName params:(NSDictionary * _Nullable)params shouldCacheTarget:(BOOL)shouldCacheTarget;
- (void)releaseCachedTargetWithFullTargetName:(NSString * _Nullable)fullTargetName;

@end
NS_ASSUME_NONNULL_END

// 简化调用单例的函数
BSRouter* _Nonnull BSR(void);

