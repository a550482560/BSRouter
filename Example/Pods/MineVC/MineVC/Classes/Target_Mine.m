//
//  Target_Mine.m
//  MineVC
//
//  Created by 550482560@qq.com on 12/06/2021.
//  Copyright (c) 2021 550482560@qq.com. All rights reserved.
//

#import "Target_Mine.h"
#import "MineViewController.h"

typedef void (^CTUrlRouterCallbackBlock)(NSDictionary *info);

@implementation Target_Mine

- (UIViewController *)Action_showMineWithParams:(NSDictionary *)params
{
    // 因为action是从属于ModuleA的，所以action直接可以使用ModuleA里的所有声明
    MineViewController *viewController = [[MineViewController alloc] init];
    viewController.userID = params[@"id"];
    return viewController;
}

- (id)Action_nativePresentImage:(NSDictionary *)params
{
//    DemoModuleADetailViewController *viewController = [[DemoModuleADetailViewController alloc] init];
//    viewController.valueLabel.text = @"this is image";
//    viewController.imageView.image = params[@"image"];
//    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
    return nil;
}

- (id)Action_showAlert:(NSDictionary *)params
{
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        CTUrlRouterCallbackBlock callback = params[@"cancelAction"];
        if (callback) {
            callback(@{@"alertAction":action});
        }
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CTUrlRouterCallbackBlock callback = params[@"confirmAction"];
        if (callback) {
            callback(@{@"alertAction":action});
        }
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"alert from Module A" message:params[@"message"] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:cancelAction];
    [alertController addAction:confirmAction];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    return nil;
}

- (id)Action_nativeNoImage:(NSDictionary *)params
{
//    DemoModuleADetailViewController *viewController = [[DemoModuleADetailViewController alloc] init];
//    viewController.valueLabel.text = @"no image";
//    viewController.imageView.image = [UIImage imageNamed:@"noImage"];
//    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:viewController animated:YES completion:nil];
    
    return nil;
}

@end
