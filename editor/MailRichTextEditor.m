//
//  MailRichTextEditor.m
//  mailEditor
//
//  Created by 赵祥 on 2018/7/31.
//  Copyright © 2018年 赵祥. All rights reserved.
//

#import "MailRichTextEditor.h"
#import "mailTextView.h"
#import "selectStyleView.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Masonry.h>



@import JavaScriptCore;


/**
 
 UIWebView modifications for hiding the inputAccessoryView
 
 **/
@interface UIWebView (HackishAccessoryHiding)
@property (nonatomic, assign) BOOL hidesInputAccessoryView;
@end

@implementation UIWebView (HackishAccessoryHiding)

static const char * const hackishFixClassName = "UIWebBrowserViewMinusAccessoryView";
static Class hackishFixClass = Nil;

- (UIView *)hackishlyFoundBrowserView {
    UIScrollView *scrollView = self.scrollView;
    
    UIView *browserView = nil;
    for (UIView *subview in scrollView.subviews) {
        if ([NSStringFromClass([subview class]) hasPrefix:@"UIWebBrowserView"]) {
            browserView = subview;
            break;
        }
    }
    return browserView;
}

- (id)methodReturningNil {
    return nil;
}

- (void)ensureHackishSubclassExistsOfBrowserViewClass:(Class)browserViewClass {
    if (!hackishFixClass) {
        Class newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        newClass = objc_allocateClassPair(browserViewClass, hackishFixClassName, 0);
        IMP nilImp = [self methodForSelector:@selector(methodReturningNil)];
        class_addMethod(newClass, @selector(inputAccessoryView), nilImp, "@@:");
        objc_registerClassPair(newClass);
        
        hackishFixClass = newClass;
    }
}

- (BOOL) hidesInputAccessoryView {
    UIView *browserView = [self hackishlyFoundBrowserView];
    return [browserView class] == hackishFixClass;
}

- (void) setHidesInputAccessoryView:(BOOL)value {
    UIView *browserView = [self hackishlyFoundBrowserView];
    if (browserView == nil) {
        return;
    }
    [self ensureHackishSubclassExistsOfBrowserViewClass:[browserView class]];
    
    if (value) {
        object_setClass(browserView, hackishFixClass);
    }
    else {
        Class normalClass = objc_getClass("UIWebBrowserView");
        object_setClass(browserView, normalClass);
    }
    [browserView reloadInputViews];
}

@end
/***********************************************/
@interface MailRichTextEditor ()

/*
 *  MailTextView for displaying the source code for what is displayed in the editor view
 */
@property (nonatomic, strong) mailTextView *sourceView;

/*
 *  UIWebView for writing/editing/displaying the content
 */
@property (nonatomic, strong) UIWebView *editorView;

/*
 *  BOOL for if the editor is loaded or not
 */
@property (nonatomic) BOOL editorLoaded;

/*
 *  NSString holding the css
 */
@property (nonatomic, strong) NSString *customCSS;

/*
 *  NSString holding the html
 */
@property (nonatomic, strong) NSString *internalHTML;

/*
 *  Image Picker for selecting photos from users photo library
 */
@property (nonatomic, strong) UIImagePickerController *imagePicker;

/*
 *  NSString holding the base64 value of the current image
 */
@property (nonatomic, strong) NSString *imageBase64String;

/*
 *  CGFloat holdign the selected image scale value
 */
@property (nonatomic, assign) CGFloat selectedImageScale;

/*
 *  BOOL for holding if the resources are loaded or not
 */
@property (nonatomic) BOOL resourcesLoaded;

/*
 *  悬浮视图
 */
@property (nonatomic,strong) UIView *selectHolder;
/*
 *  悬浮视图选择样式的按钮
 */
@property (nonatomic,strong)UIButton *styleBtn;
/*
 *  悬浮视图选择图片的按钮
 */
@property (nonatomic,strong)UIButton *imgBtn;
/*
 *  悬浮视图变回键盘的按钮
 */
@property (nonatomic,strong)UIButton *showKeyBoardBtn;
/*
 *  是否更新悬浮视图的位置
 */
@property (nonatomic) BOOL isUpdateSelectHolder;
/*
 *  字体样式选择视图
 */
@property (nonatomic,strong) selectStyleView *styleView;
/*
 *  记录点击事件回退发送的消息
 */
@property (nonatomic,strong)NSMutableArray *eventsArr;

@property (nonatomic, strong)UIButton *clearBtn;

/*
 *  Method for getting a version of the html without quotes
 */
- (NSString *)removeQuotesFromHTML:(NSString *)html;

/*
 *  Method for getting a tidied version of the html
 */
- (NSString *)tidyHTML:(NSString *)html;


@end

@implementation MailRichTextEditor

//Scale image from device
static CGFloat kJPEGCompression = 0.8;
static CGFloat kDefaultScale = 0.5;
static CGFloat mailKeyBoardHeight = -1.0;
static int selectNum = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Initialise variables
    self.editorLoaded = NO;
    self.receiveEditorDidChangeEvents = NO;
    self.shouldShowKeyboard = YES;
    self.formatHTML = YES;
    self.isUpdateSelectHolder = YES;
    self.eventsArr = [[NSMutableArray alloc]init];
    
    //Frame for the source view and editor view
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    //Source View
    [self createSourceViewWithFrame:frame];
    
    //Editor View
    [self createEditorViewWithFrame:frame];
    
    
    //Image Picker used to allow the user insert images from the device (base64 encoded)
    [self setUpImagePicker];
    
    //悬浮按钮
    [self createSelectBtn];
    
    //Load Resources
    if (!self.resourcesLoaded) {
        
        [self loadResources];
        
    }
    
}

#pragma mark - View Will Appear Section
- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    

    //Add observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOrHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

#pragma mark - View Will Disappear Section
- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    //Remove observers for keyboard showing or hiding notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

#pragma mark - Resources Section

- (void)loadResources {
    
    //Define correct bundle for loading resources
    NSBundle* bundle = [NSBundle bundleForClass:[mailTextView class]];
    
    //Create a string with the contents of editor.html
    NSString *filePath = [bundle pathForResource:@"editor" ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    //Add jQuery.js to the html file
    NSString *jquery = [bundle pathForResource:@"jQuery" ofType:@"js"];
    NSString *jqueryString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:jquery] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- jQuery -->" withString:jqueryString];
    
    //Add JSBeautifier.js to the html file
    NSString *beautifier = [bundle pathForResource:@"JSBeautifier" ofType:@"js"];
    NSString *beautifierString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:beautifier] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!-- jsbeautifier -->" withString:beautifierString];
    
    //Add mailRichTextEditor.js to the html file
    NSString *source = [bundle pathForResource:@"MailRichTextEditor" ofType:@"js"];
    NSString *jsString = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:source] encoding:NSUTF8StringEncoding];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<!--editor-->" withString:jsString];
    
    [self.editorView loadHTMLString:htmlString baseURL:self.baseURL];
    self.resourcesLoaded = YES;
    
}

#pragma mark - Set Up View Section

- (void)createSelectBtn {
    
    self.selectHolder = [[UIView alloc]init];
    self.selectHolder.layer.cornerRadius = 6;

    self.selectHolder.layer.borderWidth = 1;
    self.selectHolder.layer.borderColor = [[self colorWithHexString:@"#e5e5e5"] CGColor];
    
    [self.view addSubview:self.selectHolder];
    
    [self.selectHolder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(88, 44));
        make.right.equalTo(self.view).with.offset(-10);
        make.bottom.equalTo(self.view).with.offset(-15);
    }];
    self.selectHolder.backgroundColor = [self colorWithHexString:@"#fafafa"];
  
    
    //弹出键盘按钮
    self.showKeyBoardBtn = [[UIButton alloc]init];
    [self.showKeyBoardBtn addTarget:self action:@selector(showKeyBoard:) forControlEvents:UIControlEventTouchDown];
    [self.selectHolder addSubview:self.showKeyBoardBtn];
    [self.showKeyBoardBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(39, 39));
        make.top.equalTo(self.selectHolder).with.offset(5);
        make.left.equalTo(self.selectHolder).with.offset(5);
        make.bottom.equalTo(self.selectHolder).with.offset(-5);
    }];
    UIImageView *keyBoardImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"keyboard"]];
    [self.showKeyBoardBtn addSubview:keyBoardImgView];
    [keyBoardImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(25, 25));
        make.center.equalTo(self.showKeyBoardBtn);
    }];
    
    
    //图片选择按钮
    self.imgBtn = [[UIButton alloc]init];
    [self.imgBtn addTarget:self action:@selector(selectImg:) forControlEvents:UIControlEventTouchDown];
    [self.selectHolder addSubview:self.imgBtn];
    [self.imgBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(39, 39));
        make.top.equalTo(self.selectHolder).with.offset(5);
        make.right.equalTo(self.selectHolder).with.offset(-5);
        make.bottom.equalTo(self.selectHolder).with.offset(-5);
    }];
    UIImageView *imageImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"insertimg"]];
    [self.imgBtn addSubview:imageImgView];
    [imageImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(25, 25));
        make.center.equalTo(self.imgBtn);
    }];
    
    //样式选择按钮
    self.styleBtn = [[UIButton alloc]init];
    [self.styleBtn addTarget:self action:@selector(selectStyle:) forControlEvents:UIControlEventTouchDown];
    [self.selectHolder addSubview:self.styleBtn];
    [self.styleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(39, 39));
        make.top.equalTo(self.selectHolder).with.offset(5);
        make.left.equalTo(self.selectHolder).with.offset(5);
        make.bottom.equalTo(self.selectHolder).with.offset(-5);
    }];
    UIImageView *styleImgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"editA"]];
    [self.styleBtn addSubview:styleImgView];
    [styleImgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(25, 25));
        make.center.equalTo(self.styleBtn);
    }];
    self.styleBtn.hidden = YES;
}

- (void)createSourceViewWithFrame:(CGRect)frame {
    
    self.sourceView = [[mailTextView alloc] initWithFrame:frame];
    self.sourceView.hidden = YES;
    self.sourceView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.sourceView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.sourceView.font = [UIFont fontWithName:@"Courier" size:13.0];
    self.sourceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.sourceView.autoresizesSubviews = YES;
    self.sourceView.delegate = self;
    [self.view addSubview:self.sourceView];
    
}

- (void)createEditorViewWithFrame:(CGRect)frame {
    
    self.editorView = [[UIWebView alloc] initWithFrame:frame];
    self.editorView.delegate = self;
    self.editorView.hidesInputAccessoryView = YES;
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    self.editorView.scalesPageToFit = YES;
    self.editorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.editorView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.editorView.scrollView.bounces = NO;
    self.editorView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.editorView];
    
    
    self.clearBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.clearBtn.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.clearBtn];
    self.clearBtn.hidden = YES;
    [self.clearBtn addTarget:self action:@selector(focusTextEditor) forControlEvents:UIControlEventTouchDown];
}

- (void)createStyleView {
    
    self.styleView = [[selectStyleView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-mailKeyBoardHeight, self.view.frame.size.width, mailKeyBoardHeight)];
    [self.view addSubview:self.styleView];
  
    
    //字号大小按钮的初始化
    [self.styleView.smallFont.btn addTarget:self action:@selector(tapSmallFont) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.defaultFont.btn addTarget:self action:@selector(tapDefaultFont:) forControlEvents:UIControlEventTouchDown];
    self.styleView.defaultFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
    [self.styleView.defaultFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
    [self.styleView.defaultFont.btn.layer setBorderWidth:1.0];
    
    [self.styleView.bigFont.btn addTarget:self action:@selector(tapBigFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.moreBigFont.btn addTarget:self action:@selector(tapMoreBigFont:) forControlEvents:UIControlEventTouchDown];
    
    //字颜色的初始化
    [self.styleView.blackFont.btn addTarget:self action:@selector(tapBlackFont:) forControlEvents:UIControlEventTouchDown];
    self.styleView.blackFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
    [self.styleView.blackFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
    [self.styleView.blackFont.btn.layer setBorderWidth:1.0];
    
    [self.styleView.redFont.btn addTarget:self action:@selector(tapRedFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.blueFont.btn addTarget:self action:@selector(tapBlueFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.greenFont.btn addTarget:self action:@selector(tapGreenFont:) forControlEvents:UIControlEventTouchDown];
    
    //字体样式的初始化
    [self.styleView.boldFont.btn addTarget:self action:@selector(tapBoldFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.italicFont.btn addTarget:self action:@selector(tapItalicFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.underlineFont.btn addTarget:self action:@selector(tapUnderlineFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.backgroundFont.btn addTarget:self action:@selector(tapBackgroundFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.itemdotFont.btn addTarget:self action:@selector(tapItemdotFont:) forControlEvents:UIControlEventTouchDown];
    
    [self.styleView.itemnumFont.btn addTarget:self action:@selector(tapItemnumFont:) forControlEvents:UIControlEventTouchDown];
    
}

- (void)setUpImagePicker {
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.allowsEditing = YES;
    self.selectedImageScale = kDefaultScale; //by default scale to half the size
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Utilities

- (NSString *)removeQuotesFromHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    html = [html stringByReplacingOccurrencesOfString:@"“" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"”" withString:@"&quot;"];
    html = [html stringByReplacingOccurrencesOfString:@"\r"  withString:@"\\r"];
    html = [html stringByReplacingOccurrencesOfString:@"\n"  withString:@"\\n"];
    return html;
}

- (NSString *)tidyHTML:(NSString *)html {
    html = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"<br />"];
    html = [html stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
    if (self.formatHTML) {
        html = [self.editorView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"style_html(\"%@\");", html]];
    }
    return html;
}

#pragma mark - Editor Modification Section

- (void)focusTextEditor {
    self.editorView.keyboardDisplayRequiresUserAction = NO;
    NSString *js = [NSString stringWithFormat:@"mail_editor.clearRecord('%d');",selectNum];
    [self.editorView stringByEvaluatingJavaScriptFromString:js];
    
    for(NSString *msg in self.eventsArr)
    {
        [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
        [self.editorView stringByEvaluatingJavaScriptFromString:msg];
    }
    
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.focusEditor();"];
    
    selectNum = 0;
    [self.eventsArr removeAllObjects];
    self.clearBtn.hidden = YES;
}


- (void)setCSS:(NSString *)css {
    
    self.customCSS = css;
    
    if (self.editorLoaded) {
        [self updateCSS];
    }
    
}

- (void)updateCSS {
    
    if (self.customCSS != NULL && [self.customCSS length] != 0) {
        
        NSString *js = [NSString stringWithFormat:@"mail_editor.setCustomCSS(\"%@\");", self.customCSS];
        [self.editorView stringByEvaluatingJavaScriptFromString:js];
        
    }
    
}

- (void)setPlaceholderText {
    
    //Call the setPlaceholder javascript method if a placeholder has been set
    if (self.placeholder != NULL && [self.placeholder length] != 0) {
        
        NSString *js = [NSString stringWithFormat:@"mail_editor.setPlaceholder(\"%@\");", self.placeholder];
        [self.editorView stringByEvaluatingJavaScriptFromString:js];
        
    }
    
}
- (void)setHTML:(NSString *)html {
    
    self.internalHTML = html;
    
    if (self.editorLoaded) {
        [self updateHTML];
    }
    
}

- (void)updateHTML {
    
    NSString *html = self.internalHTML;
    self.sourceView.text = html;
    NSString *cleanedHTML = [self removeQuotesFromHTML:self.sourceView.text];
    NSString *trigger = [NSString stringWithFormat:@"mail_editor.setHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (NSString *)getHTML {
    
    NSString *html = [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.getHTML();"];
    html = [self removeQuotesFromHTML:html];
    html = [self tidyHTML:html];
    return html;
    
}


- (void)insertHTML:(NSString *)html {
    
    NSString *cleanedHTML = [self removeQuotesFromHTML:html];
    NSString *trigger = [NSString stringWithFormat:@"mail_editor.insertHTML(\"%@\");", cleanedHTML];
    [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    
}

- (NSString *)getText {
    
    return [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.getText();"];
    
}

#pragma mark - tapEvents

- (void) selectStyle:(UIButton *)btn
{
    
    NSLog(@"i'm selectStyle");
    
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
 //   [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.blurEditor();"];
 //   [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.setSelectContent();"];
  //  [self sendMessageToJS:@"mail_editor.setSelectContent();"];
   // [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.setSelectContent();"];
    
    if(!self.styleView && mailKeyBoardHeight != -1.0)
    {
        //样式选择视图
        [self createStyleView];
    }
    self.isUpdateSelectHolder = false;
    
    [self.view endEditing:YES];
    
    self.isUpdateSelectHolder = true;
    self.styleBtn.hidden = YES;
    
    self.showKeyBoardBtn.hidden = NO;
    self.styleView.hidden = NO;
    
    [self resetStyleBtnState];
    
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
    selectNum++;
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.setBackgroundColor(\"#CADDEC\");"];
    
    self.clearBtn.hidden = NO;
}

- (void) showKeyBoard:(UIButton *)btn
{
    NSLog(@"i'm showKeyBoard");
    
    self.styleView.hidden = YES;
    
    self.showKeyBoardBtn.hidden = YES;
    self.styleBtn.hidden = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self focusTextEditor];
    });
    
}

- (void) selectImg:(UIButton *)btn
{
    NSLog(@"i'm selectImg");
    // Save the selection location
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}
//点击选择图片按钮后又点击了取消按钮执行的方法
- (void) tapCacelSelectImg
{
    //执行想要执行的方法
    
    //以下方法是为了获取焦点
    [self focusTextEditor];
}
//字号按钮状态的更新
- (void) tapSmallFont
{
    NSLog(@"i'm tapSmallFont");
    [self updateFontBtnState:1];
    self.styleView.selectedSize = 1;
    [self sendMessageToJS:@"mail_editor.setHeading('3');"];
}

- (void) tapDefaultFont:(UIButton *)btn
{
    NSLog(@"i'm tapdefaultFont");
    [self updateFontBtnState:2];
    self.styleView.selectedSize = 2;
    
    [self sendMessageToJS:@"mail_editor.setHeading('4');"];
}
- (void) tapBigFont:(UIButton *)btn
{
    NSLog(@"i'm tapBigFont");
    [self updateFontBtnState:3];
    self.styleView.selectedSize = 3;
    [self sendMessageToJS:@"mail_editor.setHeading('5');"];
}
- (void) tapMoreBigFont:(UIButton *)btn
{
    NSLog(@"i'm tapMoreBigFont");
    [self updateFontBtnState:4];
    self.styleView.selectedSize = 4;
    [self sendMessageToJS:@"mail_editor.setHeading('6');"];
}
- (void) updateFontBtnState:(int)selectNum
{
    
    self.styleView.smallFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.smallFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.smallFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.defaultFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.defaultFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.defaultFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.bigFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.bigFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.bigFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.moreBigFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.moreBigFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.moreBigFont.btn.layer setBorderWidth:1.0];
    
    switch (selectNum) {
        case 1:
            self.styleView.smallFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.smallFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 2:
            self.styleView.defaultFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.defaultFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 3:
            self.styleView.bigFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.bigFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 4:
            self.styleView.moreBigFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.moreBigFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
            
        default:
            break;
    }
}

//颜色按钮状态的更新
- (void) tapBlackFont:(UIButton *)btn
{
    NSLog(@"i'm tapBlackFont");
    [self updateColorBtnState:1];
    self.styleView.selectedColor = 1;
    [self sendMessageToJS:@"mail_editor.setTextColor('#2e363d');"];
}

- (void) tapRedFont:(UIButton *)btn
{
    NSLog(@"i'm tapRedFont");
    [self updateColorBtnState:2];
    self.styleView.selectedColor = 2;
    [self sendMessageToJS:@"mail_editor.setTextColor('#e84247');"];
}
- (void) tapBlueFont:(UIButton *)btn
{
    NSLog(@"i'm tapBlueFont");
    [self updateColorBtnState:3];
    self.styleView.selectedColor = 3;
    [self sendMessageToJS:@"mail_editor.setTextColor('#107fea');"];
}
- (void) tapGreenFont:(UIButton *)btn
{
    NSLog(@"i'm tapGreenFont");
    [self updateColorBtnState:4];
    self.styleView.selectedColor = 4;
    [self sendMessageToJS:@"mail_editor.setTextColor('#01a833');"];
}
- (void) updateColorBtnState:(int)selectNum
{
    
    self.styleView.blackFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.blackFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.blackFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.redFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.redFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.redFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.blueFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.blueFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.blueFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.greenFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.greenFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.greenFont.btn.layer setBorderWidth:1.0];
    
    switch (selectNum) {
        case 1:
            self.styleView.blackFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.blackFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 2:
            self.styleView.redFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.redFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 3:
            self.styleView.blueFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.blueFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
        case 4:
            self.styleView.greenFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
            [self.styleView.greenFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
            break;
            
        default:
            break;
    }
}

//字体样式按钮及更新

//更新字体样式选择的集合
//- (void) updateSelectSyleArr:(NSString *)str
//{
//    if(![self.styleView.selectedStyle containsObject: str])
//    {
//        [self.styleView.selectedStyle addObject:str];
//    }
//    else
//    {
//        for(NSString *tstr in self.styleView.selectedStyle)
//        {
//            if([tstr isEqualToString:str])
//               [self.styleView.selectedStyle removeObject:tstr];
//        }
//    }
//}

- (void) tapBoldFont:(UIButton *)btn
{
    NSLog(@"i'm tapBoldFont");
    BOOL state =  [self updateStyleBtnState:1];
    [self sendMessageToJS:@"mail_editor.setBold();"];
}

- (void) tapItalicFont:(UIButton *)btn
{
    NSLog(@"i'm tapItalicFont");
    BOOL state = [self updateStyleBtnState:2];
    [self sendMessageToJS:@"mail_editor.setItalic();"];
}

- (void) tapUnderlineFont:(UIButton *)btn
{
    
    NSLog(@"i'm tapUnderlineFont");
    BOOL state = [self updateStyleBtnState:3];
    [self sendMessageToJS:@"mail_editor.setUnderline();"];
    
}

- (void) tapBackgroundFont:(UIButton *)btn
{
    NSLog(@"i'm tapBackgroundFont");
    BOOL state = [self updateStyleBtnState:4];
    NSString *trigger = @"mail_editor.setBackgroundColor(\"#fffaa5\");";
    
    if(self.styleView.backgroundFont.isSelect == true)
    {
        
    }else{
        trigger = @"mail_editor.setBackgroundColor(\"#ffffff\");";
    }
    
    [self sendMessageToJS:trigger];
}

- (void) tapItemdotFont:(UIButton *)btn
{
    
    NSLog(@"i'm tapItemdotFont");
    BOOL state = [self updateStyleBtnState:5];
    [self sendMessageToJS:@"mail_editor.setUnorderedList();"];
}

- (void) tapItemnumFont:(UIButton *)btn
{
    NSLog(@"i'm tapItemnumFont");
    BOOL state = [self updateStyleBtnState:6];
    [self sendMessageToJS:@"mail_editor.setOrderedList();"];
}

- (BOOL) updateStyleBtnState:(int)selectNum
{
    BOOL isSelect = false;
    switch (selectNum) {
        case 1:
            isSelect = self.styleView.boldFont.isSelect;
            if (self.styleView.boldFont.isSelect) {
                self.styleView.boldFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.boldFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.boldFont.btn.layer setBorderWidth:1.0];
                self.styleView.boldFont.isSelect = false;
            }
            else {
                self.styleView.boldFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.boldFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.boldFont.isSelect = true;
            }
            break;
        case 2:
            isSelect = self.styleView.italicFont.isSelect;
            if (self.styleView.italicFont.isSelect) {
                self.styleView.italicFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.italicFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.italicFont.btn.layer setBorderWidth:1.0];
                self.styleView.italicFont.isSelect = false;
            }
            else {
                self.styleView.italicFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.italicFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.italicFont.isSelect = true;
            }
            break;
        case 3:
            isSelect = self.styleView.underlineFont.isSelect;
            if (self.styleView.underlineFont.isSelect) {
                self.styleView.underlineFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.underlineFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.underlineFont.btn.layer setBorderWidth:1.0];
                self.styleView.underlineFont.isSelect = false;
            }
            else {
                self.styleView.underlineFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.underlineFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.underlineFont.isSelect = true;
            }
            break;
        case 4:
            isSelect = self.styleView.backgroundFont.isSelect;
            if (self.styleView.backgroundFont.isSelect) {
                self.styleView.backgroundFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.backgroundFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.backgroundFont.btn.layer setBorderWidth:1.0];
                self.styleView.backgroundFont.isSelect = false;
            }
            else {
                self.styleView.backgroundFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.backgroundFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.backgroundFont.isSelect = true;
            }
            break;
        case 5:
            isSelect = self.styleView.itemdotFont.isSelect;
            if (self.styleView.itemdotFont.isSelect) {
                self.styleView.itemdotFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.itemdotFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.itemdotFont.btn.layer setBorderWidth:1.0];
                self.styleView.itemdotFont.isSelect = false;
            }
            else {
                self.styleView.itemdotFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.itemdotFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.itemdotFont.isSelect = true;
            }
            self.styleView.itemnumFont.btn.backgroundColor = [UIColor clearColor];
            [self.styleView.itemnumFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
            [self.styleView.itemnumFont.btn.layer setBorderWidth:1.0];
            self.styleView.itemnumFont.isSelect = false;
            break;
        case 6:
            isSelect = self.styleView.itemnumFont.isSelect;
            if (self.styleView.itemnumFont.isSelect) {
                self.styleView.itemnumFont.btn.backgroundColor = [UIColor clearColor];
                [self.styleView.itemnumFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
                [self.styleView.itemnumFont.btn.layer setBorderWidth:1.0];
                self.styleView.itemnumFont.isSelect = false;
            }
            else {
                self.styleView.itemnumFont.btn.backgroundColor = [self colorWithHexString:@"e6e7e8"];
                [self.styleView.itemnumFont.btn.layer setBorderColor:[self colorWithHexString:@"d9dadb"].CGColor];
                self.styleView.itemnumFont.isSelect = true;
            }
            self.styleView.itemdotFont.btn.backgroundColor = [UIColor clearColor];
            [self.styleView.itemdotFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
            [self.styleView.itemdotFont.btn.layer setBorderWidth:1.0];
            self.styleView.itemdotFont.isSelect = false;
            break;
            
        default:
            break;
    }
    return isSelect;
}

- (void) resetStyleBtnState
{
    self.styleView.boldFont.isSelect = false;
    self.styleView.boldFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.boldFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.boldFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.italicFont.isSelect = false;
    self.styleView.italicFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.italicFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.italicFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.underlineFont.isSelect = false;
    self.styleView.underlineFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.underlineFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.underlineFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.backgroundFont.isSelect = false;
    self.styleView.backgroundFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.backgroundFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.backgroundFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.itemnumFont.isSelect = false;
    self.styleView.itemnumFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.itemnumFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.itemnumFont.btn.layer setBorderWidth:1.0];
    
    self.styleView.itemdotFont.isSelect = false;
    self.styleView.itemdotFont.btn.backgroundColor = [UIColor clearColor];
    [self.styleView.itemdotFont.btn.layer setBorderColor:[UIColor clearColor].CGColor];
    [self.styleView.itemdotFont.btn.layer setBorderWidth:1.0];
}

- (void) sendMessageToJS:(NSString *)msg
{
    [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
    [self.editorView stringByEvaluatingJavaScriptFromString:msg];
    [self recordTapEvents:msg];
}

#pragma mark - Keyboard status

- (void)keyboardWillShowOrHide:(NSNotification *)notification {
    if(self.styleBtn.hidden == YES)
    {
        self.showKeyBoardBtn.hidden = YES;
        self.styleBtn.hidden = NO;
        self.styleView.hidden = YES;
    }
    
    // Orientation
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // User Info
    NSDictionary *info = notification.userInfo;
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    int curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardEnd = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    
    // Keyboard Size
    //Checks if IOS8, gets correct keyboard height
    CGFloat keyboardHeight = UIInterfaceOrientationIsLandscape(orientation) ? ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.000000) ? keyboardEnd.size.height : keyboardEnd.size.width : keyboardEnd.size.height;
    
    
    mailKeyBoardHeight = keyboardHeight;
    
    // Correct Curve
    UIViewAnimationOptions animationOptions = curve << 16;
    
    if (self.isUpdateSelectHolder) {
        if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
            [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
                [self.selectHolder mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.size.mas_equalTo(CGSizeMake(88, 44));
                    make.right.equalTo(self.view).with.offset(-10);
                    make.bottom.equalTo(self.view).with.offset(-keyboardHeight-10);
                }];

            } completion:nil];
            
        } else {
            [UIView animateWithDuration:duration delay:0 options:animationOptions animations:^{
                
                [self.selectHolder mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.size.mas_equalTo(CGSizeMake(88, 44));
                    make.right.equalTo(self.view).with.offset(-10);
                    make.bottom.equalTo(self.view).with.offset(-15);
                }];
                
            } completion:nil];
            
        }
    }
    
}


- (void)insertImageBase64String:(NSArray *)imageBase64StringArr{
    for(NSString *imageBase64String in imageBase64StringArr)
    {
        NSString *trigger = [NSString stringWithFormat:@"mail_editor.insertImageBase64String(\"%@\", \"%p\");", imageBase64String, &imageBase64String];
        [self.editorView stringByEvaluatingJavaScriptFromString:trigger];
    }
}



#pragma mark - UITextView Delegate

- (void)textViewDidChange:(UITextView *)textView {
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
    if ( overflow > 0 ) {
        // We are at the bottom of the visible text and introduced a line feed, scroll down (iOS 7 does not do it)
        // Scroll caret to visible area
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 7; // leave 7 pixels margin
        // Cannot animate with setContentOffset:animated: or caret will not appear
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
    
}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    
    NSString *urlString = [[request URL] absoluteString];
    //NSLog(@"web request");
    //NSLog(@"%@", urlString);
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    } else if ([urlString rangeOfString:@"callback://0/"].location != NSNotFound) {
        
    } else if ([urlString rangeOfString:@"debug://"].location != NSNotFound) {
        
        NSLog(@"Debug Found");
        
        // We recieved the callback
        NSString *debug = [urlString stringByReplacingOccurrencesOfString:@"debug://" withString:@""];
        debug = [debug stringByReplacingPercentEscapesUsingEncoding:NSStringEncodingConversionAllowLossy];
        NSLog(@"%@", debug);
        
    } else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        
        NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        [self editorDidScrollWithPosition:position];
        
    }
    return YES;
}




- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.editorLoaded = YES;
    
    if (!self.internalHTML) {
        self.internalHTML = @"";
    }
    [self updateHTML];
    
    if(self.placeholder) {
        [self setPlaceholderText];
    }
    
    if (self.customCSS) {
        [self updateCSS];
    }
    
    if (self.shouldShowKeyboard) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self focusTextEditor];
        });
    }
    
    /*
     
     Callback for when text is changed, solution posted by richardortiz84 https://github.com/nnhubbard/mailRichTextEditor/issues/5
     
     */
    JSContext *ctx = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    ctx[@"mail_editor.redoEvents"] = ^(){
//        NSLog(@"test按钮被点击了!!");
//        // 这里网页上的按钮被点击了, 客户端可以在这里拦截到,并进行操作
//    };
    ctx[@"contentUpdateCallback"] = ^(JSValue *msg) {
        
        if (self.receiveEditorDidChangeEvents) {
            
            [self editorDidChangeWithText:[self getText] andHTML:[self getHTML]];
            
        }
        
        [self checkForMentionOrHashtagInText:[self getText]];
        
    };
    [ctx evaluateScript:@"document.getElementById('mail_editor_content').addEventListener('input', contentUpdateCallback, false);"];
    
}

#pragma mark - Image Picker Delegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    //Dismiss the Image Picker
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info{
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage]?:info[UIImagePickerControllerOriginalImage];
    
    //Scale the image
    CGSize targetSize = CGSizeMake(selectedImage.size.width * self.selectedImageScale, selectedImage.size.height * self.selectedImageScale);
    UIGraphicsBeginImageContext(targetSize);
    [selectedImage drawInRect:CGRectMake(0,0,targetSize.width,targetSize.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Compress the image, as it is going to be encoded rather than linked
    NSData *scaledImageData = UIImageJPEGRepresentation(scaledImage, kJPEGCompression);
    
    //Encode the image data as a base64 string
    NSString *imageBase64String = [scaledImageData base64EncodedStringWithOptions:0];
    
    /*
     *  获取的图片的base64编码，存入Array里面，然后调用 [self insertImageBase64String:arr] 即可
     *  注意：在切换界面的时候，需要先调用 [self.editorView stringByEvaluatingJavaScriptFromString:@"mail_editor.prepareInsert();"];
     *  来保存光标的位置，否则插入图片无效
     */
    NSMutableArray *imageBase64StringArr = [[NSMutableArray alloc]init];
    [imageBase64StringArr addObject:imageBase64String];
    //Decide if we have to insert or update
    [self insertImageBase64String:[imageBase64StringArr copy]];
    
    self.imageBase64String = imageBase64String;
    
    //Dismiss the Image Picker
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Mention & Hashtag Support Section

- (void)checkForMentionOrHashtagInText:(NSString *)text {
    
    if ([text containsString:@" "] && [text length] > 0) {
        
        NSString *lastWord = nil;
        NSString *matchedWord = nil;
        BOOL ContainsHashtag = NO;
        BOOL ContainsMention = NO;
        
        NSRange range = [text rangeOfString:@" " options:NSBackwardsSearch];
        lastWord = [text substringFromIndex:range.location];
        
        if (lastWord != nil) {
            
            //Check if last word typed starts with a #
            NSRegularExpression *hashtagRegex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
            NSArray *hashtagMatches = [hashtagRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
            
            for (NSTextCheckingResult *match in hashtagMatches) {
                
                NSRange wordRange = [match rangeAtIndex:1];
                NSString *word = [lastWord substringWithRange:wordRange];
                matchedWord = word;
                ContainsHashtag = YES;
                
            }
            
            if (!ContainsHashtag) {
                
                //Check if last word typed starts with a @
                NSRegularExpression *mentionRegex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
                NSArray *mentionMatches = [mentionRegex matchesInString:lastWord options:0 range:NSMakeRange(0, lastWord.length)];
                
                for (NSTextCheckingResult *match in mentionMatches) {
                    
                    NSRange wordRange = [match rangeAtIndex:1];
                    NSString *word = [lastWord substringWithRange:wordRange];
                    matchedWord = word;
                    ContainsMention = YES;
                    
                }
                
            }
            
        }
        
        if (ContainsHashtag) {
            
            [self hashtagRecognizedWithWord:matchedWord];
            
        }
        
        if (ContainsMention) {
            
            [self mentionRecognizedWithWord:matchedWord];
            
        }
        
    }
    
}

#pragma mark - Callbacks

//Blank implementation
- (void)editorDidScrollWithPosition:(NSInteger)position {}

//Blank implementation
- (void)editorDidChangeWithText:(NSString *)text andHTML:(NSString *)html  {}

//Blank implementation
- (void)hashtagRecognizedWithWord:(NSString *)word {}

//Blank implementation
- (void)mentionRecognizedWithWord:(NSString *)word {}


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

#pragma mark - Record
//记录点击事件
-(void)recordTapEvents:(NSString *)msg
{
    selectNum++;
    [self.eventsArr addObject:msg];
}

-(void)redoEvents
{
    NSLog(@"i'm redoEvents");
}

@end
