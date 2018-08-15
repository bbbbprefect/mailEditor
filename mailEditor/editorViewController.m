//
//  editorViewController.m
//  mailEditor
//
//  Created by 赵祥 on 2018/7/27.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import "editorViewController.h"

@interface editorViewController ()

@end

@implementation editorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.title = @"Standard";
    
    //Set Custom CSS
    NSString *customCSS = @"";
    [self setCSS:customCSS];
    
    self.receiveEditorDidChangeEvents = NO;
    
    
    // HTML Content to set in the editor
    NSString *html = @"<div class='test'></div><!-- This is an HTML comment -->"
    "<p>This is a test of the <strong>ZSSRichTextEditor</strong> by <a title=\"Zed Said\" href=\"http://www.zedsaid.com\">Zed Said Studio</a></p>";

    self.shouldShowKeyboard = YES;
    // Set the HTML contents of the editor
    [self setPlaceholder:@"在这里输入发送内容"];
    
    [self setHTML:html];
}


//导出文本为html样式
- (void)exportHTML {
    
    NSLog(@"%@", [self getHTML]);
    
}

- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html {
    
    NSLog(@"Text Has Changed: %@", text);
    
    NSLog(@"HTML Has Changed: %@", html);
    
}

- (void)hashtagRecognizedWithWord:(NSString *)word {
    
    NSLog(@"Hashtag has been recognized: %@", word);
    
}

- (void)mentionRecognizedWithWord:(NSString *)word {
    
    NSLog(@"Mention has been recognized: %@", word);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
