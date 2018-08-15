//
//  selectStyleView.h
//  mailEditor
//
//  Created by 赵祥 on 2018/8/1.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "styleBtnItem.h"

@interface selectStyleView : UIView

//字体大小的布局
@property(nonatomic,strong) UIView *fontSizeHolder;
@property(nonatomic,strong) styleBtnItem *smallFont;
@property(nonatomic,strong) styleBtnItem *defaultFont;
@property(nonatomic,strong) styleBtnItem *bigFont;
@property(nonatomic,strong) styleBtnItem *moreBigFont;
@property(nonatomic) int selectedSize;

//字体颜色的布局
@property(nonatomic,strong) UIView *fontColorHolder;
@property(nonatomic,strong) styleBtnItem *blackFont;
@property(nonatomic,strong) styleBtnItem *redFont;
@property(nonatomic,strong) styleBtnItem *blueFont;
@property(nonatomic,strong) styleBtnItem *greenFont;
@property(nonatomic) int selectedColor;

//字体样式的布局
@property(nonatomic,strong) UIView *fontStyleHolder;
@property(nonatomic,strong) styleBtnItem *boldFont;
@property(nonatomic,strong) styleBtnItem *italicFont;
@property(nonatomic,strong) styleBtnItem *underlineFont;
@property(nonatomic,strong) styleBtnItem *backgroundFont;
@property(nonatomic,strong) styleBtnItem *itemdotFont;
@property(nonatomic,strong) styleBtnItem *itemnumFont;
@property(nonatomic) NSMutableArray *selectedStyle;

@end
