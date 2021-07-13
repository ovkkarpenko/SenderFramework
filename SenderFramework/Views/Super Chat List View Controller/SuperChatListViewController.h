//
// Created by Roman Serga on 7/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EntityViewModel;

@interface SuperChatListViewController: UIViewController

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@end


@interface SuperChatListViewControllerTableDataSource: NSObject <UITableViewDataSource>

@property (nonatomic, strong) UITableView * tableView;

- (void)setChatModels:(NSArray *)chatModels;

- (id<EntityViewModel>)chatModelForIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath * _Nullable)indexPathForChatModel:(id <EntityViewModel>)chatModel;

@end

@class ChatTableViewCell;

@interface SuperChatListViewControllerTableDelegate: NSObject <UITableViewDelegate>

@property (nonatomic, strong) SuperChatListViewControllerTableDataSource * dataSource;

- (instancetype)initWithDataSource:(SuperChatListViewControllerTableDataSource *)dataSource;
- (void)setUpCellAppearance:(ChatTableViewCell *)cell forTableView:(UITableView *)tableView;

@end
