//
//  BSCore.m
//  BSRouter
//
//  Created by LUU on 2021/12/10.
//
#import "BSCore.h"
#import "BSControlRouter.h"
#import "BSComponentProtocol.h"

#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

@interface BSCore ()
/** //app主框架只有一个，默认为10003，如有其它主框架使用其它最后一个主框架*/
@property(nonatomic, strong) id<BSComponentProtocol> appMainFramework;
/** 配置文件中组件数据*/
@property(nonatomic, strong) NSMutableDictionary * componentsData;
@end

static dispatch_once_t loadAllComponents;

@implementation BSCore

#pragma mark - Public Methods
+ (instancetype)sharedInstance
{
    static dispatch_once_t predicate;
    static id instance = nil;
    dispatch_once(&predicate, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (BOOL)registerComponentClass:(Class)componentClass
{
    return [[BSCore sharedInstance] registerComponentClass:componentClass];
}

- (instancetype)init
{
    if (self = [super init]) {
        _components = [NSMutableArray array];
    }
    return self;
}
/*！
 * 用来获得当前sdk的版本号
 * return 返回sdk版本号
 */
+ (NSString *) sdkVersion
{
    return @"1.0";
}

/*！
 *  注册app
 *  @param app_id       后台注册生成的app_id
 *  @param secretKey    后台注册生成的secret_key
 *
 */
+ (void)registerApp_id:(NSString *)app_id secret_key:(NSString *)secret_key app_host:(NSString *)app_host host_web:(NSString *)host_web
{
    if(!app_id) {
        app_id = @"";
    }
    if(!secret_key) {
        secret_key = @"";
    }
    [BSCore sharedInstance].app_id = app_id;
    [BSCore sharedInstance].secret_key = secret_key;
    [BSCore sharedInstance].app_host = app_host;
    
    dispatch_once(&loadAllComponents, ^{
        [[BSCore sharedInstance] loadAllRegisteredComponents];
        [BSControlRouter sharedControlRouter];
    });
}

/*!
 *  是否开启日志
 *  @param open 是否开启日志，默认 false
 */
+(void)openSDKDebug:(BOOL)open
{

}

- (void)setContext:(NSDictionary *)context
{
    _context = context;
    
    [BSCore sharedInstance].app_id = _context[@"app_id"];
    [BSCore sharedInstance].secret_key = _context[@"secret_key"];
    [BSCore sharedInstance].app_host = _context[@"host"];

    
    dispatch_once(&loadAllComponents, ^{
        [[BSCore sharedInstance] loadAllRegisteredComponents];
        [BSControlRouter sharedControlRouter];
        //组件配置数据
        NSArray* config_build = _context[@"config_build"];
        if(config_build && [config_build isKindOfClass:[NSArray class]])
        {
            @weakify(self);
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                @strongify(self);
                [self initComponentsData:config_build];
            });
        }
    });
}

- (void)initComponentsData:(NSArray*)data
{
    if(!self.componentsData)
        self.componentsData=[NSMutableDictionary dictionary];
    
    //这里的obj在进去循环的时候一开始就是One One的地址, 到后再到Tow, 以此类推.
     for (NSDictionary* obj in data){
         [self.componentsData setObject:obj forKey:obj[@"component_id"]];
     }
    
    //发送config数据到各个组件
    for(id<BSComponentProtocol> comp in self.components)
    {
        NSString *componentId = comp.componentId;
        if([comp respondsToSelector:@selector(receiveLoadComponentConfigData:)] && componentId.length>0)
        {
            NSDictionary *config = [self.componentsData objectForKey:componentId];
            if(config)
                [comp receiveLoadComponentConfigData:config];
        }
    }
}

+ (void)loadConfig
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    [BSCore sharedInstance].context = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
}

// 加载主框架
+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if([BSCore sharedInstance].appMainFramework && [[BSCore sharedInstance].appMainFramework respondsToSelector:@selector(application:didFinishLaunchingWithOptions:)])
    {
        return [[BSCore sharedInstance].appMainFramework application:application didFinishLaunchingWithOptions:launchOptions];
    }
    return NO;
}

- (BOOL)registerComponentClass:(Class)componentClass
{
    if (componentClass == nil) {
        return NO;
    }
    if (![componentClass conformsToProtocol:@protocol(BSComponentProtocol)]) {
        return NO;
    }
    NSString *componentClassName = NSStringFromClass(componentClass);
    if (![componentClassName isKindOfClass:[NSString class]] || componentClassName.length == 0) {
        return NO;
    }
    if ([self.components containsObject:componentClassName]) {
        return NO;
    }
    [self.components addObject:componentClassName];
    return YES;
}

- (void)loadAllRegisteredComponents
{
    @weakify(self);
    __block NSMutableArray *moduleInstanceArray = [NSMutableArray array];
    [self.components enumerateObjectsUsingBlock:^(NSString *componentClassName, NSUInteger idx, BOOL *_Nonnull stop) {
        @strongify(self);
        Class componentClass = NSClassFromString(componentClassName);

        if (componentClass) {
            id<BSComponentProtocol> moduleInstance = [[componentClass alloc] init];
            if ([moduleInstance respondsToSelector:@selector(loadChatExtension)]) {
                [moduleInstance loadChatExtension];
            }
            if([moduleInstance respondsToSelector:@selector(isAppMainFramework)] && [moduleInstance isAppMainFramework])
            {
                if([moduleInstance componentId].intValue < 10000 || !self.appMainFramework)
                    self.appMainFramework = moduleInstance;
            }
            else
                [moduleInstanceArray addObject:moduleInstance];
        }
    }];
    if(self.appMainFramework)
        [moduleInstanceArray addObject:self.appMainFramework];
    [self.components removeAllObjects];
    [self.components addObjectsFromArray:moduleInstanceArray];
}

/// 打印除BSCore和BSUICore之外其他所有组件
+ (void)printAllComponent {
    dispatch_once(&loadAllComponents, ^{
        [[BSCore sharedInstance] loadAllRegisteredComponents];
        [BSControlRouter sharedControlRouter];
    });
    NSString *string = @"\n--------当前组件列表--------\n";
    for (id<BSComponentProtocol>component in [BSCore sharedInstance].components) {
        NSString *name = [component componentName];
        NSString *Id = [component componentId];
        NSString *version = [component componentVersion];
        NSString *description = [component componentDescription];
        NSArray *viewControllers = [component componentViewControllers];
        string = [NSString stringWithFormat:@"%@         name = %@\n         description = %@\n         id = %@\n         version = %@\n         viewControllers = %@\n\n",string,name,description,Id,version,viewControllers];
    }
    NSLog(@"%@",string);
}


/// 判断某个组件是否加载
+ (BOOL)isLoadedComponentName:(NSString *)name {
    for (id<BSComponentProtocol>component in [BSCore sharedInstance].components) {
        if([NSStringFromClass([component class]) isEqualToString:name]) {
            return YES;
        }
    }
    return NO;
}

@end

