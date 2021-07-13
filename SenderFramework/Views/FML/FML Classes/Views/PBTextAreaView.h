//
//  PBTextAreaView.h
//  SENDER
//
//  Created by Eugene Gilko on 5/27/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@interface PBTextAreaView : PBSubviewFacade <UITextViewDelegate>

@property (nonatomic, strong) UITextView * inputTextView;
@property (nonatomic, strong) NSString * inputedText;
@property (nonatomic, weak) MainContainerModel * viewModel;

@end