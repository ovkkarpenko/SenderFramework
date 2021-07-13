//
// Created by Roman Serga on 1/2/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "ChatPickerViewController.h"
#import "EntityViewModel.h"
#import "UIView+FindSearchTextField.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "ChatPickerViewControllerTableDelegate.h"
#import "ChatPickerSearchTableDataSource.h"

@interface ChatPickerViewController()

@property (nonatomic, strong) ChatSearchManager * searchManager;
@property (nonatomic, strong) SuperChatListViewController * searchDisplayViewController;

@end

@implementation ChatPickerViewController

#pragma mark - Initialization

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = SenderFrameworkLocalizedString(@"select_user_ios", nil);
        self.pickerTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
        self.pickerTableDelegate = [[ChatPickerViewControllerTableDelegate alloc] initWithDataSource:self.pickerTableDataSource];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.title = SenderFrameworkLocalizedString(@"select_user_ios", nil);
        self.pickerTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
        self.pickerTableDelegate = [[ChatPickerViewControllerTableDelegate alloc] initWithDataSource:self.pickerTableDataSource];
    }
    return self;
}

#pragma mark - Implementation

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pickerTableDataSource.tableView = self.tableView;

    self.tableView.dataSource = self.pickerTableDataSource;
    self.tableView.delegate = self.pickerTableDelegate;
    self.tableView.allowsMultipleSelection = [self.presenter isMultipleSelectionAllowed];

    self.pickerTableDelegate.presenter = self.presenter;

    [self customizeNavigationBar];
    [self addSearchController];
    [self fixSearchBarColors];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameWillChangeNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];

    [self.presenter viewWasLoaded];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardFrameWillChangeNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval animationDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat bottomInset = CGRectGetMaxY(self.tableView.frame) - CGRectGetMinY(keyboardFrame);
    UIEdgeInsets newContentInset = self.searchDisplayViewController.tableView.contentInset;
    newContentInset.bottom = bottomInset;
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue] << 16;
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:animationCurve
                     animations:^{
                         self.searchDisplayViewController.tableView.contentInset = newContentInset;
                         self.searchDisplayViewController.tableView.scrollIndicatorInsets = newContentInset;
                     } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self customizeNavigationBar];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self fixSearchTableInset];
}

- (void)fixSearchTableInset
{
    CGFloat newTopInset;
    NSString * currSysVer = [[UIDevice currentDevice] systemVersion];
    /*
     * For iOS 11 we just need to set contentInset to avoid searchBar.
     */
    if ([currSysVer compare:@"11" options:NSNumericSearch] != NSOrderedAscending)
    {
        newTopInset = self.searchManager.searchController.searchBar.frame.size.height;
    }
    else
    {
        CGRect searchBarFrameInSearchTable = [self.tableView convertRect:self.searchManager.searchController.searchBar.frame
                                                                  toView:self.searchDisplayViewController.tableView];
        newTopInset = CGRectGetMaxY(searchBarFrameInSearchTable);
    }
    UIEdgeInsets inset = self.searchDisplayViewController.tableView.contentInset;
    inset.top = newTopInset;
    self.searchDisplayViewController.tableView.scrollIndicatorInsets = inset;
    self.searchDisplayViewController.tableView.contentInset = inset;
}

- (void)customizeNavigationBar
{
    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = NO;

    UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(closeButtonPressed:)];
    cancelButton.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    self.navigationItem.leftBarButtonItem = cancelButton;
    if ([self.presenter isMultipleSelectionAllowed])
    {
        UIBarButtonItem * doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonPressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        doneButton.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    }

    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
    [[self navigationController]setNavigationBarHidden:NO];
}

- (void)fixSearchBarColors
{
    NSDictionary * textAttributes = @{NSForegroundColorAttributeName:[SenderCore sharedCore].stylePalette.mainTextColor,
            NSFontAttributeName : [SenderCore sharedCore].stylePalette.inputTextFieldFont};
    UITextField * searchTextField = [self.searchManager.searchController.searchBar searchTextField];
    [searchTextField setDefaultTextAttributes: textAttributes];
    [searchTextField setBackgroundColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
}

- (void)addSearchController
{
    NSString * sbName = @"SuperChatListViewController";
    self.searchDisplayViewController = [SuperChatListViewController loadFromSenderFrameworkStoryboardWithName: sbName];
    //Loading view in order to have non-nil tableView
    self.searchDisplayViewController.view;
    self.searchDisplayViewController.tableView.allowsMultipleSelection = [self.presenter isMultipleSelectionAllowed];

    self.searchTableDataSource = [[ChatPickerSearchTableDataSource alloc] init];
    self.searchTableDataSource.tableView = self.searchDisplayViewController.tableView;

    self.searchManager = [[ChatSearchManager alloc] initWithSearchDisplayController:self.searchDisplayViewController
                                                                searchManagerOutput:self.searchTableDataSource
                                                                 searchManagerInput:self.pickerTableDelegate];

    self.searchDisplayViewController.tableView.delegate = self.pickerTableDelegate;
    self.searchManager.searchController.delegate = self;
    self.searchManager.searchController.hidesNavigationBarDuringPresentation = NO;

    UISearchBar *searchBar = self.searchManager.searchController.searchBar;
    searchBar.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    searchBar.showsCancelButton = NO;
    self.tableView.tableHeaderView = searchBar;

    self.definesPresentationContext = YES;
    self.searchDisplayViewController.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)closeButtonPressed:(id)sender
{
    [self.presenter cancelPickingEntities];
}

- (void)doneButtonPressed:(id)sender
{
    [self.presenter startFinishingPickingEntities];
}

#pragma mark - UISearchController Delegate

- (void)willPresentSearchController:(UISearchController *)searchController
{
    self.pickerTableDelegate.dataSource = self.searchTableDataSource;
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    self.pickerTableDelegate.dataSource = self.pickerTableDataSource;

    for (NSIndexPath * indexPath in [self.tableView indexPathsForSelectedRows])
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView reloadData];
}

#pragma mark - ChatPickerDisplayController

- (void)showNoUsersSelectedError
{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:SenderFrameworkLocalizedString(@"select_person_ios", nil)
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction * okAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"ok_ios", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil];
    [alert addAction:okAction];
    [alert mw_safePresentInViewController:self animated:YES completion:nil];
}

#pragma mark - EntityPicker View

- (void)entityWasUpdated:(id<EntityViewModel>)entity
{
    NSIndexPath * entityIndexPath = [self.pickerTableDataSource indexPathForChatModel:entity];
    if (entityIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[entityIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updateWithEntities:(NSArray *)entities
{
    self.pickerTableDataSource.chatModels = entities;
    [self.tableView reloadData];
    self.searchManager.localModels = entities;
}

@end