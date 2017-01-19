//
//  ViewController.m
//  WebViewDemo
//
//  Created by huangshan on 2016/12/7.
//  Copyright © 2016年 huangshan. All rights reserved.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

#import "ContentImageCacheManager.h"

#define MAX_LIMIT_NUMS     (20)


//static NSString *JSString = @"document.getElementsByTagName('body')[0].style.background='#000000'";


@interface ViewController ()<WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) UILabel *allTextNumLabel;

@property (nonatomic, strong) WKWebViewConfiguration *wkConfig;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic , strong ) NSArray *imageUrlArray; //图片Url数组

@property (nonatomic , strong ) ContentImageCacheManager *imageCache; //内容图片缓存管理

@property (nonatomic, assign) NSInteger fontSize;

@property (nonatomic, assign) BOOL themeDay;



@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initData];
    
    [self initSubviews];
    
    [self requestContent];
    
    
}

- (void)initData{
    
    [ContentImageCacheManager initData];
    
    self.fontSize = 20;
    
    self.themeDay = YES;
}


- (void)requestContent {
    
    //如果image的格式不是HTML中固定的样式，那就需要过滤出img标签
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"testweb" ofType:@"html"];
    
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *cssType = @"White";
    
    NSString *frame = [NSString stringWithFormat:@"\
                       <html>\
                       <head>\
                       <meta http-equiv =\"Content-Type\" content=\"text/html; charset=utf-8\"/>\
                       <meta name = \"viewport\" content=\"width = device-width, initial-scale = 1, user-scalable=no\"/>\
                       <title></title>\
                       <link href=\"../css/WebContentStyle-%@.css\" rel=\"stylesheet\" type=\"text/css\"/>\
                       <script src=\"../js/jquery-1.12.3.min.js\"></script>\
                       </head>\
                       <body>\
                       <div class = \"content\">%@</div>\
                       </body>\
                       <script src=\"../js/WebContentHandle.js\"></script>\
                       </html>" , cssType , content];
    
    NSString *htmlPath = [[ContentImageCacheManager getCachePath:@"html"] stringByAppendingPathComponent:@"communityContent.html"];
    
    [frame writeToFile:htmlPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:htmlPath]]];
    
}

- (void)initSubviews {
    
    
    //改变字号button
    
    UIButton *fontButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    fontButton.frame = CGRectMake(20.0f, 20.0f, 80.0f, 44.0f);
    
    [fontButton setTitle:@"改变字号" forState:UIControlStateNormal];
    
    fontButton.backgroundColor = [UIColor redColor];
    
    [fontButton addTarget:self action:@selector(fontClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:fontButton];
    
    
    //改变主题button
    
    UIButton *themeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    themeButton.frame = CGRectMake(120.0f, 20.0f, 80.0f, 44.0f);
    
    [themeButton setTitle:@"改变颜色" forState:UIControlStateNormal];
    
    themeButton.backgroundColor = [UIColor blueColor];
    
    [themeButton addTarget:self action:@selector(themeClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:themeButton];
    
    
    
    
    [self.view addSubview:self.tableView];
    
    
    
    //webView
    
    WKWebViewConfiguration *webConfig = [[WKWebViewConfiguration alloc] init];
    
    webConfig.preferences = [[WKPreferences alloc] init]; // 设置偏好设置
    
    webConfig.preferences.minimumFontSize = 10; // 默认为0
    
    webConfig.preferences.javaScriptEnabled = YES; // 默认认为YES
    
    webConfig.preferences.javaScriptCanOpenWindowsAutomatically = NO; // 在iOS上默认为NO，表示不能自动通过窗口打开
    
    webConfig.userContentController = [[WKUserContentController alloc] init]; // 通过JS与webview内容交互
    
    
    [webConfig.userContentController addScriptMessageHandler:self name:@"clickImage"]; // 注入JS对象
    
    [webConfig.userContentController addScriptMessageHandler:self name:@"showImage"]; // 注入JS对象
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64.0f, self.view.frame.size.width, self.view.frame.size.height) configuration:webConfig];
    
    _webView.backgroundColor = [UIColor whiteColor];
    
    _webView.UIDelegate = self;
    
    _webView.navigationDelegate = self;
    
    _webView.scrollView.bounces = NO;
    
    _webView.scrollView.bouncesZoom = NO;
    
    _webView.scrollView.showsHorizontalScrollIndicator = NO;
    
    _webView.scrollView.directionalLockEnabled = YES;
    
    _webView.scrollView.scrollEnabled = NO;
    
    self.tableView.tableHeaderView = _webView;
}


#pragma mark - WKNavigationDelegate

// JS调用webView
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    
}



// 决定导航的动作，通常用于处理跨域的链接能否导航。WebKit对跨域进行了安全检查限制，不允许跨域，因此我们要对不能跨域的链接单独处理。但是，对于Safari是允许跨域的，不用这么处理。
// 这个是决定是否Reques
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    //判断请求url 拦截非本地请求
    
    NSURL *url = navigationAction.request.URL;
    
    if ([url.scheme isEqualToString:@"file"]) {
        
        decisionHandler(WKNavigationActionPolicyAllow);
        
    } else {
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

// 决定是否接收响应
// 这个是决定是否接收response
// 要获取response，通过WKNavigationResponse对象获取
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    
    decisionHandler(WKNavigationResponsePolicyAllow);
    
}

// 当main frame的导航开始请求时，会调用此方法
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
    
}

// 当main frame接收到服务重定向时，会回调此方法
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    
    
}

// 当main frame开始加载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    
    
}

// 当main frame的web内容开始到达时，会回调
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    
    
}

// 当main frame导航完成时，会回调
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
    __weak typeof(self) weakSelf = self;
    
    //初始化设置
    
    NSMutableDictionary *configInfo = [NSMutableDictionary dictionary];
    
    [configInfo setObject:@(self.fontSize) forKey:@"fontSize"];
    
    [configInfo setObject:(self.themeDay ? @"fafafa" : @"333333") forKey:@"backgroundColor"];
    
    [configInfo setObject:(self.themeDay ? @"333333" : @"777777") forKey:@"fontColor"];
    
    BOOL isClickLoad = NO;
    
    [configInfo setObject:@(isClickLoad) forKey:@"isClickLoad"];
    
    
    [webView evaluateJavaScript:@"alertContent('哈哈')" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        
        
    }];
    
    [webView evaluateJavaScript:[NSString stringWithFormat:@"initial(%@)" , [self jsonStringEncoded:configInfo]] completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"response: %@ error: %@", response, error);
        
        if (weakSelf) {
            
            //获取图片Url数组
            
            [weakSelf.webView evaluateJavaScript:@"getImageUrls()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                
                if (weakSelf) {
                    
                    if (!error) {
                        
                        weakSelf.imageUrlArray = [response copy];
                        
                        if (!isClickLoad) [weakSelf loadImages]; // 加载图片
                    }
                    
                }
                
            }];
            
            //更新webview高度
            
            [weakSelf updateWebViewHeight];
            
        }
        
    }];
}

// 当main frame最后下载数据失败时，会回调
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    
    
}

// 这与用于授权验证的API，与AFN、UIWebView的授权验证API是一样的
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    
    
}

// 当web content处理完成时，会回调
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
    
}

#pragma mark - WebView UIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    return self.webView;
}

- (void)webViewDidClose:(WKWebView *)webView {
    
    
}

/** 居然不能自己弹出alert，需要自己写alert */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    
    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    
    
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    
    
}

//- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo  {
//
//
//
//}
//
//- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions  {
//
//
//}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController  {
    
    
    
}



#pragma mark - 加载图片

- (void)loadImages{
    
    for (NSInteger i = 0; i < self.imageUrlArray.count ; i++) {
        
        [self loadImage:i];
    }
    
}

- (void)loadImage:(NSInteger)index{
    
    __weak typeof(self) weakSelf = self;
    
    if (self.imageUrlArray.count) {
        
        NSURL *imageUrl = [NSURL URLWithString:self.imageUrlArray[index]];
        
        if (!self.imageCache) self.imageCache = [[ContentImageCacheManager alloc] init];
        
        //设置加载中状态
        
        NSString *configJS = [NSString stringWithFormat:@"configImgState('1' , '%ld');" , index];
        
        [self.webView evaluateJavaScript:configJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            
            if (!weakSelf) return;
            
            //加载图片
            
            [weakSelf.imageCache loadImage:imageUrl ResultBlock:^(NSString *cachePath, BOOL result) {
                
                if (!weakSelf) return;
                
                //判断结果 并设置相应的状态
                
                if (result) {
                    
                    //设置图片Url和完成状态
                    
                    NSString *js = [NSString stringWithFormat:@"configImgState('4' , '%ld'); setImageUrl('%ld' , '%@');" , index , index , [NSURL fileURLWithPath:cachePath].absoluteString];
                    
                    [weakSelf.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                        
                        if (weakSelf) {
                            
                            if (!error) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    
                                    //更新webview高度
                                    
                                    [weakSelf updateWebViewHeight];
                                });
                            }
                            
                        }
                        
                    }];
                    
                } else {
                    
                    //设置加载失败状态
                    
                    NSString *configJS = [NSString stringWithFormat:@"configImgState('2' , '%ld');" , index];
                    
                    [weakSelf.webView evaluateJavaScript:configJS completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                        
                    }];
                    
                }
                
            }];
            
        }];
        
    }
    
}

#pragma mark - 更新webview高度

- (void)updateWebViewHeight{
    
    __weak typeof(self) weakSelf = self;
    
    [self.webView evaluateJavaScript:@"getContentHeight()" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        if (weakSelf) {
            
            if (!error) {
                
                CGFloat height = [response floatValue];
                
                if (weakSelf.webView.frame.size.height != height) {
                    
                    weakSelf.webView.frame = CGRectMake(0, 64.0f, weakSelf.webView.frame.size.width, height);
                    
                    weakSelf.tableView.tableHeaderView = weakSelf.webView;
                }
                
            }
            
        }
        
    }];
    
}

#pragma mark - Method

- (void)fontClick {
    
    self.fontSize += 4;
    
    NSString *js = [NSString stringWithFormat:@"configFontSize('%ld')" , self.fontSize];
    
    //设置字体大小
    
    __weak typeof(self) weakSelf = self;
    
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        //更新webview高度
        
        if (weakSelf) [weakSelf updateWebViewHeight];
    }];
    
}

- (void)themeClick {
    
    NSString *backgroundColor = (self.themeDay ? @"fafafa" : @"333333");
    
    NSString *fontColor = (self.themeDay ? @"333333" : @"777777");
    
    //设置背景颜色
    
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"configBackgroundColor('%@')", fontColor] completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"response: %@ error: %@", response, error);
    }];
    
    //设置字体颜色
    
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"configFontColor('%@')", backgroundColor] completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        NSLog(@"response: %@ error: %@", response, error);
    }];
    
    self.themeDay = !self.themeDay;
    
}



#pragma mark - TableView Delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", @(indexPath.row)];
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 20.0f;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50.0f;
}



#pragma mark - Lazy Loading


- (UITableView *)tableView {
    
    if (_tableView == nil){
        
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64.0f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - 64.0f) style:UITableViewStyleGrouped];
        
        _tableView.delegate = self;
        
        _tableView.dataSource = self;
        
        _tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        
        _tableView.separatorColor = [UIColor lightGrayColor];
        
        _tableView.backgroundColor = [UIColor clearColor];
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        
        [self.view addSubview:_tableView];
    }
    
    return _tableView;
}

- (NSString *)jsonStringEncoded:(NSDictionary *)tempDic {
    
    if ([NSJSONSerialization isValidJSONObject:tempDic]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tempDic options:0 error:&error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (!error) return json;
    }
    return nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
