//
//  BSRouter.m
//  BSKit
//
//  Created by LUU on 2021/11/11.
//

#import "BSRouter.h"

#import <objc/runtime.h>
#import <CoreGraphics/CoreGraphics.h>
NSString * const kSwiftTargetModuleName = @"kCTMediatorParamsKeySwiftTargetModuleName";

#define BSRouterLog(format, ...) NSLog((@"BSRouter >>> " format), ##__VA_ARGS__)

#pragma mark - UINavigationController+BSRouter


UIViewController * YHCurrentViewController(void){
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal){
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows){
            if (tmpWin.windowLevel == UIWindowLevelNormal){
                window = tmpWin;
                break;
            }
        }
    }
    UIViewController *result = window.rootViewController;
    while (result.presentedViewController) {
        result = result.presentedViewController;
    }
    if ([result isKindOfClass:[UITabBarController class]]) {
        result = [(UITabBarController *)result selectedViewController];
    }
    if ([result isKindOfClass:[UINavigationController class]]) {
        result = [(UINavigationController *)result topViewController];
    }
    return result;
}

BOOL IsNull(id obj){
    if(!obj){
        return YES;
    }
    if(obj == nil || [obj isEqual:[NSNull class]] || [obj isKindOfClass:[NSNull class]]){
        return YES;
    }
    if([obj isKindOfClass:[NSString class]]){
        NSString * str = (NSString *)obj;
        if([str isEqualToString:@""]){
            return YES;
        }
        if ([[str stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]){
            return YES;
        }
    }
    return NO;
}

void BSRouter_swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


@interface UINavigationController (BSRouter)

@end

@implementation UINavigationController (BSRouter)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        BSRouter_swizzleMethod(class, @selector(viewWillAppear:), @selector(router_navigationViewWillAppear:));
    });
}

- (void)router_navigationViewWillAppear:(BOOL)animation {
    [self router_navigationViewWillAppear:animation];
    
    if([BSRouter sharedRouter].currentNavigationController){
        [[BSRouter sharedRouter] setValue:[BSRouter sharedRouter].currentNavigationController forKey:@"preNavc"];
    }
    [BSRouter sharedRouter].currentNavigationController = self;
    
}


@end



@implementation UIViewController(YHBRouter)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        BSRouter_swizzleMethod(class, @selector(viewWillAppear:), @selector(router_ViewWillAppear:));
    });
}

- (void)router_ViewWillAppear:(BOOL)animation {
    [self router_ViewWillAppear:animation];
    
    if(self.navigationController){
        if([BSRouter sharedRouter].currentNavigationController){
            [[BSRouter sharedRouter] setValue:[BSRouter sharedRouter].currentNavigationController forKey:@"preNavc"];
        }
        [BSRouter sharedRouter].currentNavigationController = self.navigationController;
    }
}

-(BSRouterCallBlock)routerCallBlock{
    return objc_getAssociatedObject(self, @selector(routerCallBlock));
}

-(void)setRouterCallBlock:(BSRouterCallBlock)routerCallBlock{
    objc_setAssociatedObject(self, @selector(routerCallBlock), routerCallBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end


@implementation UIView(YHBRouter)

-(BSRouterCallBlock)routerCallBlock{
    return objc_getAssociatedObject(self, @selector(routerCallBlock));
}

-(void)setRouterCallBlock:(BSRouterCallBlock)routerCallBlock{
    objc_setAssociatedObject(self, @selector(routerCallBlock), routerCallBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end



#pragma mark - BSRouter

@interface BSRouter()

@property (weak, nonatomic) UINavigationController * preNavc;

@property (retain, nonatomic) NSMutableDictionary <NSString *, id> * mapper;
@property (nonatomic, strong) NSMutableDictionary *cachedTarget;

@end


@implementation BSRouter


+ (instancetype)sharedRouter {
    static BSRouter *router = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!router) {
            router = [[BSRouter alloc] init];
            router.url_scheme = @"";
            router.mapper = [NSMutableDictionary new];
            [router cachedTarget]; // ?????????cachedTarget??????????????????????????????????????????
        }
    });
    return router;
}

-(UIViewController *)currentViewController{
    return YHCurrentViewController();
}

/// ?????????????????????
- (void)addMapperVC:(NSString *)vcName mapKey:(id)mapKey{
    if(IsNull(vcName) || IsNull(mapKey)){
        return;
    }
    self.mapper[vcName] = mapKey;
}
- (void)addMapperDic:(NSDictionary<NSString *, id> *)mapperDic{
    [self.mapper addEntriesFromDictionary:mapperDic];
}

#pragma mark - key mapper

- (NSString *)mapperController:(NSString *)mapper{
    
    __block NSString * reslutMapper = mapper;
    
    NSDictionary * customMapper = self.mapper;
    [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *propertyName, NSString *mappedToKey, BOOL *stop) {

        if ([mappedToKey isKindOfClass:[NSString class]]) {
            
            if([mappedToKey isEqualToString:mapper]){
                reslutMapper = propertyName;
                return;
            }
            
        } else if ([mappedToKey isKindOfClass:[NSArray class]]) {

            for (NSString *oneKey in ((NSArray *)mappedToKey)) {
                if([oneKey isKindOfClass:[NSString class]]){
                    if([oneKey isEqualToString:mapper]){
                        reslutMapper = propertyName;
                        return;
                    }
                }else if ([oneKey isKindOfClass:[NSNumber class]]){
                    NSNumber * oneKeyNum = (NSNumber *)oneKey;
                    if([oneKeyNum.stringValue isEqualToString:mapper]){
                        reslutMapper = propertyName;
                        return;
                    }
                }
            }
        }
    }];
    
    return reslutMapper;
}


#pragma mark -



//=================== Push

+ (id)bs_pushVCName:(NSString *)vcName{
    
    return [BSRouter bs_pushVCName:vcName params:nil callBlock:nil];
}

+ (id)bs_pushVCName:(NSString *)vcName params:(id)passParams callBlock:(BSRouterCallBlock)callBlock{
    if(vcName && vcName.length > 0){
        BSRouter * router = [BSRouter sharedRouter];
        id model = [router bs_getControllerByVCName:vcName queryParams:passParams callBlock:callBlock];
        if ([model isKindOfClass:[UIViewController class]]) {
            UIViewController * vc = model;
            vc.routerCallBlock = callBlock;
            if (!vc) {
                BSRouterLog(@"?????? ?????? %@",vcName);
                return nil;
            }
            
            void (^push)(void) = ^void () {
                if(router.currentNavigationController){
                    [router.currentNavigationController pushViewController:vc animated:YES];
                }else if ([router valueForKey:@"preNavc"]){
                    UINavigationController * navc = [router valueForKey:@"preNavc"];
                    [navc pushViewController:vc animated:YES];
                }else if (router.currentViewController.navigationController){
                    UINavigationController * navc = router.currentViewController.navigationController;
                    [navc pushViewController:vc animated:YES];
                } else{
                    vc.modalPresentationStyle = UIModalPresentationFullScreen;
                    [router.currentViewController presentViewController:vc animated:YES completion:nil];
                    BSRouterLog(@"???????????????????????????");
                }
            };
            SEL selectorLogin = NSSelectorFromString(@"bs_routerNeedLogin");
            if([vc respondsToSelector:selectorLogin]){
                BOOL needLogin = [vc bs_routerNeedLogin];
                
                if (needLogin &&
                    router.needLoginBlock &&
                    !router.needLoginBlock()) {
                    
                    return vc;
                }
            }
            push();
            
            return vc;
        }else{
            return model;
        }
    }else{
        BSRouterLog(@"??????????????? %@ ?????????",vcName);
        return nil;
    }
}

+ (id)bs_presentVCName:(NSString *)vcName{
    return [BSRouter bs_presentVCName:vcName params:nil callBlock:nil];
}

+ (id)bs_presentVCName:(NSString *)vcName params:(id)passParams callBlock:(BSRouterCallBlock)callBlock{

    if(vcName && vcName.length > 0){
        
        BSRouter * router = [BSRouter sharedRouter];
        id model = [router bs_getControllerByVCName:vcName queryParams:passParams callBlock:callBlock];
        if ([model isKindOfClass:[UIViewController class]]) {
            UIViewController * vc = model;
            vc.routerCallBlock = callBlock;
            if (!vc) {
                BSRouterLog(@"?????? ?????? %@",vcName);
                return nil;
            }
            
            if(router.currentNavigationController){
                UINavigationController * navc;
                if(router.presentNavcClass &&
                   [router.presentNavcClass isSubclassOfClass:[UINavigationController class]]
                   ){
                    navc = [router.presentNavcClass new];
                }else{
                    navc = [UINavigationController new];
                }
                [navc setViewControllers:@[vc] animated:NO];

                navc.modalPresentationStyle = UIModalPresentationFullScreen;
                [router.currentNavigationController presentViewController:navc animated:YES completion:nil];
            }else{
                vc.modalPresentationStyle = UIModalPresentationFullScreen;
                [router.currentViewController presentViewController:vc animated:YES completion:nil];
            }

            return vc;
        }else{
            return model;
        }
    }else{
        BSRouterLog(@"??????????????? %@ ?????????",vcName);
        return nil;
    }
}


#pragma mark - URL route

/** ??????URL?????? ????????? ??????????????????????????????*/
+ (id)bs_openSchemeURL:(NSString *)routePattern isPush:(BOOL)isPush{

    NSURLComponents *components = [NSURLComponents componentsWithString:routePattern];
    NSString *scheme = components.scheme;
    
    //scheme??????????????????
    if([BSRouter sharedRouter].url_scheme){
        if (![scheme isEqualToString:[BSRouter sharedRouter].url_scheme]) {
            BSRouterLog(@"scheme???????????????");
            return nil;
        }
    }
    
    NSString * vcHost = nil;
    
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        vcHost = [components.percentEncodedHost copy];
        components.host = @"/";
        components.percentEncodedPath = [vcHost stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
    }
    
    NSString *path = [components percentEncodedPath];
    
    if (components.fragment != nil) {
        BOOL fragmentContainsQueryParams = NO;
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
        
        if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
            fragmentComponents.query = fragmentComponents.path;
        }
        
        if (fragmentComponents.queryItems.count > 0) {
            fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
        }
        
        if (fragmentContainsQueryParams) {
            components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
        }
        
        if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
        }
    }
    
    if (path.length > 0 && [path characterAtIndex:0] == '/') {
        path = [path substringFromIndex:1];
    }
    
    if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
        path = [path substringToIndex:path.length - 1];
    }
    
    //??????queryItem
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary *params = queryParams.copy;
    if(!vcHost && [params isKindOfClass:[NSDictionary class]]){
        vcHost = params[@"vc"];
    }
    
    //??????????????????????????????
    if([BSRouter sharedRouter].URLOpenHostContinuePushBlock){
        BOOL continuePush = [BSRouter sharedRouter].URLOpenHostContinuePushBlock(vcHost, params);
        if(!continuePush){
            return nil;
        }
    }
    if (isPush) {
        return [BSRouter bs_pushVCName:vcHost params:params callBlock:nil];
    }else{
        return [BSRouter bs_presentVCName:vcHost params:params callBlock:nil];
    }
}
/** ??????URL?????? ????????? ??????????????????????????????*/
+ (id)bs_openLinkURL:(NSString *)routePattern {

    NSURLComponents *components = [NSURLComponents componentsWithString:routePattern];
    
    //??????queryItem
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary *params = queryParams.copy;
    
    NSString * page = nil;
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        page = [components.percentEncodedHost copy];
    }
    
    NSString * pageKey = [BSRouter sharedRouter].linkURLPageKey;
    if([params isKindOfClass:[NSDictionary class]] &&
       pageKey &&
       [params objectForKey:pageKey]){
        page = params[pageKey];
    }
    if (IsNull(page)) {
        page = [components.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    }
    
    //??????????????????????????????
    if([BSRouter sharedRouter].URLOpenHostContinuePushBlock){
        BOOL continuePush = [BSRouter sharedRouter].URLOpenHostContinuePushBlock(page, params);
        if(!continuePush){
            return nil;
        }
    }
    
    return [BSRouter bs_pushVCName:page params:params callBlock:nil];
}


#pragma mark - privite
/// ????????????
+ (id)bs_getVCKey:(NSString *)vcKey params:(id _Nullable)passParams callBlock:(BSRouterCallBlock _Nullable)callBlock
{
    BSRouter * router = [BSRouter sharedRouter];
    id model = [router bs_getControllerByVCName:vcKey queryParams:passParams callBlock:callBlock];
    if ([model isKindOfClass:[UIViewController class]]) {
        UIViewController * vc = model;
        vc.routerCallBlock = callBlock;
    }else if ([model isKindOfClass:[UIView class]]){
        UIView * view = model;
        view.routerCallBlock = callBlock;
        return view;
    }
    return model;
}
//????????????
- (id)bs_getControllerByVCName:(NSString *)targetName queryParams:(NSDictionary *)queryParams callBlock:(BSRouterCallBlock)callBlock{
    if(!targetName || targetName.length == 0){
        return nil;
    }

    targetName = [self mapperController:targetName];
    NSString * sbName = nil;
    NSString * vcName = targetName;
    if([targetName containsString:@"."]){
        sbName = [targetName componentsSeparatedByString:@"."].firstObject;
        vcName = [targetName componentsSeparatedByString:@"."].lastObject;
    }
    Class vcClass = NSClassFromString(vcName);
    if(!vcClass){
        BSRouterLog(@"??????????????? %@ ?????????",vcName);
        return nil;
    }
    //?????????????????????
    UIViewController * currentVC = [[BSRouter sharedRouter] currentViewController];
    for (UIView * views in currentVC.view.subviews) {
        if ([views isKindOfClass:vcClass]) {
            SEL selectorShow = NSSelectorFromString(@"bs_routerReloadViewController_shoudShowNext:");
            if([views respondsToSelector:selectorShow]){
                if(![views bs_routerReloadViewController_shoudShowNext:queryParams]){
                    return nil;
                }
            }
        }
    }
    if([currentVC isKindOfClass:vcClass]){
        SEL selectorShow = NSSelectorFromString(@"bs_routerReloadViewController_shoudShowNext:");
        if([currentVC respondsToSelector:selectorShow]){
            if(![currentVC bs_routerReloadViewController_shoudShowNext:queryParams]){
                //????????????
                BSRouterLog(@"?????????????????? %@ ???????????? ??????????????????",vcName);
                return nil;
            }
        }
    }
    
    SEL selectorCreate = NSSelectorFromString(@"bs_routerCreateViewController:");
    UIViewController *targetController;
    if(sbName){
        targetController = [[UIStoryboard storyboardWithName:sbName bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:vcName];
        if(!targetController){
            BSRouterLog(@"??? storyboard %@ ??????????????????????????? %@ ",sbName,vcName);
            return nil;
        }
        if(queryParams){
            SEL selectorConfig = NSSelectorFromString(@"bs_routerPassParamViewController:");
            if([targetController respondsToSelector:selectorConfig]){
                [targetController bs_routerPassParamViewController:queryParams];
            }
        }
    }else{
        if ([vcClass respondsToSelector:selectorCreate]) {
            targetController = [vcClass bs_routerCreateViewController:queryParams];
        }else{
            targetController = [vcClass new];
            
            if(queryParams){
                SEL selectorConfig = NSSelectorFromString(@"bs_routerPassParamViewController:");
                if([targetController respondsToSelector:selectorConfig]){
                    [targetController bs_routerPassParamViewController:queryParams];
                }
            }
        }
    }
    
    if(![targetController isKindOfClass:[UIViewController class]]){
        BSRouterLog(@"??????????????? %@ ",targetName);
    }
    
    return targetController;
}
/// ???????????????????????????????????????
+ (void)bs_sendParameterControl:(id _Nullable)control
                         params:(id _Nullable)passParams
{
    SEL selectorShow = NSSelectorFromString(@"bs_updateParamToParameters:");
    if([control respondsToSelector:selectorShow]){
        [control bs_updateParamToParameters:passParams];
    }
}

#pragma mark - public methods


/*
 scheme://[target]/[action]?[params]
 
 url sample:
 aaa://targetA/actionB?id=1234
 */

- (id)performActionWithUrl:(NSURL *)url completion:(void (^)(NSDictionary *))completion
{
    if (url == nil||![url isKindOfClass:[NSURL class]]) {
        return nil;
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:url.absoluteString];
    // ??????????????????
    [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.value&&obj.name) {
            [params setObject:obj.value forKey:obj.name];
        }
    }];
    
    // ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // ??????demo??????URL???????????????????????????????????????????????????target?????????method???????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}

- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params shouldCacheTarget:(BOOL)shouldCacheTarget
{
    if (targetName == nil || actionName == nil) {
        return nil;
    }
    
    NSString *swiftModuleName = params[kSwiftTargetModuleName];
    
    // generate target
    NSString *targetClassString = nil;
    if (swiftModuleName.length > 0) {
        targetClassString = [NSString stringWithFormat:@"%@.Target_%@", swiftModuleName, targetName];
    } else {
        targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    }
    NSObject *target = [self safeFetchCachedTarget:targetClassString];
    if (target == nil) {
        Class targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }

    // generate action
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil) {
        // ??????????????????????????????????????????????????????demo????????????????????????????????????????????????target????????????return????????????????????????????????????????????????????????????target???????????????????????????????????????????????????????????????
        [self NoTargetActionResponseWithTargetString:targetClassString selectorString:actionString originParams:params];
        return nil;
    }
    
    if (shouldCacheTarget) {
        [self safeSetCachedTarget:target key:targetClassString];
    }

    if ([target respondsToSelector:action]) {
        return [self safePerformAction:action target:target params:params];
    } else {
        // ?????????????????????????????????????????????????????????????????????????????????target???notFound??????????????????
        SEL action = NSSelectorFromString(@"notFound:");
        if ([target respondsToSelector:action]) {
            return [self safePerformAction:action target:target params:params];
        } else {
            // ????????????????????????????????????????????????notFound???????????????????????????demo?????????return???????????????????????????????????????????????????????????????target????????????
            [self NoTargetActionResponseWithTargetString:targetClassString selectorString:actionString originParams:params];
            @synchronized (self) {
                [self.cachedTarget removeObjectForKey:targetClassString];
            }
            return nil;
        }
    }
}

- (void)releaseCachedTargetWithFullTargetName:(NSString *)fullTargetName
{
    /*
     fullTargetName???oc??????????????????Target_XXXX????????????Target_????????????swift??????????????????XXXModule.Target_YYY??????????????????Target_?????????????????????????????????
     */
    if (fullTargetName == nil) {
        return;
    }
    @synchronized (self) {
        [self.cachedTarget removeObjectForKey:fullTargetName];
    }
}

#pragma mark - private methods
- (void)NoTargetActionResponseWithTargetString:(NSString *)targetString selectorString:(NSString *)selectorString originParams:(NSDictionary *)originParams
{
    SEL action = NSSelectorFromString(@"Action_response:");
    NSObject *target = [[NSClassFromString(@"Target_NoTargetAction") alloc] init];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"originParams"] = originParams;
    params[@"targetString"] = targetString;
    params[@"selectorString"] = selectorString;
    
    [self safePerformAction:action target:target params:params];
}

- (id)safePerformAction:(SEL)action target:(NSObject *)target params:(NSDictionary *)params
{
    NSMethodSignature* methodSig = [target methodSignatureForSelector:action];
    if(methodSig == nil) {
        return nil;
    }
    const char* retType = [methodSig methodReturnType];

    if (strcmp(retType, @encode(void)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        return nil;
    }

    if (strcmp(retType, @encode(NSInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(BOOL)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        BOOL result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(CGFloat)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        CGFloat result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

    if (strcmp(retType, @encode(NSUInteger)) == 0) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSig];
        [invocation setArgument:&params atIndex:2];
        [invocation setSelector:action];
        [invocation setTarget:target];
        [invocation invoke];
        NSUInteger result = 0;
        [invocation getReturnValue:&result];
        return @(result);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [target performSelector:action withObject:params];
#pragma clang diagnostic pop
}

#pragma mark - getters and setters
- (NSMutableDictionary *)cachedTarget
{
    if (_cachedTarget == nil) {
        _cachedTarget = [[NSMutableDictionary alloc] init];
    }
    return _cachedTarget;
}

- (NSObject *)safeFetchCachedTarget:(NSString *)key {
    @synchronized (self) {
        return self.cachedTarget[key];
    }
}

- (void)safeSetCachedTarget:(NSObject *)target key:(NSString *)key {
    @synchronized (self) {
        self.cachedTarget[key] = target;
    }
}


@end

BSRouter* _Nonnull BSR(void){
    return [BSRouter sharedRouter];
};

