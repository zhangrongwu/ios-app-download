//
//  ICSectorProgressView.m
//  ICome
//
//  Created by zhangrongwu on 2017/12/11.
//  Copyright © 2017年 iCom. All rights reserved.
//

#import "ICSectorProgressView.h"
@interface ICSectorProgressCentreView : UIView

@property(assign,nonatomic)CGFloat progress;

@end

@implementation ICSectorProgressCentreView
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect {
    //    定义扇形中心
    CGPoint origin = CGPointMake(rect.size.width / 2.0f, rect.size.height / 2.0f);
    //    定义扇形半径
    CGFloat radius = rect.size.width / 2.0f;
    //    设定扇形起点位置
    CGFloat startAngle = - M_PI_2 + self.progress * M_PI * 2;
    //    根据进度计算扇形结束位置
    CGFloat endAngle = M_PI *3.0/2.0;
    //    根据起始点、原点、半径绘制弧线
    UIBezierPath *sectorPath = [UIBezierPath bezierPathWithArcCenter:origin radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    //    从弧线结束为止绘制一条线段到圆心。这样系统会自动闭合图形，绘制一条从圆心到弧线起点的线段。
    [sectorPath addLineToPoint:origin];
    //    设置扇形的填充颜色
    [[UIColor blackColor] set];
    //    设置扇形的填充模式
    [sectorPath fill];
}


//重写progress的set方法，可以在赋值的同时给label赋值
- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    //    赋值结束之后要刷新UI，不然看不到扇形的变化
    [self setNeedsDisplay];
}
@end





@interface ICSectorProgressView ()<CAAnimationDelegate>

@property (nonatomic, strong)ICSectorProgressCentreView *sectorView;
@property (nonatomic, strong) CAShapeLayer *borderLayer;//中间的圆透明，圆与边框之间的内容半透明的layer

@end

@implementation ICSectorProgressView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.borderWidth = 20;
    }
    return self;
}

-(void)beginSetDefault {
    [self.layer addSublayer:self.borderLayer];
    self.layer.masksToBounds = YES;
    [self addSubview:self.sectorView];
}

-(void)endLoadIng {
    [self.borderLayer addAnimation:[self expandAnimation] forKey:@"expandAnimation"];
    [self.sectorView removeFromSuperview];
}

/**
 *  用添加的方式画一个边是矩形，中间有一个圆形的path，配合fillRule和fillRule可以做出中间透明、外部半透明的效果
 */
- (UIBezierPath *)maskPathWithDiameter:(CGFloat)diameter  {
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    [path moveToPoint:CGPointMake(CGRectGetWidth(self.bounds) / 2, (CGRectGetHeight(self.bounds) -diameter) / 2)];
    [path addArcWithCenter:self.center radius:diameter / 2 startAngle:-M_PI / 2 endAngle:M_PI *3.0/2.0 clockwise:YES];
    return path;
}

- (CABasicAnimation *)expandAnimation {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];
    animation.toValue = (id)[self maskPathWithDiameter:CGRectGetHeight(self.bounds)].CGPath;
    animation.duration = 1.0;
    animation.delegate = self;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if ([self.borderLayer animationForKey:@"expandAnimation"] == anim) {
        [self removeFromSuperview];
    }
}

//重写progress的set方法，可以在赋值的同时给label赋值
- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    
    self.sectorView.progress = progress;
    //    赋值结束之后要刷新UI，不然看不到扇形的变化
    if (progress == 1.0) {
        [self endLoadIng];
    }
}

-(void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
}

-(ICSectorProgressCentreView *)sectorView {
    if (!_sectorView) {
        _sectorView = [[ICSectorProgressCentreView alloc] initWithFrame:CGRectMake(self.borderWidth, self.borderWidth, self.bounds.size.width - self.borderWidth *2, self.bounds.size.height - self.borderWidth * 2)];
        _sectorView.backgroundColor = [UIColor clearColor];
        _sectorView.alpha = 0.5;
    }
    return _sectorView;
}

- (CAShapeLayer *)borderLayer {
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer layer];
        _borderLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
        _borderLayer.path = [self maskPathWithDiameter:CGRectGetHeight(self.bounds) - self.borderWidth].CGPath;
        _borderLayer.fillRule = kCAFillRuleEvenOdd;
    }
    return _borderLayer;
}

@end


