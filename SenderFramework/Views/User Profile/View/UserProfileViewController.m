//
//  UserProfileViewController.m
//  SENDER
//
//  Created by Eugene Gilko on 11/2/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "UserProfileViewController.h"
#import "MainButtonCell.h"
#import "SenderNotifications.h"
#import "PBConsoleConstants.h"
#import "ParamsFacade.h"
#import "ServerFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import "Owner.h"

@interface UserProfileViewController ()
{
    IBOutlet UIImageView * userImage;
    IBOutlet UILabel * userName;
    IBOutlet UILabel * userDesc;

    BOOL isSetUp;
    NSArray * mainActions;
    
    MainActionModel * refillModel;
    MainActionModel * transferModel;
    MainActionModel * walletModel;
    MainActionModel * shopModel;
    MainActionModel * qrModel;
    MainActionModel * createBusinessModel;
    
    __weak IBOutlet UICollectionView * mainCollectionView;

    IBOutlet UIButton * settingsButton;
    IBOutlet UIButton * dialogsButton;
}

@property (nonatomic, strong, nullable) UIImage * rightBarButtonImage;

@end

@implementation UserProfileViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor;
    [self.presenter viewWasLoaded];
    [self setControlButtons];

    mainCollectionView.scrollsToTop = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (!isSetUp)
    {
        [self setMainActions];

        if (userImage.image)
        {
            [PBConsoleConstants imageSetRounds:userImage];
            userImage.layer.borderWidth = 4;
            userImage.layer.borderColor = [SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor.CGColor;
        }
    }

    if ([[[UIDevice currentDevice]systemVersion]floatValue] < 8.0)
        [self.view layoutIfNeeded];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)setControlButtons
{
    [userName setTextColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
    [userDesc setTextColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
    self.view.backgroundColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    dialogsButton.tintColor = [UIColor whiteColor];
    [dialogsButton setImage:self.rightBarButtonImage forState:UIControlStateNormal];
    [dialogsButton setHidden:self.rightBarButtonImage == nil];
}

- (void)updateInfoWithOwner:(Owner *)owner
{
    UIImage * placeHolder = [MWDefaultImageGenerator generateDefaultImageWithEmoji:owner.defaultImageEmoji
                                                                              size:userImage.frame.size
                                                                           rounded:NO
                                                               backgroundImageName:@"icAccount"];
    [userImage sd_cancelCurrentImageLoad];
    [userImage sd_setImageWithURL:owner.imageURL placeholderImage:placeHolder];
    userName.text = owner.name;
    userDesc.text = [owner.desc isEqualToString:@"User description"] ?  @"I Love SENDER!" : owner.desc;
}

#pragma mark - Actions

- (IBAction)goToDialogs:(id)sender
{
    [self.presenter performMainAction];
}

- (IBAction)goToSettings:(id)sender
{
    [self.presenter showSettings];
}

- (void)showQRImage
{
    [self.presenter showQRScreen];
}

#pragma mark - UICollectionView Delegate Methods

-(void)setMainActions
{
    __weak UserProfileViewController * wSelf = self;

    refillModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"refill_menu_ios", nil)
                                                 image:[UIImage imageFromSenderFrameworkNamed:@"_refil"]
                                            tapHandler:^{ [wSelf.presenter topUpMobile]; }];

    transferModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"transfer_menu_ios", nil)
                                                   image:[UIImage imageFromSenderFrameworkNamed:@"_send"]
                                              tapHandler:^{ [wSelf.presenter transferMoney]; }];

    walletModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"wallet_menu_ios", nil)
                                                 image:[UIImage imageFromSenderFrameworkNamed:@"_wallet"]
                                            tapHandler:^{ [wSelf.presenter showWallet]; }];

    shopModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"shop", nil)
                                               image:[UIImage imageFromSenderFrameworkNamed:@"_shop"]
                                          tapHandler:^{ [wSelf.presenter showStore]; }];

    qrModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"qr_menu_ios", nil)
                                             image:[UIImage imageFromSenderFrameworkNamed:@"_QR"]
                                        tapHandler:^{ [wSelf showQRImage]; }];

    createBusinessModel = [[MainActionModel alloc]initWithName:SenderFrameworkLocalizedString(@"add_robot", nil)
                                                         image:[UIImage imageFromSenderFrameworkNamed:@"_bot"]
                                                    tapHandler:^{ [wSelf.presenter createRobot]; }];

    NSDictionary * firstRow = @{@"header" : @"", @"actionModels" : @[refillModel, transferModel, walletModel]};
    NSDictionary * secondRow = @{@"header" : @"", @"actionModels" : @[shopModel, qrModel, createBusinessModel]};

    mainActions = @[firstRow,secondRow];

    [mainCollectionView reloadData];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [mainActions count];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray * actionsArray = [mainActions[section]objectForKey:@"actionModels"];
    return [actionsArray count];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MainActionModel * action = [self modelForIndexPath:indexPath];
    if (action.tapHandler)
        action.tapHandler();
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MainButtonCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MainButtonCell" forIndexPath:indexPath];
    [cell customizeWithModel:[self modelForIndexPath:indexPath]];
    [cell.mainImage setTintColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
    [cell setTintColor:[[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor colorWithAlphaComponent:0.2]];
    [cell.title setTextColor:[SenderCore sharedCore].stylePalette.controllerCommonBackgroundColor];
    return cell;
}

-(MainActionModel *)modelForIndexPath:(NSIndexPath *)indexPath
{
    MainActionModel * resultModel;
    NSArray * actionsArray = [mainActions[indexPath.section]objectForKey:@"actionModels"];
    if ([actionsArray[indexPath.row] isKindOfClass:[MainActionModel class]])
        resultModel = (MainActionModel *)actionsArray[indexPath.row];
    return resultModel;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sizeForItem];
}

-(CGSize)sizeForItem
{
    DeviceType device;
    if (IS_IPHONE_4_OR_LESS)
        device = DeviceTypeIphone4;
    else if (IS_IPHONE_5)
        device = DeviceTypeIphone5;
    else if (IS_IPHONE_6)
        device = DeviceTypeIphone6;
    else if (IS_IPHONE_6P)
        return CGSizeMake(120.0f, 130.0f);
    
    return [MainButtonCell templateSizeForDeviceType:device];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section
{
    UIEdgeInsets result;
    
    NSUInteger viewsPerRow = [mainCollectionView numberOfItemsInSection:section];
    CGFloat offsetX = (mainCollectionView.frame.size.width - viewsPerRow * [self sizeForItem].width) / (viewsPerRow + 1);
    
    NSUInteger rowsPerPage = (long)mainCollectionView.frame.size.height / (long)[self sizeForItem].height;
    if (rowsPerPage > [mainActions count])
        rowsPerPage = [mainActions count];
    
    CGFloat offsetY = (mainCollectionView.frame.size.height - rowsPerPage * [self sizeForItem].height) / (rowsPerPage + 1);
    
    result = UIEdgeInsetsMake(offsetY, offsetX, 0.0f, offsetX);
    
    return result;
}

- (void)updateWithUser:(Owner *)user
{
    [self updateInfoWithOwner:user];
}

#pragma mark - AddToContainerInNavigationWireframe Events Handler

- (void)prepareForPresentationWithAddToContainerWireframe:(id)addToContainerWireframe
{
    UIImage * chatsImage = [UIImage imageFromSenderFrameworkNamed:@"showdialogs"];
    self.rightBarButtonImage = [chatsImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithAddToContainerWireframe:(id)addToContainerWireframe
{

}

#pragma mark - ModalInNavigationWireframe Events Handler

- (void)prepareForPresentationWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{
    UIImage *closeImage = [UIImage imageFromSenderFrameworkNamed:@"close"];
    self.rightBarButtonImage = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)prepareForDismissalWithModalInNavigationWireframe:(ModalInNavigationWireframe *)modalInNavigationWireframe
{

}


@end
