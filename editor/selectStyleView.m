//
//  selectStyleView.m
//  mailEditor
//
//  Created by 赵祥 on 2018/8/1.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import "selectStyleView.h"
#import <Masonry.h>

@implementation selectStyleView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        //创建字体大小的视图
        [self createFontSizeHolderWithFrame:frame];
        
        //创建字体颜色的视图
        [self createFontColorHolderWithFrame:frame];
        
        //创建字体样式的视图
        [self createFontStyleHolderWithFrame:frame];
        
        self.selectedStyle = [[NSMutableArray alloc]init];
        
    }
    return self;
}

- (void) createFontSizeHolderWithFrame:(CGRect)frame
{
    self.fontSizeHolder = [[UIView alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height * 1.44 / 3.88)];
    self.fontSizeHolder.backgroundColor = [self colorWithHexString:@"#fafafa"];
    [self addSubview:self.fontSizeHolder];
    
    UILabel *title = [[UILabel alloc]init];
    [title setText:@"字号"];
    [title setTextColor:[self colorWithHexString:@"#84858a"]];
    [title setFont:[UIFont systemFontOfSize:13.0]];
    title.textAlignment = NSTextAlignmentCenter;
    [self.fontSizeHolder addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo([NSNumber numberWithInt:55]);
        make.top.equalTo(self.fontSizeHolder).with.offset(0);
        make.bottom.equalTo(self.fontSizeHolder).with.offset(0);
    }];
    
    [self createFontSizeBtn:self.fontSizeHolder.frame];
    
    UIView *line = [UIView new];
    line.backgroundColor = [self colorWithHexString:@"#e5e5e5"];
    [self.fontSizeHolder addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:1]);
        make.right.equalTo(self.fontSizeHolder).with.offset(-15);
        make.left.equalTo(self.fontSizeHolder).with.offset(55);
        make.bottom.equalTo(self.fontSizeHolder).with.offset(0);
    }];
}

- (void) createFontColorHolderWithFrame:(CGRect)frame
{
    self.fontColorHolder = [[UIView alloc]initWithFrame:CGRectMake(0, frame.size.height * 1.44 / 3.88, frame.size.width, frame.size.height * 1.44 / 3.88)];
    self.fontColorHolder.backgroundColor = [self colorWithHexString:@"#fafafa"];
    [self addSubview:self.fontColorHolder];
    
    UILabel *title = [[UILabel alloc]init];
    [title setText:@"字色"];
    [title setTextColor:[self colorWithHexString:@"#84858a"]];
    [title setFont:[UIFont systemFontOfSize:13.0]];
    title.textAlignment = NSTextAlignmentCenter;
    [self.fontColorHolder addSubview:title];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo([NSNumber numberWithInt:55]);
        make.top.equalTo(self.fontColorHolder).with.offset(0);
        make.bottom.equalTo(self.fontColorHolder).with.offset(0);
    }];
    
    [self createFontColorBtn:self.fontColorHolder.frame];
    
    UIView *line = [UIView new];
    line.backgroundColor = [self colorWithHexString:@"#e5e5e5"];
    [self.fontColorHolder addSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo([NSNumber numberWithInt:1]);
        make.right.equalTo(self.fontColorHolder).with.offset(-15);
        make.left.equalTo(self.fontColorHolder).with.offset(15);
        make.bottom.equalTo(self.fontColorHolder).with.offset(0);
    }];
}

- (void) createFontStyleHolderWithFrame:(CGRect)frame
{
    self.fontStyleHolder = [[UIView alloc]initWithFrame:CGRectMake(0, frame.size.height * 2.88 / 3.88, frame.size.width, frame.size.height / 3.88)];
    self.fontStyleHolder.backgroundColor = [self colorWithHexString:@"#fafafa"];
    [self addSubview:self.fontStyleHolder];
    
    [self createFontStyleBtn:self.fontColorHolder.frame];
}

- (void)createFontSizeBtn:(CGRect)frame
{
    CGFloat width = (frame.size.width - 70) / 4.0;
    
    self.smallFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55, 0, width, frame.size.height)];
    [self.smallFont addImgToBtn:@"A_small"];
    [self.smallFont createTitleWithFrame:@"小"];
    [self.fontSizeHolder addSubview:self.smallFont];
    
    self.defaultFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width, 0, width, frame.size.height)];
    [self.defaultFont addImgToBtn:@"A_defult"];
    [self.defaultFont createTitleWithFrame:@"默认"];
    [self.fontSizeHolder addSubview:self.defaultFont];
    
    self.bigFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width*2, 0, width, frame.size.height)];
    [self.bigFont addImgToBtn:@"A_big"];
    [self.bigFont createTitleWithFrame:@"大"];
    [self.fontSizeHolder addSubview:self.bigFont];
    
    self.moreBigFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width*3, 0, width, frame.size.height)];
    [self.moreBigFont addImgToBtn:@"A_superbig"];
    [self.moreBigFont createTitleWithFrame:@"特大"];
    [self.fontSizeHolder addSubview:self.moreBigFont];
}

- (void)createFontColorBtn:(CGRect)frame
{
    CGFloat width = (frame.size.width - 70) / 4.0;
    
    self.blackFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55, 0, width, frame.size.height)];
    [self.blackFont addColorToBtn:@"#2e363d"];
    [self.fontColorHolder addSubview:self.blackFont];
    
    self.redFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width, 0, width, frame.size.height)];
    [self.redFont addColorToBtn:@"#e84247"];
    [self.fontColorHolder addSubview:self.redFont];
    
    self.blueFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width*2, 0, width, frame.size.height)];
    [self.blueFont addColorToBtn:@"#107fea"];
    [self.fontColorHolder addSubview:self.blueFont];
    
    self.greenFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(55 + width*3, 0, width, frame.size.height)];
    [self.greenFont addColorToBtn:@"#01a833"];
    [self.fontColorHolder addSubview:self.greenFont];
}

- (void)createFontStyleBtn:(CGRect)frame
{
    CGFloat width = frame.size.width / 6.0;
    
    self.boldFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(0, 0, width, frame.size.height)];
    [self.boldFont addImgToBtnAndChangeFrame:@"bold"];
    [self.fontStyleHolder addSubview:self.boldFont];
    
    self.italicFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(width, 0, width, frame.size.height)];
    [self.italicFont addImgToBtnAndChangeFrame:@"italic"];
    [self.fontStyleHolder addSubview:self.italicFont];
    
    self.underlineFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(width*2, 0, width, frame.size.height)];
    [self.underlineFont addImgToBtnAndChangeFrame:@"underline"];
    [self.fontStyleHolder addSubview:self.underlineFont];
    
    self.backgroundFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(width*3, 0, width, frame.size.height)];
    [self.backgroundFont addImgToBtnAndChangeFrame:@"Acolor"];
    [self.fontStyleHolder addSubview:self.backgroundFont];
    
    self.itemdotFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(width*4, 0, width, frame.size.height)];
    [self.itemdotFont addImgToBtnAndChangeFrame:@"itemdot"];
    [self.fontStyleHolder addSubview:self.itemdotFont];
    
    self.itemnumFont = [[styleBtnItem alloc]initWithFrame:CGRectMake(width*5, 0, width, frame.size.height)];
    [self.itemnumFont addImgToBtnAndChangeFrame:@"itemnum"];
    [self.fontStyleHolder addSubview:self.itemnumFont];
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
