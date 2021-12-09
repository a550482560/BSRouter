//
//  HomePageViewController.m
//  HomePage
//
//  Created by LUU on 2021/12/9.
//

#import "HomePageViewController.h"
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
    // Do any additional setup after loading the view.
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
