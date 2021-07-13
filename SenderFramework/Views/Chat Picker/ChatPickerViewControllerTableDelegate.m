//
// Created by Roman Serga on 8/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerViewControllerTableDelegate.h"
#import "ChatTableViewCell.h"
#import "SuperChatListViewController.h"
#import "ChatPickerManager.h"
#import "ChatTableViewCell+SelectedAccessory.h"
#import <SenderFramework/SenderFramework-Swift.h>

@implementation ChatPickerViewControllerTableDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<EntityViewModel> cellModel = [self.dataSource chatModelForIndexPath:indexPath];
    if (!cellModel)
        return;

    [self.presenter selectEntity:cellModel];
    UITableViewCell * selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([selectedCell isKindOfClass:[UITableViewCell class]])
    {
        if ([self.presenter isEntitySelectedWithEntity:cellModel] && [self.presenter isMultipleSelectionAllowed])
            [(ChatTableViewCell *)selectedCell showSelectedAccessory];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<EntityViewModel> cellModel = [self.dataSource chatModelForIndexPath:indexPath];
    if (!cellModel)
        return;

    [self.presenter selectEntity:cellModel];
    UITableViewCell * selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([selectedCell isKindOfClass:[UITableViewCell class]])
    {
        if (![self.presenter isEntitySelectedWithEntity:cellModel] && [self.presenter isMultipleSelectionAllowed])
            [(ChatTableViewCell *)selectedCell showDeselectedAccessory];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];

    if ([cell isKindOfClass:[ChatTableViewCell class]] && tableView == self.dataSource.tableView)
    {
        ChatTableViewCell *chatCell = (ChatTableViewCell *) cell;
        id <EntityViewModel> cellModel = [self.dataSource chatModelForIndexPath:indexPath];
        if (!cellModel)
            return;

        if ([self.presenter isMultipleSelectionAllowed])
        {
            chatCell.selectedBackgroundView.backgroundColor = [UIColor clearColor];

            BOOL isModelSelected = [self.presenter isEntitySelectedWithEntity:cellModel];
            if (isModelSelected)
            {
                [chatCell showSelectedAccessory];
                [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
            else
            {
                [chatCell showDeselectedAccessory];
            }
        }
    }
}

@end