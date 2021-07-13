//
//  ChatListViewController.h
//  SENDER
//
//  Created by Eugene Gilko on 11/2/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "ChatTableViewCell.h"
#import "ActionCellModel.h"

#define favoriteGroupeName @"favorite" 
#define usersGroupeName @"users"
#define groupsGroupeName @"groups"
#define companiesGroupeName @"companies"
#define opersGroupeName @"oper"

@class Contact;
@class ChatListViewController;
@class ChatListStorage;

@protocol ChatListViewProtocol;
@protocol ChatListPresenterProtocol;
@protocol ChatSearchManagerDelegate;
@protocol ChatsChangesHandler;
@protocol MessagesChangesHandler;
@protocol AddToContainerInNavigationWireframeEventsHandler;
@protocol ModalInNavigationWireframeEventsHandler;

@protocol ChatListViewControllerDelegate <NSObject>

- (void)chatListViewController:(ChatListViewController *)chatListViewController
              didChooseContact:(Contact *)contact;

- (void)chatListViewController:(ChatListViewController *)chatListViewController
               didChooseAction:(ActionCellModel *)action;

- (void)chatListViewControllerDidChooseUserPage:(ChatListViewController *)chatListViewController;

- (void)chatListViewController:(ChatListViewController *)chatListViewController didChooseDialog:(Dialog *)dialog;

- (void)chatListViewControllerDidOpenSearch:(ChatListViewController *)chatListViewController;

- (void)chatListViewControllerDidCloseSearch:(ChatListViewController *)chatListViewController;

@end

@interface ChatListViewController : UIViewController <UITableViewDataSource,
                                                      UITableViewDelegate,
                                                      UISearchBarDelegate,
                                                      ChatTableViewCellDelegate,
                                                      ChatSearchManagerDelegate,
                                                      UISearchControllerDelegate,
                                                      ChatsChangesHandler,
                                                      MessagesChangesHandler,
                                                      ChatListViewProtocol,
                                                      AddToContainerInNavigationWireframeEventsHandler,
                                                      ModalInNavigationWireframeEventsHandler>
{
    @protected
    ChatListStorage * chatStorage;
    NSMutableArray * mainArray;
    NSInteger favUnread;
    NSInteger senderUnread;
    NSInteger companiesUnread;
    NSInteger groupUnread;
    NSInteger operUnread;
}

@property (nonatomic, assign)   id<ChatListViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet UITableView * contactsListTable;
@property (nonatomic, strong, nullable) UIImage * leftBarButtonImage;

@property (nonatomic, nullable) id<ChatListPresenterProtocol> presenter;

- (void)updateCategoryButtons;

- (void)loadContactsFromDB;
- (void)setFavCategoryButtonHidden:(BOOL)hidden;
- (void)reloadCurrentCategory;

- (NSMutableArray *)categoryArrayForChatType:(ChatType)chatType;

@end

