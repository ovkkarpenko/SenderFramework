//
//  PBInputTextView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/22/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@interface PBInputTextView : PBSubviewFacade <UITextFieldDelegate>

@property (nonatomic, strong) UITextField * inputTextField;
@property (nonatomic, strong) NSString * inputedText;
@property (nonatomic, weak) MainContainerModel * viewModel;

@end