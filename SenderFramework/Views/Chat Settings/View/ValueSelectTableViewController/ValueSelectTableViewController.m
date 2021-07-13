//
//  ValueSelectTableViewController.m
//  SENDER
//
//  Created by Roman Serga on 21/4/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "ValueSelectTableViewController.h"

#define valueCellIdentifier @"valueCell"

@implementation ValueSelectTableViewController
{
    BOOL hasLoaded;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:valueCellIdentifier];
    self.tableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];

    self.tableView.backgroundColor = [SenderCore sharedCore].stylePalette.commonTableViewBackgroundColor;

    if ([SenderCore sharedCore].stylePalette.lineColor)
        self.tableView.separatorColor = [SenderCore sharedCore].stylePalette.lineColor;

    [[SenderCore sharedCore].stylePalette customizeNavigationBar:self.navigationController.navigationBar];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!hasLoaded)
    {
        NSIndexPath * selectedPath = [NSIndexPath indexPathForRow:self.indexOfSelectedValue inSection:0];
        [self tableView:self.tableView didSelectRowAtIndexPath:selectedPath];
        [self.tableView selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [[self.tableView cellForRowAtIndexPath:selectedPath]setSelected:NO];
        hasLoaded = YES;
    }
}

- (void)update
{
    NSIndexPath * oldSelectedPath = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:oldSelectedPath animated:NO];
    [self tableView:self.tableView didDeselectRowAtIndexPath:oldSelectedPath];

    [self.tableView reloadData];

    NSIndexPath * selectedPath = [NSIndexPath indexPathForRow:self.indexOfSelectedValue inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:selectedPath];
    [self.tableView selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [[self.tableView cellForRowAtIndexPath:selectedPath]setSelected:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
    {
        NSInteger selectedValueIndex = self.tableView.indexPathForSelectedRow.row;
        if ([self.delegate respondsToSelector:@selector(valueSelectTableViewController:didFinishWithValueAtIndex:)])
            [self.delegate valueSelectTableViewController:self didFinishWithValueAtIndex:selectedValueIndex];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.values count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:valueCellIdentifier];
    cell.textLabel.text = self.values[indexPath.row];
    cell.textLabel.textColor = [SenderCore sharedCore].stylePalette.mainTextColor;
    cell.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    cell.contentView.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    cell.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    selectedCell.accessoryView.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [selectedCell setSelected:NO animated:YES];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryNone;
}

@end
