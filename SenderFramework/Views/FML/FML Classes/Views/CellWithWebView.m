//
//  CellWithWebView.m
//  SENDER
//
//  Created by Eugene Gilko on 10/7/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "CellWithWebView.h"
#import "SenderNotifications.h"

@implementation CellWithWebView


#pragma mark WEBVIEW helpers

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    
    self.viewHeight = fittingSize.height + 30.0;
    
    CGRect rectSelf = self.frame;
    rectSelf.size = fittingSize;
    rectSelf.size.height = self.viewHeight;
    self.frame = rectSelf;
    
    frame.size = fittingSize;
    aWebView.frame = frame;
    
    //    self.heightOfWeb.constant = frame.size.height;
    // NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
//    [[NSNotificationCenter defaultCenter] postNotificationName:ReloadActiveChat object:nil];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // NSLog(@"WEB VIEW ERROR  %@!!!!",error);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
//    if ([request.URL.scheme isEqualToString:@"http"]) {
//        if ([request.URL.host isEqualToString:@"sender.mobi"]) {
//            // do capture action
//            NSString * rr = request.URL;
//            // NSLog(@"ACTION!!!!");
//        }
//        return YES;
//    }
    return YES;
}

- (void)loadViewFromString:(NSString *)htmlString
{
    webView = [[UIWebView alloc] initWithFrame:SENDER_SHARED_CORE.window.frame];
    [self addSubview:webView];
    
//    WebPreferences *webPrefs = [WebPreferences standardPreferences];
//    [webPrefs setUserStyleSheetEnabled:YES];
//    //Point to wherever your local/custom css is
//    [webPrefs setUserStyleSheetLocation:[NSBundle.senderFrameworkResourcesBundle URLForResource:@"style" withExtension:@"css"]];
//    
//    //Set your webview's preferences
//    [myWebView setPreferences:webPrefs];
    

    NSString * path = [SENDER_FRAMEWORK_BUNDLE bundlePath];
    NSURL * baseURL = [NSURL fileURLWithPath:path];
    webView.delegate = self;
    [webView loadHTMLString:htmlString baseURL:baseURL];
}

//- (void)loadViewDataFromULR:(NSString *)URL
//{
//    NSURL *url = [NSURL URLWithString:URL];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    
////    [webView loadRequest:request];
//}

- (void)clearWebView
{
//    [WebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
}

//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
//{
//    NSArray * compenents = [request.URL.absoluteString componentsSeparatedByString:@"#"];
//    if (compenents.count > 1) {
//        NSString * cmd = compenents[1];
//        if ([cmd rangeOfString:@"cmd_alertMessage"].location != NSNotFound) {
//            // Call your obj-c method and get appropriated param
//            NSString * jsFunction = [NSString stringWithFormat:@"setParameterFromAAAMethod('%@')", [self aaa]];
//            // Return this param back to js
//            NSString * alertMessage = [webView stringByEvaluatingJavaScriptFromString:jsFunction];
//        }
//    }
//    
//    
//    return YES;
//}


@end
