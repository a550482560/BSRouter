//
//  BSCore.h
//  BSRouter
//
//  Created by LUU on 2021/12/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BSCore : NSObject

/** 组件列表 */
@property (nonatomic, strong) NSMutableArray *components;

@property (nonatomic, strong) NSDictionary *context;

/** app_id */
@property(nonatomic, copy) NSString * app_id;
/** secret_key */
@property(nonatomic, copy) NSString * secret_key;
/** app_host */
@property(nonatomic, copy) NSString * app_host;

/**
 * @brief 单例方法。
 * @return 返回单例对象。
 */
+ (instancetype)sharedInstance;

/**
 * @brief 向Core注册模块的方法。
 * @param componentClass 组件类
 */
+ (BOOL)registerComponentClass:(Class)componentClass;

/**
 * @brief 加载Config.plist
 */
+ (void)loadConfig;


/*！
 * 用来获得当前sdk的版本号
 * return 返回sdk版本号
 */
+ (NSString *) sdkVersion;

/*！
 *  注册app
 *  @param app_id       后台注册生成的app_id
 *  @param secretKey    后台注册生成的secret_key
 *
 */
+ (void)registerApp_id:(NSString *)app_id secret_key:(NSString *)secret_key app_host:(NSString *)app_host host_web:(NSString *)host_web;

/*!
 *  是否开启日志
 *  @param open 是否开启日志，默认 false
 */
+(void)openSDKDebug:(BOOL)open;



/// 打印除BSCore和BSUICore之外其他所有组件
+ (void)printAllComponent;



/// 判断某个组件是否加载
/// @param name 组件名
+ (BOOL)isLoadedComponentName:(NSString *)name;

// 加载主框架
+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
@end

NS_ASSUME_NONNULL_END

