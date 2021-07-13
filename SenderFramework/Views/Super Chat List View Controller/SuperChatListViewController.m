//
// Created by Roman Serga on 7/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "SuperChatListViewController.h"
#import "EntityViewModel.h"
#import "ChatTableViewCell.h"
#import "UIView+MWSubviews.h"

@implementation SuperChatListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkResources bundle");
    UINib * cellNib = [UINib nibWithNibName:@"ChatTableViewCell" bundle:NSBundle.senderFrameworkResourcesBundle];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"ChatTableViewCell"];

    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    self.tableView.backgroundColor = self.view.backgroundColor;

    if ([SenderCore sharedCore].stylePalette.lineColor)
        self.tableView.separatorColor = [SenderCore sharedCore].stylePalette.lineColor;
}

@end

@interface SuperChatListViewControllerTableDataSource()

@property (nonatomic, strong, readwrite) NSArray<id<EntityViewModel>> * _chatModels;

@end

@implementation SuperChatListViewControllerTableDataSource

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    _tableView.dataSource = self;
}

- (void)setChatModels:(NSArray *)chatModels;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self._chatModels = chatModels;
        [self.tableView reloadData];
    });
}

- (id<EntityViewModel>)chatModelForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self._chatModels.count)
        return nil;
    return self._chatModels[indexPath.row];
}

- (NSIndexPath *)indexPathForChatModel:(id<EntityViewModel>) chatModel
{
    NSUInteger modelIndex = [self._chatModels indexOfObject:chatModel];
    if (modelIndex == NSNotFound) return nil;

    return [NSIndexPath indexPathForRow:modelIndex inSection:0];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self._chatModels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell" forIndexPath:indexPath];
    return cell;
}

@end

@implementation SuperChatListViewControllerTableDelegate

- (instancetype)initWithDataSource:(SuperChatListViewControllerTableDataSource *)dataSource
{
    self = [super init];
    if (self)
    {
        self.dataSource = dataSource;
    }
    return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 72.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[ChatTableViewCell class]] && tableView == self.dataSource.tableView)
    {
        ChatTableViewCell * chatCell = (ChatTableViewCell *)cell;
        id<EntityViewModel> cellModel = [self.dataSource chatModelForIndexPath:indexPath];
        chatCell.cellModel = cellModel;
        [self setUpCellAppearance:chatCell forTableView:tableView];
    }
}

-(void)setUpCellAppearance:(ChatTableViewCell *)cell forTableView:(UITableView *)tableView
{
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = tableView.backgroundColor;
    cell.cellContainerView.backgroundColor = tableView.backgroundColor;
    cell.hidesUnread = YES;
    cell.hidesOptions = YES;
    cell.hidesFavoriteIndicator = YES;
    cell.hidesTypeImage = YES;
}

@end