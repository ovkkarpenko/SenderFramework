//
//  PBLoadFileView.h
//  SENDER
//
//  Created by Eugene Gilko on 4/11/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "PBSubviewFacade.h"

@class PBLoadFileView;

@protocol PBLoadFileViewDelegate <PBSubviewDelegate>

- (void)loadFileForFileView:(PBLoadFileView *)fileView;

@end

@interface PBLoadFileView : PBSubviewFacade

@property (nonatomic, weak) MainContainerModel * viewModel;

@property (nonatomic, strong) UIButton * loadLinkButton;
@property (nonatomic, strong) UILabel * fileName;

@property (nonatomic, weak) id<PBLoadFileViewDelegate> delegate;

- (void)setImageURL:(NSURL *)imageURL imageData:(NSData *)imageData;

@end
