//
//  ChatListViewController.m
//  SENDER
//
//  Created by Eugene Gilko on 11/2/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "ChatListViewController.h"
#import "UIView+ResizeAnimated.h"
#import "Item.h"
#import "UIAlertView+CompletionHandler.h"
#import "EntityViewModel.h"
#import "SenderNotifications.h"
#import "PBConsoleConstants.h"
#import "ServerFacade.h"
#import "ParamsFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import "ChatListViewController+UpdatesHandling.h"
#import "Owner.h"
#import "UIView+FindSearchTextField.h"
#import "ChatCategoryButton.h"
#import "ChatListStorage.h"
#import "ChatListChatViewModel.h"
#import "GlobalSearchContactViewModel.h"
#import "AddContactViewController.h"
#import "ProgressView.h"

#define timeSortDescriptor @"lastMessageTime"

@interface ChatListViewController ()
{
    NSInteger currentCategory;
    ChatTableViewCell * cellWithOpenOptions;
    BOOL opChatsMode;
    UIImage * _navigationBarImage;
}

@property (strong, nonatomic) IBOutletCollection(ChatCategoryButton) NSArray *categoryButtons;
@property (nonatomic, strong) NSMutableArray * visibleCategoryButtons;
@property (nonatomic, weak) IBOutlet UIView * categoryButtonsView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint * categoryButtonsViewHeight;

@property (nonatomic, weak) IBOutlet ChatCategoryButton * favoriteCategoryButton;
@property (nonatomic, weak) IBOutlet ChatCategoryButton * senderCategoryButton;
@property (nonatomic, weak) IBOutlet ChatCategoryButton * companiesCategoryButton;
@property (nonatomic, weak) IBOutlet ChatCategoryButton * groupCategoryButton;
@property (nonatomic, weak) IBOutlet ChatCategoryButton * opchatCategoryButton;

@property (nonatomic, strong) IBOutlet UIBarButtonItem * addUserButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * leftBarButton;

@property (nonatomic, strong) GlobalSearchManager * searchManager;
@property (nonatomic, strong) MWChatEditManager * chatEditManager;

@property (nonatomic, strong, nullable) UIImage * rightBarButtonImage;

@property (nonatomic, strong, nullable) UIView * syncProgressIndicator;

@end

@implementation ChatListViewController
{
    CGFloat initialCategoryButtonsViewHeight;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.presenter viewWasLoaded];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];

    initialCategoryButtonsViewHeight = self.categoryButtonsViewHeight.constant;

    MWChatEditManagerInput * chatEditManagerInput = [[MWChatEditManagerInput alloc] init];
    self.chatEditManager = [[MWChatEditManager alloc]initWithInput:chatEditManagerInput];

    self.view.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];
    self.contactsListTable.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];

    self.visibleCategoryButtons = [NSMutableArray arrayWithArray:self.categoryButtons];

    [self addSearchController];
    [self fixSearchBarColors];
    [self refreshAddContactButton];
    
    NSAssert(NSBundle.senderFrameworkResourcesBundle != nil, @"Cannot load SenderFrameworkBundle.");
    UINib * cellNib = [UINib nibWithNibName:@"ChatTableViewCell" bundle:NSBundle.senderFrameworkResourcesBundle];
    [self.contactsListTable registerNib:cellNib forCellReuseIdentifier:@"ChatTableViewCell"];
    [self customizeCategoryButtons];

    [self loadContactsFromDB];
    [self reloadCurrentCategory];

    self.contactsListTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.contactsListTable.separatorColor = [SenderCore sharedCore].stylePalette.lineColor;

    ChatTableViewCell * cell = [[cellNib instantiateWithOwner:nil options:nil] firstObject];
    CGFloat separatorInset = CGRectGetMaxX(cell.cellContainerView.iconImage.frame);
    self.contactsListTable.separatorInset = UIEdgeInsetsMake(0.0f, separatorInset, 0.0f, 0.0f);

    dispatch_async(dispatch_get_main_queue(), ^{
        [SENDER_SHARED_CORE.interfaceUpdater addUpdatesHandler:self];
    });

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(refreshAddContactButton)
                                                name:SenderCoreDidChangeFullVersionState
                                              object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[self navigationController]setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
    [self fixSearchBarColors];
    [self customizeTopBar];

    //Workaround for quick swipe-to-back to other controller and back
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self navigationController]setNavigationBarHidden:NO animated:animated];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [[self navigationController]setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    ChatSearchDisplayViewController * searchDisplayViewController = [[ChatSearchDisplayViewController alloc]init];

    GlobalSearchDisplayViewControllerDataSource * dataSource = [[GlobalSearchDisplayViewControllerDataSource alloc] initWithTableView:searchDisplayViewController.tableView];
    ChatSearchDisplayViewControllerTableDelegate * tableDelegate = [[ChatSearchDisplayViewControllerTableDelegate alloc] initWithDataSource:dataSource];

    self.searchManager = [[GlobalSearchManager alloc] initWithGlobalSearchOutput:dataSource
                                                         searchDisplayController:searchDisplayViewController
                                                             searchManagerOutput:dataSource
                                                               globalSearchInput:tableDelegate
                                                              searchManagerInput:tableDelegate];

    searchDisplayViewController.tableView.delegate = tableDelegate;

    self.searchManager.delegate = self;
    self.searchManager.searchController.delegate = self;
    self.searchManager.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchManager.globalSearchInput = tableDelegate;

    UISearchBar * searchBar = self.searchManager.searchController.searchBar;
    searchBar.tintColor = [[SenderCore sharedCore].stylePalette mainAccentColor];
    self.navigationItem.titleView = searchBar;
    self.definesPresentationContext = YES;
    searchBar.showsCancelButton = NO;
}

- (UIImage *)navigationBarImage
{
    if (!_navigationBarImage)
    {
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat statusBarHeight = self.navigationController.navigationBar.frame.origin.y;
        if (statusBarHeight <= 0) statusBarHeight = 20.0f;

        UIGraphicsBeginImageContext(CGSizeMake(1.0f, statusBarHeight + navigationBarHeight));

        CGContextRef currentContext = UIGraphicsGetCurrentContext();

        CGContextSetFillColorWithColor(currentContext, [SenderCore sharedCore].stylePalette.mainAccentColor.CGColor);
        CGContextFillRect(currentContext, CGRectMake(0.0f, 0.0f, 1.0f, statusBarHeight));

        CGContextSetFillColorWithColor(currentContext, [SenderCore sharedCore].stylePalette.navigationCommonBarColor.CGColor);
        CGContextFillRect(currentContext, CGRectMake(0.0f, statusBarHeight + 1.0f, 1.0f, navigationBarHeight));

        _navigationBarImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return _navigationBarImage;
}

- (void)customizeTopBar
{
    if (!self.searchManager.searchController.active) [self refreshNavigationItemButtonsAnimated:NO];

    UINavigationBar * navigationBar = self.navigationController.navigationBar;
    [[SenderCore sharedCore].stylePalette customizeNavigationBar:navigationBar];
    [[SenderCore sharedCore].stylePalette customizeNavigationItem:self.navigationItem];
    [navigationBar setBackgroundImage:[self navigationBarImage] forBarMetrics:UIBarMetricsDefault];
}

- (void)refreshAddContactButton
{
    if ([[SenderCore sharedCore] isFullVersionEnabled])
    {
        UIImage * addContactImage = [UIImage imageFromSenderFrameworkNamed:@"_add_contact"];
        addContactImage = [addContactImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.rightBarButtonImage = addContactImage;
    }
    else
    {
        self.rightBarButtonImage = nil;
    }
    [self refreshNavigationItemButtonsAnimated:NO];
}

- (void)refreshNavigationItemButtonsAnimated:(BOOL)animated
{
    [self.leftBarButton setImage:self.rightBarButtonImage];
    [self.navigationItem setRightBarButtonItem:(self.rightBarButtonImage ? self.addUserButton : nil) animated:animated];

    [self.leftBarButton setImage:self.leftBarButtonImage];
    [self.navigationItem setLeftBarButtonItem:(self.leftBarButtonImage ? self.leftBarButton : nil) animated:animated];
    
    [self iOS11FixNavigationItemsVerticalAlignment];
}

- (void)setSyncIndicatorVisible:(BOOL)syncIndicatorVisible
{
    /*
     * By some reason, if we don't call this code asynchronously
     * after synchronization image on favorite button will have wrong origin
     * and will be located outside of bounds of button.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        if (syncIndicatorVisible)
            [self addSyncProgressIndicator];
        else
            [self removeSyncProgressIndicator];
    });
}

- (void)addSyncProgressIndicator
{
    if (!self.syncProgressIndicator)
    {
        NSString * syncText = SenderFrameworkLocalizedString(@"sync_preloader", nil);
        self.syncProgressIndicator = [[ProgressView alloc] initWithText: syncText];
        self.syncProgressIndicator.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
        self.syncProgressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    }

    if (!self.syncProgressIndicator.superview)
    {
        [self.view insertSubview:self.syncProgressIndicator aboveSubview:self.contactsListTable];

        NSLayoutConstraint * xCenter = [NSLayoutConstraint constraintWithItem:self.syncProgressIndicator
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1.0f
                                                                     constant:0.0f];

        NSLayoutConstraint * bottomSpace = [NSLayoutConstraint constraintWithItem:self.syncProgressIndicator
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0f
                                                                         constant:-20.0f];


        NSLayoutConstraint * leftSpace = [NSLayoutConstraint constraintWithItem:self.syncProgressIndicator
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0f
                                                                       constant:20.0f];

        NSLayoutConstraint * rightSpace = [NSLayoutConstraint constraintWithItem:self.syncProgressIndicator
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationLessThanOrEqual
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0f
                                                                        constant:-20.0f];


        [self.view addConstraint:bottomSpace];
        [self.view addConstraint:xCenter];
        [self.view addConstraint:leftSpace];
        [self.view addConstraint:rightSpace];
        [self.view layoutIfNeeded];
    }
}

- (void)removeSyncProgressIndicator
{
    [self.syncProgressIndicator removeFromSuperview];
    self.syncProgressIndicator = nil;
}

/*
 * In iOS 11 adding UISearchBar as titleView of UINavigationItem increases UINavigationItem's height.
 * But after changing item's size barItems become misaligned vertically.
 * This method finds top and bottom constraints of stack views that contain barItems and changes their constants
 * to align vertically barItems to UINavigationItem's center.
 * */
- (void)iOS11FixNavigationItemsVerticalAlignment
{
    [self.navigationController.navigationBar layoutIfNeeded];
    
    NSString * currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:@"11" options:NSNumericSearch] != NSOrderedAscending)
    {
        UIView * navigationBarContentView;
        for (UIView * subview in [self.navigationController.navigationBar subviews])
        {
            if ([subview isKindOfClass:NSClassFromString(@"_UINavigationBarContentView")])
            {
                navigationBarContentView = subview;
                break;
            }
        }
        
        if (navigationBarContentView)
        {
            for (UIView * subview in [navigationBarContentView subviews])
            {
                if (![subview isKindOfClass:NSClassFromString(@"_UIButtonBarStackView")]) continue;
                
                NSLayoutConstraint * topSpaceConstraint;
                NSLayoutConstraint * bottomSpaceConstraint;
                
                CGFloat topConstraintMultiplier = 1.0f;
                CGFloat bottomConstraintMultiplier = 1.0f;
                
                for (NSLayoutConstraint * constraint in navigationBarContentView.constraints)
                {
                    if (constraint.firstItem == subview && constraint.firstAttribute == NSLayoutAttributeTop)
                    {
                        topSpaceConstraint = constraint;
                        break;
                    }
                    
                    if (constraint.secondItem == subview && constraint.secondAttribute == NSLayoutAttributeTop)
                    {
                        topConstraintMultiplier = -1.0f;
                        topSpaceConstraint = constraint;
                        break;
                    }
                }
                
                for (NSLayoutConstraint * constraint in navigationBarContentView.constraints)
                {
                    if (constraint.firstItem == subview && constraint.firstAttribute == NSLayoutAttributeBottom)
                    {
                        bottomSpaceConstraint = constraint;
                        break;
                    }
                    
                    if (constraint.secondItem == subview && constraint.secondAttribute == NSLayoutAttributeBottom)
                    {
                        bottomConstraintMultiplier = -1.0f;
                        bottomSpaceConstraint = constraint;
                        break;
                    }
                }
                
                CGFloat contentViewHeight = navigationBarContentView.frame.size.height;
                CGFloat subviewHeight = subview.frame.size.height;
                topSpaceConstraint.constant = topConstraintMultiplier * (contentViewHeight - subviewHeight) / 2.0f;
                bottomSpaceConstraint.constant = bottomConstraintMultiplier * (contentViewHeight - subviewHeight) / 2.0f;
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden forCategoryButton:(ChatCategoryButton *)categoryButton
{
    NSUInteger categoryButtonIndex = [self.visibleCategoryButtons indexOfObject:categoryButton];
    if (hidden)
        [self.visibleCategoryButtons removeObject:categoryButton];
    else if (categoryButtonIndex == NSNotFound)
        [self.visibleCategoryButtons addObject:categoryButton];

    [self layoutCategoryButtonsView];
}

- (void)setSelected:(BOOL)selected forCategoryButton:(ChatCategoryButton *)categoryButton
{
    UIColor * tintColor;
    UIColor * bottomLineColor;

    if (selected)
    {
        tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
        bottomLineColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    }
    else
    {
        tintColor = [SenderCore sharedCore].stylePalette.lineColor;
        bottomLineColor = [SenderCore sharedCore].stylePalette.lineColor;
    }

    categoryButton.backgroundColor = [[SenderCore sharedCore].stylePalette controllerCommonBackgroundColor];
    [categoryButton setTintColor:tintColor];
    categoryButton.bottomLine.backgroundColor = bottomLineColor;

    categoryButton.bigBottomLine = selected;
    [categoryButton setSelected:selected];
    [categoryButton setUserInteractionEnabled:!selected];
}

- (void)layoutCategoryButtonsView
{
    NSInteger buttonsCount = [self.visibleCategoryButtons count];
    CGFloat widthMultiplier = 0.0f;
    if (buttonsCount > 0) widthMultiplier = 1 / (CGFloat)buttonsCount;

    NSArray * constraintsToRemove = @[];
    NSArray * constraintsToAdd = @[];

    for (NSLayoutConstraint * categoryButtonWidth in self.categoryButtonsView.constraints)
    {
        if ([categoryButtonWidth.identifier isEqualToString:@"ButtonWidth"])
        {
            UIButton * categoryButton = categoryButtonWidth.firstItem;
            BOOL categoryButtonVisible = [self.visibleCategoryButtons containsObject:categoryButton];

            NSLayoutConstraint * newCategoryButtonWidth = [NSLayoutConstraint constraintWithItem:categoryButton
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.categoryButtonsView
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                      multiplier:categoryButtonVisible ? widthMultiplier : 0.0f
                                                                                        constant:0.0f];

            newCategoryButtonWidth.identifier = categoryButtonWidth.identifier;
            constraintsToRemove = [constraintsToRemove arrayByAddingObject:categoryButtonWidth];
            constraintsToAdd = [constraintsToAdd arrayByAddingObject:newCategoryButtonWidth];
        }
    }
    [self.categoryButtonsView removeConstraints:constraintsToRemove];
    [self.categoryButtonsView addConstraints:constraintsToAdd];

    [self.view layoutIfNeeded];
}

- (void)customizeCategoryButtons
{
    [self.favoriteCategoryButton setImage:[[UIImage imageFromSenderFrameworkNamed:@"favorites_newios"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.senderCategoryButton setImage: [[UIImage imageFromSenderFrameworkNamed:@"p2p_newios"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.companiesCategoryButton setImage: [[UIImage imageFromSenderFrameworkNamed:@"business_newios"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.groupCategoryButton setImage: [[UIImage imageFromSenderFrameworkNamed:@"groups_newios"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.opchatCategoryButton setImage: [[UIImage imageFromSenderFrameworkNamed:@"operators_newios"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

    CGFloat fontSize = 14.0f;

    if (IS_IPHONE_6 || IS_IPHONE_6P)
        fontSize = 16.0f;

    UIFont * mainFont = [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];

    for (ChatCategoryButton * categoryButton in self.categoryButtons)
    {
        categoryButton.titleLabel.font = mainFont;
        [categoryButton setTitle:@"" forState:UIControlStateNormal];
        [self setMessagesCount:0 forButton:categoryButton];
        [categoryButton addTarget:self action:@selector(handleCategoryTap:) forControlEvents:UIControlEventTouchDown];
        [categoryButton setTintColor:[SenderCore sharedCore].stylePalette.lineColor];
        categoryButton.bottomLine.backgroundColor = [SenderCore sharedCore].stylePalette.lineColor;
        categoryButton.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    }
}

-(void)setMessagesCount:(NSInteger)count forButton:(UIButton *)button
{
    NSString * titleString;
    if (count > 0)
        titleString = [NSString stringWithFormat:@" %li", (long)count];
    else
        titleString = @"";

    NSMutableAttributedString * attributedTitleSelected = [[NSMutableAttributedString alloc]initWithString:titleString];

    [attributedTitleSelected addAttribute:NSForegroundColorAttributeName value:[[SenderCore sharedCore].stylePalette alertColor] range:[titleString rangeOfString:titleString]];
    NSMutableAttributedString * attributedTitleNormal = [[NSMutableAttributedString alloc]initWithAttributedString:attributedTitleSelected];

    [button setAttributedTitle:attributedTitleNormal forState:UIControlStateNormal];
}

-(void)reloadCurrentCategory
{
    [self handleCategoryTap:self.categoryButtons[currentCategory] animated:NO];
}

- (void)handleCategoryTap:(ChatCategoryButton *)sender
{
    [self handleCategoryTap:sender animated:NO];
}

- (void)handleCategoryTap:(ChatCategoryButton *)sender animated:(BOOL)animated
{
    NSUInteger newCategory = [self.categoryButtons indexOfObject:sender];

    if (![self hasChats])
        newCategory = [self.categoryButtons indexOfObject:self.companiesCategoryButton];
        
    if ([self hasChats] && ![[self chatsForCategoryButton:sender] count])
    {
        newCategory++;
        newCategory = (newCategory >= [self.categoryButtons count]) ? 0 : newCategory;
        [self handleCategoryTap:self.categoryButtons[newCategory] animated:animated];
    }
    else
    {
        [self.contactsListTable reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

        for (ChatCategoryButton * categoryButton in self.categoryButtons)
            [self setSelected:categoryButton == sender forCategoryButton:categoryButton];

        mainArray = [self chatsForCategoryButton:sender];
        opChatsMode = mainArray == chatStorage.opers;

        if (!opChatsMode)
            [mainArray sortUsingDescriptors:[[ParamsFacade sharedInstance] getSortDescriptorsBy:timeSortDescriptor ascending:NO]];

        NSIndexSet * sectionsToReload = [NSIndexSet indexSetWithIndex:0];
        UITableViewRowAnimation reloadAnimation = UITableViewRowAnimationNone;
        if (animated)
            reloadAnimation = (currentCategory < newCategory) ? UITableViewRowAnimationLeft : UITableViewRowAnimationRight;

        BOOL areAnimationEnabledBeforeReloading = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:animated];
        [self.contactsListTable reloadSections:sectionsToReload withRowAnimation:reloadAnimation];
        [UIView setAnimationsEnabled:areAnimationEnabledBeforeReloading];

        currentCategory = newCategory;
    }
}

- (BOOL)hasChats
{
    if ([[SenderCore sharedCore] isFullVersionEnabled])
        return ![chatStorage isEmpty];
    else
        return [chatStorage.companies count] != 0;
}

- (NSMutableArray *)chatsForCategoryButton:(UIButton *)categoryButton
{
    if (![[SenderCore sharedCore] isFullVersionEnabled] && categoryButton != self.companiesCategoryButton)
        return nil;

    if (categoryButton == self.favoriteCategoryButton)
        return chatStorage.favorite;
    else if (categoryButton == self.senderCategoryButton)
        return chatStorage.users;
    else if (categoryButton == self.companiesCategoryButton)
        return chatStorage.companies;
    else if (categoryButton == self.groupCategoryButton)
        return chatStorage.groups;
    else if (categoryButton == self.opchatCategoryButton)
        return chatStorage.opers;
    else
        return nil;
}

#pragma mark DB Operations

- (void)loadContactsFromDB
{
    senderUnread = 0;
    groupUnread = 0;
    favUnread = 0;
    companiesUnread = 0;

    chatStorage = [[ChatListStorage alloc]init];

    NSArray * chats = [[CoreDataFacade sharedInstance] getChats];

    NSMutableArray * users = [NSMutableArray array];
    NSMutableArray * groups = [NSMutableArray array];
    NSMutableArray * companies  =  [NSMutableArray array];
    NSMutableArray * opers = [NSMutableArray array];

    for (Dialog * chat in chats)
    {
        if (chat.chatState == ChatStateRemoved || chat.chatState == ChatStateUndefined)
            continue;
        switch (chat.chatType) {
            case ChatTypeOperator:
                [opers addObject:chat];
                break;
            case ChatTypeGroup:
                [groups addObject:chat];
                break;
            case ChatTypeP2P:
                [users addObject:chat];
                break;
            case ChatTypeCompany:
                [companies addObject:chat];
                break;
            case ChatTypeUndefined:
                break;
        }
    }

    [self setChatsToArray:chatStorage.users fromArray:users withUnreadCounter:&senderUnread memberOf:usersGroupeName];
    [self setChatsToArray:chatStorage.groups fromArray:groups withUnreadCounter:&groupUnread memberOf:groupsGroupeName];
    [self setChatsToArray:chatStorage.companies fromArray:companies withUnreadCounter:&companiesUnread memberOf:companiesGroupeName];
    [self setChatsToArray:chatStorage.opers fromArray:opers withUnreadCounter:&operUnread memberOf:opersGroupeName];

    NSArray * sortDescriptors = [[ParamsFacade sharedInstance] getSortDescriptorsBy:timeSortDescriptor ascending:NO];

    [chatStorage.favorite sortUsingDescriptors:sortDescriptors];
    [chatStorage.users sortUsingDescriptors:sortDescriptors];
    [chatStorage.companies sortUsingDescriptors:sortDescriptors];
    [chatStorage.groups sortUsingDescriptors:sortDescriptors];
    [chatStorage.opers sortUsingDescriptors:sortDescriptors];

    [self updateCategoryButtons];
}

- (void)setChatsToArray:(NSMutableArray<id<EntityViewModel>> *)toArray
              fromArray:(NSArray<Dialog *> *)fromArray
      withUnreadCounter:(NSInteger *)counter
               memberOf:(NSString *)groupName
{
    *counter = 0;
    for (Dialog * chat in fromArray)
    {
        ChatListChatViewModel * model = [[ChatListChatViewModel alloc] initWithChat:chat];

        [toArray addObject:model];
        BOOL isUnreadChat = (model.unreadCount > 0 && ![model isNotificationsHidden] && ![model isCounterHidden]);
        NSInteger unreadCounterDelta = isUnreadChat ? 1 : 0;

        if (model.isFavorite)
        {
            [chatStorage.favorite addObject:model];
            favUnread += unreadCounterDelta;
//            [model updateGroupeID:favoriteGroupeName];
        }
        else
        {
//            [model updateGroupeID:groupName];
            *counter += unreadCounterDelta;
        }
    }
}

- (void)updateCategoryButtons
{
    NSUInteger visibleButtons = 0;
    for (ChatCategoryButton * button in self.categoryButtons)
    {
        BOOL buttonHidden = ![[self chatsForCategoryButton:button] count];
        visibleButtons += !buttonHidden;
        [self setHidden:buttonHidden forCategoryButton:button];
    }

    BOOL showCategoryButtons = visibleButtons > 1;

    self.categoryButtonsViewHeight.constant = showCategoryButtons ? initialCategoryButtonsViewHeight : 0.0f;

    [self setMessagesCount:favUnread forButton:self.favoriteCategoryButton];
    [self setMessagesCount:senderUnread forButton:self.senderCategoryButton];
    [self setMessagesCount:companiesUnread forButton:self.companiesCategoryButton];
    [self setMessagesCount:groupUnread forButton:self.groupCategoryButton];
    [self setMessagesCount:operUnread forButton:self.opchatCategoryButton];
}

#pragma mark - Other

- (IBAction)goToUserPage:(id)sender
{
    [self.presenter performMainAction];
}

- (IBAction)runAddNewContactForm:(id)sender
{
    [self.view endEditing:YES];
    [self.presenter startAddingContact];
}

- (NSMutableArray *)categoryArrayForChatType:(ChatType)chatType
{
    switch (chatType) {
        case ChatTypeP2P:
            return chatStorage.users;
            break;
        case ChatTypeOperator:
            return chatStorage.opers;
            break;
        case ChatTypeCompany:
            return chatStorage.companies;
            break;
        case ChatTypeGroup:
            return chatStorage.groups;
            break;
        case ChatTypeUndefined:
            return nil;
            break;
    }
}

#pragma mark - UITableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (opChatsMode) {
    }
    return 72.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (opChatsMode) {
    }
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (opChatsMode) {
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"ChatTableViewCell" forIndexPath:indexPath];
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatListChatViewModel * chatViewModel = [self getModelForIndexPath:indexPath];
    if ([cell isKindOfClass:[ChatTableViewCell class]])
    {
        ChatTableViewCell * chatCell = (ChatTableViewCell *)cell;
        [chatCell setCellModel:chatViewModel];
        NSString * senderChatID = [[[CoreDataFacade sharedInstance] getOwner] senderChatId];
        [chatCell setHidesDeleteButton:[chatViewModel.chat.chatID isEqualToString:senderChatID]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatTableViewCell * cell = [self.contactsListTable cellForRowAtIndexPath:indexPath];

    if (cell.optionsAreOpen)
    {
        [cell hideOptions];
        cellWithOpenOptions = nil;
    }
    else
    {
        ChatListChatViewModel * selectedModel = [self getModelForIndexPath:indexPath];
        [self openViewForModel:selectedModel];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)openViewForModel:(ChatListChatViewModel *)model
{
    [self.presenter showChatWithChat:model.chat actions:nil];
}

- (void)openViewForGlobalSearchModel:(GlobalSearchContactViewModel *)model
{
    if (model.userID)
    {
        NSString * chatID = chatIDFromUserID(model.userID);
        [self.presenter showChatWithChatID:chatID actions:nil];
    }
}

- (ChatListChatViewModel *)getModelForIndexPath:(NSIndexPath *)indexPath
{
    if (opChatsMode) {
        mainArray[indexPath.section][@"chatsOp"][indexPath.row];
    }
    return mainArray[indexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (opChatsMode) {
        NSArray * opChats = [mainArray firstObject][@"chatsOp"];
        return opChats.count;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (opChatsMode) {
        NSArray * opChats = mainArray[section][@"chatsOp"];
        return opChats.count;
    }

    return [mainArray count];
}

#pragma mark - ChatTableViewCell Delegate Methods

-(void)chatCell:(ChatTableViewCell *)cell willToggleOptions:(BOOL)optionsHidden
{
    if (optionsHidden)
    {
        if (cellWithOpenOptions == cell)
            cellWithOpenOptions = nil;
    }
    else
    {
        [cellWithOpenOptions hideOptions];
        cellWithOpenOptions = cell;
    }
}

- (void)chatCellDidPressDelete:(ChatTableViewCell *)cell
{
    [self deleteChatFromModel:cell.cellModel];
}

- (void)chatCellDidPressFavorite:(ChatTableViewCell *)cell
{
    if ([cell.cellModel isKindOfClass:[ChatListChatViewModel class]])
    {
        Dialog * chat = [(ChatListChatViewModel *)cell.cellModel chat];
        MWChatSettingsEditModel * editModel = [[MWChatSettingsEditModel alloc] initWithChatSettings:chat.dialogSetting];
        editModel.isFavorite = !editModel.isFavorite;
        [self.chatEditManager changeSettingsOfChat:chat newSettings:editModel completionHandler:nil];
    }
}

- (void)deleteChatFromModel:(ChatListChatViewModel *)cellModel
{
    Dialog  * chatToDelete = cellModel.chat;
    BOOL shouldDeleteNotLeave = (cellModel.chat.isP2P || cellModel.chat.chatState == ChatStateInactive);
    NSString * chatName = chatToDelete.name;

    NSString * title;
    NSString * message;
    NSString * cancelButtonTitle;

    if (shouldDeleteNotLeave)
    {
        title = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"delete_chat_specific_ios", nil), chatName];
        NSString * deleteChatKey = @"delete_chat_specific_message_ios";
        message = [NSString stringWithFormat:SenderFrameworkLocalizedString(deleteChatKey, nil), chatName];
        cancelButtonTitle = SenderFrameworkLocalizedString(@"delete_ios", nil);
    }
    else
    {
        title = [NSString stringWithFormat:SenderFrameworkLocalizedString(@"leave_chat_specific_ios", nil), chatName];
        NSString * deleteChatKey = @"leave_chat_specific_message_ios";
        message = [NSString stringWithFormat:SenderFrameworkLocalizedString(deleteChatKey, nil), chatName];
        cancelButtonTitle = SenderFrameworkLocalizedString(@"leave_chat_ios", nil);
    }

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:title
                                                                              message:message
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction * leaveAction = [UIAlertAction actionWithTitle:cancelButtonTitle
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action)
                                                         {
                                                             if (shouldDeleteNotLeave)
                                                                 [self.chatEditManager deleteWithChat:cellModel.chat
                                                                                    completionHandler:nil];
                                                             else
                                                                 [self.chatEditManager leaveWithChat:cellModel.chat
                                                                                   completionHandler:nil];
                                                         }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:SenderFrameworkLocalizedString(@"cancel", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [alertController addAction:leaveAction];
    [alertController addAction:cancelAction];
    [alertController mw_safePresentInViewController:self animated:YES completion:nil];
}

#pragma mark - UISearchController Delegate

- (void)willPresentSearchController:(UISearchController *)searchController
{
    if (searchController == self.searchManager.searchController)
    {
        BOOL fullVersionEnabled = [[SenderCore sharedCore] isFullVersionEnabled];
        self.searchManager.localModels = fullVersionEnabled ? [chatStorage allChats] : [chatStorage companies];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    [self.delegate chatListViewControllerDidOpenSearch:self];
}

- (void)willDismissSearchController:(UISearchController *)searchController
{
    if (searchController == self.searchManager.searchController)
        [self refreshNavigationItemButtonsAnimated:YES];
}

- (void)didDismissSearchController:(UISearchController *)searchController;
{
    if (searchController == self.searchManager.searchController)
        self.searchManager.localModels = @[];
    [self.delegate chatListViewControllerDidCloseSearch:self];
}

#pragma mark - ChatSearchManager Delegate

-(void)chatSearchManager:(ChatSearchManager *)manager didSelectCellModel:(id<EntityViewModel>)cellModel
{
    if ([cellModel isKindOfClass:[ChatListChatViewModel class]])
        [self openViewForModel:(ChatListChatViewModel *)cellModel];
    else if ([cellModel isKindOfClass:[GlobalSearchContactViewModel class]])
        [self openViewForGlobalSearchModel:(GlobalSearchContactViewModel *)cellModel];
}

-(void)chatSearchManager:(ChatSearchManager *)manager didSelectAction:(ActionCellModel *)action
{
    if ([action.cellOper isEqualToString:@"callRobotInP2PChat"] ||
        [action.cellOper isEqualToString:@"callRobot"] ||
        [action.cellOper isEqualToString:@"startP2PChat"])
        [self.presenter launchAction:action];
    else if ([action.cellOper isEqualToString:@"qrScan"])
        [self.presenter showQRScanner];
    else if ([action.cellOper isEqualToString:@"goTo"]) ;
}

#pragma mark - AddToContainerInNavigationWireframe Events Handler

- (void)prepareForPresentationWithAddToContainerInNavigationWireframe:(id)AddToContainerInNavigationWireframe
{
    UIImage * menuImage = [UIImage imageFromSenderFrameworkNamed:@"_menu"];
    self.leftBarButtonImage = [menuImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithAddToContainerInNavigationWireframe:(id)AddToContainerInNavigationWireframe
{

}

#pragma mark - ModalInNavigationWireframe Events Handler

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    UIImage * menuImage = [UIImage imageFromSenderFrameworkNamed:@"close"];
    self.leftBarButtonImage = [menuImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{

}


@end
