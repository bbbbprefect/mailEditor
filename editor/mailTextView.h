//
//  mailTextView.h
//  mailEditor
//
//  Created by 赵祥 on 2018/7/31.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYRTextView.h"

@interface mailTextView : CYRTextView

@property (nonatomic, strong) UIFont *defaultFont;
@property (nonatomic, strong) UIFont *boldFont;
@property (nonatomic, strong) UIFont *italicFont;

@end
