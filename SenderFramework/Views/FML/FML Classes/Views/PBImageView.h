//
//  PBImageView.h
//  ZiZZ
//
//  Created by Eugene Gilko on 7/25/14.
//  Copyright (c) 2014 Dima Yarmolchuk. All rights reserved.
//

#import "PBSubviewFacade.h"

@interface PBImageView : PBSubviewFacade

@property (nonatomic, weak) MainContainerModel * viewModel;

- (void)setImage:(NSData *)imageData;

@end
