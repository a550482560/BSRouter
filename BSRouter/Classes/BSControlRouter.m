//
//  BSControlRouter.m
//  BSRouter
//
//  Created by LUU on 2021/12/10.
//

#import "BSControlRouter.h"
#import "BSComponentProtocol.h"
#import "BSCore.h"
#import "BSRouter.h"

@implementation BSControlRouter

+ (instancetype)sharedControlRouter {
    static BSControlRouter *router = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!router) {
            router = [[BSControlRouter alloc] init];
            /// - BSRouter 配置
            BSRouter * router = [BSRouter sharedRouter];
            router.presentNavcClass = [UINavigationController class];
            router.url_scheme = @"BSRouter";
            for (id<BSComponentProtocol>component in [BSCore sharedInstance].components) {
                for (NSMutableDictionary * dic in component.componentViewControllers) {
                    [router addMapperDic:dic];
                }
            }
        }
    });
    return router;
}

/**
 * 进入模
 * key 代表模块标识 列如:"login"
 */
+ (id)enterRomm:(NSString *)key isPush:(BOOL)isPush params:(id _Nullable)passParams callBlock:(BSControlRouterCallBlock _Nullable)callBlock
{
    if (isPush) {
        return [BSRouter bs_pushVCName:key params:passParams callBlock:callBlock];
    }else{
        return [BSRouter bs_presentVCName:key params:passParams callBlock:callBlock];
    }
}

+ (id)getRomm:(NSString *)key params:(id _Nullable)passParams callBlock:(BSControlRouterCallBlock _Nullable)callBlock
{
    return [BSRouter bs_getVCKey:key params:passParams callBlock:callBlock];
}

+ (void)sendParameterControl:(id _Nullable)control
                      params:(id _Nullable)passParams
{
    [BSRouter bs_sendParameterControl:control params:passParams];
}
@end
