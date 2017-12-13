//
//  ICSectorProgressView.h
//  ICome
//
//  Created by zhangrongwu on 2017/12/11.
//  Copyright © 2017年 iCom. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICSectorProgressView : UIView
@property(assign,nonatomic)CGFloat progress;

@property (nonatomic, assign)CGFloat borderWidth;

-(void)beginSetDefault;

@end
