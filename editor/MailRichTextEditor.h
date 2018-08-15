//
//  MailRichTextEditor.h
//  mailEditor
//
//  Created by 赵祥 on 2018/7/31.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

////首先创建一个实现了JSExport协议的协议
//@protocol TestJSObjectProtocol <JSExport>
//
////此处我们测试几种参数的情况
//-(void)redoEvents;
//
//@end

@interface MailRichTextEditor : UIViewController<UIWebViewDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,JSExport>

/**
 *  If the HTML should be formatted to be pretty
 */
@property (nonatomic) BOOL formatHTML;

/**
 *  The placeholder text to use if there is no editor content
 */
@property (nonatomic, strong) NSString *placeholder;
/**
 *  If the keyboard should be shown when the editor loads
 */
@property (nonatomic) BOOL shouldShowKeyboard;
/**
 *  The base URL to use for the webView
 */
@property (nonatomic, strong) NSURL *baseURL;
/**
 * If the sub class recieves text did change events or not
 */
@property (nonatomic) BOOL receiveEditorDidChangeEvents;


/********************************************   方法   *************************/
/**
 *  Set custom css
 */
- (void)setCSS:(NSString *)css;
/**
 *  Sets the HTML for the entire editor
 *
 *  @param html  HTML string to set for the editor
 *
 */
- (void)setHTML:(NSString *)html;

/**
 *  Returns the HTML from the Rich Text Editor
 *
 */
- (NSString *)getHTML;


/**
 *  Inserts HTML at the caret position
 *
 *  @param html  HTML string to insert
 *
 */
- (void)insertHTML:(NSString *)html;

/*
 * 插入图片的方法
 *  @param url The URL for the image
 *  @param alt The alt for the image
 */
- (void)insertImageBase64String:(NSString *)imageBase64String;

@end
