//
//  PBPopUpSelector.m
//
//  Created by Eugene Gilko on 7/24/14.
//  Copyright (c) 2014 Eugene Gilko. All rights reserved.
//


#import "PBPopUpSelector.h"
#import "PBConsoleConstants.h"

@interface PBPopUpSelector()
{
    UIButton * cancelButton;
    UITableView * mainTable;
}

@end

@implementation PBPopUpSelector

- (instancetype _Nonnull)initWithFrame:(CGRect)frame andValues:(NSArray *)values
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.values = values;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
    }
    return self;
}

- (void)addCancelButton
{
    CGFloat cancelButtonWidth = 100.0f;
    CGFloat cancelButtonHeight = 55.0f;
    
    CGRect cancelFrame = CGRectMake((self.frame.size.width - cancelButtonWidth)/2,
                                    self.frame.size.height - cancelButtonHeight - 15.0f,
                                    cancelButtonWidth,
                                    cancelButtonHeight);
    cancelButton = [[UIButton alloc] initWithFrame:cancelFrame];
    
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIColor * titleColor = [UIColor colorWithRed:100.0f/255.0f
                                           green:180.0f/255.0f
                                            blue:240.0f/255.0f alpha:1.0];
    [cancelButton setTitleColor:titleColor forState:UIControlStateHighlighted];
    [cancelButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:22.0]];

    [cancelButton addTarget:self action:@selector(cancelPushed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:cancelButton];
}

- (void)setupTableView
{
    mainTable = [[UITableView alloc] init];
    mainTable.scrollEnabled = NO;
    mainTable.dataSource = self;
    mainTable.delegate = self;
    
    int count = self.values.count;
    
    CGFloat w = self.frame.size.width - 60.0f;
    CGRect rect = CGRectMake(30.0f, 100.0f, w, count * 70.0f);
    
    if (count > 5) {
        rect.size.height = 350;
        mainTable.scrollEnabled = YES;
    }
    
    mainTable.frame = rect;
    mainTable.backgroundColor = [UIColor clearColor];
//    [mainTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [mainTable setContentInset:UIEdgeInsetsZero];
    [self addSubview:mainTable];
    
    [self addCancelButton];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.values.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ChatCellIdentifier = @"ChatCellIdentifier";

    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:ChatCellIdentifier];

    cell.textLabel.text = [[self.values[indexPath.row] valueForKey:@"t"] description];
    cell.textLabel.font = [PBConsoleConstants headerFont];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.minimumScaleFactor = 0.5;
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    UIView * bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [PBConsoleConstants colorGrey];
    [cell setSelectedBackgroundView:bgColorView];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.delegate popUpSelector:self didSelectValue:self.values[indexPath.row]];
}

- (IBAction)cancelPushed:(id)sender
{
    [self.delegate popUpSelectorDidCancel:self];
}

@end
