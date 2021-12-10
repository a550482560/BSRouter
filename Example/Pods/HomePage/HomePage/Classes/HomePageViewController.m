//
//  HomePageViewController.m
//  HomePage
//
//  Created by LUU on 2021/12/9.
//

#import "HomePageViewController.h"
#import <BSRouter/BSRouter.h>

@interface HomePageViewController ()

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.view.backgroundColor = UIColor.whiteColor;
    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 100)];
    label.text = @"首页";
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    UIButton * button = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 175, 50)];
    button.backgroundColor = UIColor.lightGrayColor;
    [button setTitle:@"我的页面" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(f1) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)f1{
    UIViewController *viewController = [BSR() performActionWithUrl:[NSURL URLWithString:@"bs://Mine/showMineWithParams?id=1234"] completion:nil];

    [UIApplication sharedApplication].keyWindow.rootViewController = viewController;

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
