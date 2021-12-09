//
//  Target_Home.m
//  HomePage
//
//  Created by LUU on 2021/12/9.
//

#import "Target_Home.h"
#import "HomePageViewController.h"
@implementation Target_Home
- (UIViewController *)Action_showVCWithParams:(NSDictionary *)params
{
    // 因为action是从属于ModuleA的，所以action直接可以使用ModuleA里的所有声明
    HomePageViewController *viewController = [[HomePageViewController alloc] init];
//    viewController.userID = params[@"id"];
    return viewController;
}

@end
