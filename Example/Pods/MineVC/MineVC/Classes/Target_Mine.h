//
//  Target_Mine.h
//  MineVC
//
//  Created by 550482560@qq.com on 12/06/2021.
//  Copyright (c) 2021 550482560@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Target_Mine : NSObject

- (UIViewController *)Action_showMineWithParams:(NSDictionary *)params;
- (id)Action_nativePresentImage:(NSDictionary *)params;
- (id)Action_showAlert:(NSDictionary *)params;

// 容错
- (id)Action_nativeNoImage:(NSDictionary *)params;

@end
