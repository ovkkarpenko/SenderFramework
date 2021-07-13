//
//  SBItemView_protected.h
//  SENDER
//
//  Created by Roman Serga on 9/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#ifndef SENDER_SBItemView_protected_h
#define SENDER_SBItemView_protected_h

#import "SBItemView.h"

@interface SBItemView()

@property (nonatomic, weak) IBOutlet UIButton * actionButton;
@property (nonatomic, weak) IBOutlet UILabel * titleLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * titleLabelHeight;

-(NSURL *)URLForIconWithLink:(NSString *)link;
- (NSURL *)URLForIconWithLink:(NSString *)link withCustomScale:(NSString *)imageScale;
-(void)setLocalizedTitleFromData:(NSData *)data;

@end

#endif
