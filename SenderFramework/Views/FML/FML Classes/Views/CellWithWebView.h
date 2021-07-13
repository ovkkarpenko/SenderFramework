//
//  CellWithWebView.h
//  SENDER
//
//  Created by Eugene Gilko on 10/7/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
// UNUSED CLASS

@interface CellWithWebView : UIView <UIWebViewDelegate>
{
    UIWebView * webView;
}

@property (nonatomic) float viewHeight;

- (void)loadViewFromString:(NSString *)htmlString;

@end

//        CellWithWebView * celWithWeb = [[CellWithWebView alloc] init];
//        [celWithWeb loadViewFromString:[[NSString alloc] initWithData:self.incomingMessage.data encoding:NSUTF8StringEncoding]];
//
//        self.incomingMessage.viewForCell = celWithWeb;
//        [visibleMessages addObject:self.incomingMessage];