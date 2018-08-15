//
//  ViewController.m
//  mailEditor
//
//  Created by 赵祥 on 2018/7/27.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import "ViewController.h"
#import "editorViewController.h"

@interface ViewController ()

@property(nonatomic) UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 200, 50)];
    self.btn.backgroundColor = [UIColor redColor];
    [self.btn addTarget:self action:@selector(tapAction:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.btn];
}

- (void)tapAction:(UIButton *)btn
{
    editorViewController *eVC = [[editorViewController alloc]init];
   [self.navigationController pushViewController:eVC animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
