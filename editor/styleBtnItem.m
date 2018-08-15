//
//  styleBtnItem.m
//  mailEditor
//
//  Created by 赵祥 on 2018/8/1.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import "styleBtnItem.h"
#import <Masonry.h>

CGRect f;

@implementation styleBtnItem

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        f = frame;
        //创建字体大小的视图
        [self createBtnWithFrame:frame];

    }
    return self;
}

- (void)createBtnWithFrame:(CGRect)frame
{
    self.isSelect = false;
    
    self.btn = [[UIButton alloc]init];
    [self addSubview:self.btn];
    
    self.btn.layer.cornerRadius=(frame.size.width - 20)/2;
    self.btn.clipsToBounds = YES;
}


- (void)addImgToBtn:(NSString *)img
{
    [self.btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:f.size.width - 20]);
        make.width.equalTo([NSNumber numberWithInt:f.size.width - 20]);
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(10);
    }];
    
    UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:img]];
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [self.btn addSubview:imgView];
    
    [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.btn).offset(10);
        make.left.equalTo(self.btn).offset(10);
        make.right.equalTo(self.btn).offset(-10);
        make.bottom.equalTo(self.btn).offset(-10);
    }];
}

- (void)addColorToBtn:(NSString *)img
{
    UIView *view = [[UIView alloc]init];
    [view setContentMode:UIViewContentModeScaleAspectFill];
    view.backgroundColor = [self colorWithHexString:img];
    view.userInteractionEnabled = NO;
    [self.btn addSubview:view];
    
    [self.btn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:f.size.width - 20]);
        make.width.equalTo([NSNumber numberWithInt:f.size.width - 20]);
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
    }];
    
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:27]);
        make.width.equalTo([NSNumber numberWithInt:27]);
        make.center.mas_equalTo(self.btn);
    }];
    
    view.layer.cornerRadius=13.5;
}

- (void)createTitleWithFrame:(NSString *)title
{
    self.title = [[UILabel alloc]init];
    [self.title setText:title];
    self.title.textAlignment = NSTextAlignmentCenter;
    [self.title setFont:[UIFont systemFontOfSize:10.0]];
    [self.title setTextColor:[self colorWithHexString:@"#31353b"]];
    [self addSubview:self.title];

    [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.btn.mas_bottom).offset(5);
        make.bottom.equalTo(self).offset(-15);
    }];
}

- (void)addImgToBtnAndChangeFrame:(NSString *)img
{
    self.btn.layer.cornerRadius = 4.0;
    
    [self.btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:f.size.width - 10]);
        make.width.equalTo([NSNumber numberWithInt:f.size.width - 10]);
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(15);
    }];
    
    UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:img]];
    [imgView setContentMode:UIViewContentModeScaleAspectFill];
    [self.btn addSubview:imgView];
    
    [imgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.btn).offset(12);
        make.left.equalTo(self.btn).offset(12);
        make.right.equalTo(self.btn).offset(-12);
        make.bottom.equalTo(self.btn).offset(-12);
    }];
}

#pragma mark - colortools

- (UIColor *)colorWithHexString:(NSString *)hexColorString {
    if ([hexColorString length] < 6) { //长度不合法
        return [UIColor blackColor];
    }
    NSString *tempString = [hexColorString lowercaseString];
    if ([tempString hasPrefix:@"0x"]) { //检查开头是0x
        tempString = [tempString substringFromIndex:2];
    } else if ([tempString hasPrefix:@"#"]) { //检查开头是#
        tempString = [tempString substringFromIndex:1];
    }
    if ([tempString length] != 6) {
        return [UIColor blackColor];
    }
    //分解三种颜色的值
    NSRange range = NSMakeRange(0, 2);
    NSString *rString = [tempString substringWithRange:range];
    range.location = 2;
    NSString *gString = [tempString substringWithRange:range];
    range.location = 4;
    NSString *bString = [tempString substringWithRange:range];
    //取三种颜色值
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f)
                           green:((float)g / 255.0f)
                            blue:((float)b / 255.0f)
                           alpha:1.0f];
}

@end
