//
//  BSControlRouter.h
//  BSRouter
//
//  Created by LUU on 2021/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BSControlRouterCallBlock)(id _Nullable passResult);

@protocol BSControlRouterDelegate <NSObject>



@end

@interface BSControlRouter : NSObject

+ (instancetype)sharedControlRouter;


/**
 * 进入模块
 * key 代表模块标识 例如:"login"
 * isPush 0:present跳转 1:push跳转
 * pramer 代表模块需要参数 例如:@{@"id":@"1",@"isBool":@"0"}
 * callBlock 模块返回的参数 例如:@"哈喽"
 */
+ (id)enterRomm:(NSString *)key isPush:(BOOL)isPush params:(id _Nullable)passParams callBlock:(BSControlRouterCallBlock _Nullable)callBlock;

/**
 * 获取模块
 * key 代表模块标识 例如:"login"
 * pramer 代表模块需要参数 例如:@{@"id":@"1",@"isBool":@"0"}
 * callBlock 模块返回的参数 例如:@"哈喽"
 */
+ (id)getRomm:(NSString *)key params:(id _Nullable)passParams callBlock:(BSControlRouterCallBlock _Nullable)callBlock;

/**
 * 给组件更新或者传递新的数据
 * targetName 代表模块标识 例如:"login"
 * control 模块控价 例如:loginViewController
 * pramer 代表模块需要参数 例如:@{@"id":@"1",@"isBool":@"0"}
 */
+ (void)sendParameterControl:(id _Nullable)control
                      params:(id _Nullable)passParams;

@end

NS_ASSUME_NONNULL_END
