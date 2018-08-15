//
//  styleBtnItem.h
//  mailEditor
//
//  Created by 赵祥 on 2018/8/1.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface styleBtnItem : UIView

@property (nonatomic,strong) UIButton *btn;

@property (nonatomic,strong) UILabel *title;

@property (nonatomic)BOOL isSelect;

- (void)createTitleWithFrame:(NSString *)title;

- (void)addImgToBtn:(NSString *)img;

- (void)addColorToBtn:(NSString *)img;

- (void)addImgToBtnAndChangeFrame:(NSString *)img;

@end
