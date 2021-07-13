//
//  SBCoordinator.m
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import "SBCoordinator.h"
#import "ParamsFacade.h"
#import "SBItemView.h"
#import "UIView+MWSubviews.h"
#import "PBConsoleConstants.h"
#import <SenderFramework/SenderFramework-Swift.h>

#define firstLevelViewsPerRow (IS_IPAD || IS_IPHONE_6P ? 4 : 3)

@interface SBCoordinator ()
{
    BOOL textInputExpanded;
    BOOL emojiExpanded;

    NSString * newMessageText;
    NSString * editMessageText;

    NSArray * reloadInputAction;
    BOOL isObservingKeyboard;

    BOOL isEditingText;

    BOOL isReloading;
}

@property (nonatomic, strong) BarModel * barModel;
@property (nonatomic, strong) SBTextItemView * textItemView;

@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) RecordAudioView * audioView;
@property (nonatomic, strong) UIView * emojiView;
@property (nonatomic, strong) StickerView * stickerView;

@property (nonatomic, strong) MWFirstResponderView * zeroLevelView;
@property (nonatomic, strong) UIScrollView * firstLevelView;
@property (nonatomic, strong) EmptyInputView * firstLevelBackground;

@property (nonatomic, strong) MWMessageEditingView * messageEditingView;

@property (nonatomic, readwrite) NSString * text;

@property (nonatomic, readwrite) CGFloat expectedViewHeight;
@property (nonatomic, readwrite) CGFloat expectedZeroLevelViewHeight;
@property (nonatomic, readwrite) CGFloat expectedMessageEditingViewHeight;
@property (nonatomic, readwrite) CGFloat expectedFirstLevelHeight;

@property (nonatomic, strong) NSArray * currentZeroLevelItems;
@property (nonatomic, strong) NSArray * currentFirstLevelItems;

@property (nonatomic) NSInteger currentSendBarHash;

@property (nonatomic, readonly) CGFloat defaultHeight;

@property (nonatomic, readonly) BOOL isEnteringText;

@property (nonatomic, strong) EmptyInputAccessoryView * emptyInputAccessoryView;

@property (nonatomic, strong) UIView * topLine;

@property (nonatomic, strong) NSLayoutConstraint * topLineHeightConstraint;

@property (nonatomic, strong) NSLayoutConstraint * messageEditingViewHeightConstraint;

@end

@implementation SBCoordinator

-(instancetype)initWithBarModel:(BarModel *)barModel
{
    CGRect frame = CGRectMake(0.0f, 0.0f, SCREEN_WIDTH, self.defaultHeight);
    return [self initWithFrame:frame andBarModel:barModel];
}

- (__kindof UIView *)inputAccessoryView
{
    return self.emptyInputAccessoryView;
}

- (__kindof UIView *)inputView
{
    return self.firstLevelBackground;
}

- (CGFloat)defaultHeight
{
    return 53.0f;
}

- (void)setBarModel:(BarModel *)barModel
{
    _barModel = barModel;
    self.currentSendBarHash = _barModel.hash;
}

-(instancetype)initWithFrame:(CGRect)frame andBarModel:(BarModel *)barModel
{
    self = [super init];
    if (self)
    {
        self.view.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        self.view.clipsToBounds = YES;
        self.view.translatesAutoresizingMaskIntoConstraints = NO;

        self.barModel = barModel;

        [self startObservingKeyboardChanges];

        CGRect inputAccessoryViewFrame = CGRectMake(0.0f, 0.0f, 0.0f, self.defaultHeight);
        self.emptyInputAccessoryView = [[EmptyInputAccessoryView alloc] initWithFrame:inputAccessoryViewFrame];
        self.emptyInputAccessoryView.delegate = self;

        CGRect inputViewFrame = CGRectMake(0.0f, 0.0f, 0.0f, 1.0f);
        self.firstLevelBackground = [[EmptyInputView alloc] initWithFrame:inputViewFrame];

        self.backButton = [[UIButton alloc]init];
        self.pageControl = [[UIPageControl alloc] init];
        self.firstLevelView = [[UIScrollView alloc] init];

        [self setUpFirstLevelView:self.firstLevelView];
        [self setUpBackButton:self.backButton];
        [self setUpPageControl:self.pageControl];

        [self initSendBar];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.topLine = [[UIView alloc]init];
    [self setUpTopLine:self.topLine];

    self.messageEditingView = [MWMessageEditingView mw_loadFromSenderFrameworkNibNamed:@"MessageEditingView"];
    [self setUpMessageEditingView:self.messageEditingView];

    self.zeroLevelView = [[MWFirstResponderView alloc] init];
    [self setUpZeroLevelView:self.zeroLevelView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect newFirstLevelBackgroundFrame = self.firstLevelBackground.frame;
    newFirstLevelBackgroundFrame.size.width = self.view.frame.size.width;
    self.firstLevelBackground.frame = newFirstLevelBackgroundFrame;
    [self.firstLevelBackground layoutIfNeeded];
}

- (BOOL)isActive
{
    return self.isFirstResponder || [self.view mw_findFirstResponder] != nil;
}

- (void)setUpTopLine:(UIView *)topLine
{
    topLine.backgroundColor = [SenderCore sharedCore].stylePalette.lineColor;
    topLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:topLine];

    NSLayoutAttribute attributes[] = {NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeRight};
    for (int i = 0; i < 3; i++)
    {
        NSLayoutAttribute attribute = attributes[i];
        NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                       attribute:attribute
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:topLine
                                                                       attribute:attribute
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
        [self.view addConstraint:constraint];
    }
    CGFloat heightConstant = 1.0f / [UIScreen mainScreen].scale;
    self.topLineHeightConstraint = [NSLayoutConstraint constraintWithItem:topLine
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0f
                                                                 constant:heightConstant];
    [topLine addConstraint:self.topLineHeightConstraint];
}

- (void)setUpMessageEditingView:(MWMessageEditingView *)messageEditingView
{
    messageEditingView.delegate = self;
    messageEditingView.editTitle.text = SenderFrameworkLocalizedString(@"edit_message_title", nil);
    messageEditingView.translatesAutoresizingMaskIntoConstraints = NO;
    messageEditingView.backgroundColor = [UIColor colorWithRed:243.0f/255.0f
                                                         green:245.0f/255.0f
                                                          blue:246.0f/255.0f
                                                         alpha:1.0f];
    messageEditingView.tintColor = [SenderCore sharedCore].stylePalette.mainAccentColor;
    [self.view addSubview: messageEditingView];

    NSLayoutAttribute attributes[] = {NSLayoutAttributeLeft, NSLayoutAttributeRight};
    for (int i = 0; i < 2; i++)
    {
        NSLayoutAttribute attribute = attributes[i];
        NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                       attribute:attribute
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:messageEditingView
                                                                       attribute:attribute
                                                                      multiplier:1.0f
                                                                        constant:0.0f];
        [self.view addConstraint:constraint];
    }

    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:messageEditingView
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.topLine
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0f
                                                             constant:0.0f];
    [self.view addConstraint:top];

    self.messageEditingViewHeightConstraint = [NSLayoutConstraint constraintWithItem:messageEditingView
                                                                 attribute:NSLayoutAttributeHeight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0f
                                                                  constant:0.0f];
    [messageEditingView addConstraint:self.messageEditingViewHeightConstraint];
}

- (void)setUpZeroLevelView:(MWFirstResponderView *)zeroLevelView
{
    zeroLevelView.translatesAutoresizingMaskIntoConstraints = NO;
    zeroLevelView.backgroundColor = [UIColor whiteColor];
    zeroLevelView.delegate = self;
    [self.view addSubview:zeroLevelView];

    NSLayoutAttribute attributes[] = {NSLayoutAttributeLeft, NSLayoutAttributeRight, NSLayoutAttributeBottom};
    for (int i = 0; i < 3; i++)
    {
        NSLayoutAttribute attribute = attributes[i];
        NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.view
                                                                        attribute:attribute
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:zeroLevelView
                                                                        attribute:attribute
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
        [self.view addConstraint:constraint];
    }

    NSLayoutConstraint * constraint = [NSLayoutConstraint constraintWithItem:self.messageEditingView
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:zeroLevelView
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1.0f
                                                                    constant:0.0f];
    [self.view addConstraint:constraint];
}

- (void)setUpBackButton:(UIButton *)backButton
{
    [backButton setImage:[UIImage imageFromSenderFrameworkNamed:@"_arrow_back"] forState:UIControlStateNormal];
    backButton.hidden = YES;
    [backButton setTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;

    [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButton
                                                           attribute:NSLayoutAttributeHeight
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1.0f
                                                            constant:44.0f]];

    [backButton addConstraint:[NSLayoutConstraint constraintWithItem:backButton
                                                           attribute:NSLayoutAttributeWidth
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:nil
                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                          multiplier:1.0f
                                                            constant:44.0f]];
    [self.firstLevelBackground addSubview:backButton];

    [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:backButton
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.firstLevelBackground
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0f
                                                                           constant:0.0f]];

    [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:backButton
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.firstLevelBackground
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0f
                                                                           constant:0.0f]];
}

- (void)setUpPageControl:(UIPageControl *)pageControl
{
    [pageControl setCurrentPageIndicatorTintColor:[[SenderCore sharedCore].stylePalette mainAccentColor]];
    [pageControl setPageIndicatorTintColor:[UIColor lightGrayColor]];
    pageControl.translatesAutoresizingMaskIntoConstraints = NO;

    [pageControl addConstraint:[NSLayoutConstraint constraintWithItem:pageControl
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1.0f
                                                             constant:37.0f]];
    [self.firstLevelBackground addSubview:self.pageControl];

    [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:pageControl
                                                                          attribute:NSLayoutAttributeCenterX
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.firstLevelBackground
                                                                          attribute:NSLayoutAttributeCenterX
                                                                         multiplier:1.0f
                                                                           constant:0.0f]];

    [self.firstLevelBackground addConstraint:[NSLayoutConstraint constraintWithItem:pageControl
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.firstLevelBackground
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0f
                                                                           constant:-8.0f]];
}

- (void)setUpFirstLevelView:(UIScrollView *)firstLevelView
{
    firstLevelView.delegate = self;
    firstLevelView.scrollsToTop = NO;
    firstLevelView.backgroundColor = [UIColor whiteColor];
    firstLevelView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.firstLevelBackground addSubview:firstLevelView];
    [self.firstLevelBackground mw_pinSubview:firstLevelView];
}

- (void)updateWithModel:(BarModel *)barModel
{
    BOOL shouldUpdateSendBar = barModel.hash != self.currentSendBarHash;
    self.barModel = barModel;
    if (shouldUpdateSendBar) [self initSendBar];
}

- (UIView *)emojiView
{
    EmojiLauncherViewController * emojiLauncher = [EmojiLauncherViewController controller];
    emojiLauncher.delegate = self;
    _emojiView = emojiLauncher.view;
    _emojiView.frame = CGRectMake(0.0f, 0.0f, 414.0f, 216.0f);
    [self addChildViewController:emojiLauncher];
    return _emojiView;
}

- (RecordAudioView *)audioView
{
    if (!_audioView)
    {
        _audioView = [[RecordAudioView alloc] init];
        _audioView.backgroundColor = [UIColor whiteColor];
        [_audioView setUpView];
        _audioView.delegate = self;
    }
    return _audioView;
}

- (StickerView *)stickerView
{
    if (!_stickerView)
    {
        _stickerView = [[StickerView alloc] init];
        _stickerView.backgroundColor = [UIColor whiteColor];
        _stickerView.delegate = self;
    }
    return _stickerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startObservingKeyboardChanges];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopObservingKeyboard];
}

- (void)setDumbMode:(BOOL)dumbMode
{
    if (dumbMode != _dumbMode)
    {
        if (dumbMode)
            [self stopObservingKeyboard];
        else
            [self startObservingKeyboardChanges];
        _dumbMode = dumbMode;
    }
}

- (BOOL)isEnteringText
{
    return [self.textItemView.inputField isFirstResponder];
}

- (void)startObservingKeyboardChanges
{
    if (!isObservingKeyboard)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];

        isObservingKeyboard = YES;
    }
}

-(void)stopObservingKeyboard
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    isObservingKeyboard = NO;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)initSendBar
{
    if (isEditingText) [self stopEditing];
    if (self.barModel.initializeData)
    {
        NSDictionary * initData = [[ParamsFacade sharedInstance]dictionaryFromNSData:self.barModel.initializeData];
        [self setFirstLevelItems:initData[@"_1"]];
        [self setZeroLevelItems:initData[@"_0"] expandTextInput:NO expandEmoji:NO];
    }
}

- (BOOL)setZeroLevelItems:(NSArray *)items expandTextInput:(BOOL)expandTextInput expandEmoji:(BOOL)expandEmoji
{
    CGFloat currentX = 0.0f;
    CGFloat itemViewHeight = self.defaultHeight - self.topLineHeightConstraint.constant;

    NSMutableArray * itemsTemp = [NSMutableArray array];

    textInputExpanded = expandTextInput;
    emojiExpanded = expandEmoji;

    if (emojiExpanded) textInputExpanded = YES;

    BOOL hasTextItem = NO;

    for (NSNumber * itemID in items)
    {
        for (BarItem * itemModel in self.barModel.barItems)
        {
            if ([itemModel hasTextAction])
            {
                reloadInputAction = itemModel.actionsParsed;
                hasTextItem = YES;
                if ([itemModel hasExpandedTextAction])
                    textInputExpanded = YES;
            }
            if ([@([itemModel.itemID integerValue]) isEqualToNumber:itemID])
            {
                if ([self isValidBarItem:itemModel])
                    [itemsTemp addObject:itemModel];
                break;
            }
        }
    }

    BOOL shouldActivateTextItem = hasTextItem && textInputExpanded;
    if ([items isEqualToArray:self.currentZeroLevelItems])
        return shouldActivateTextItem;

    self.currentZeroLevelItems = items;

    self.textItemView = nil;

    [self.zeroLevelView mw_removeAllSubviews];

    NSArray * itemModels = [itemsTemp copy];
    NSInteger itemsCount = [itemModels count];

    CGFloat itemViewWidth = (hasTextItem && textInputExpanded) ? 44.0f : self.view.frame.size.width / itemsCount;
    CGFloat currentWidth;
    CGFloat zeroLevelHeight = self.defaultHeight;

    for (BarItem * itemModel in itemModels)
    {
        SBItemView * itemView;
        if ([itemModel hasTextAction])
        {
            currentWidth = textInputExpanded ? self.zeroLevelView.frame.size.width - (itemsCount - 1) * itemViewWidth : itemViewWidth;
            itemView = [[SBTextItemView alloc]initWithFrame:CGRectMake(currentX, 0.0f, currentWidth, itemViewHeight)
                                               andItemModel:itemModel
                                               shouldExpand:textInputExpanded
                                                  bigButton:self.expandTextButtonSize];
            self.textItemView = (SBTextItemView *)itemView;
            if (emojiExpanded)
                self.textItemView.inputField.inputView = self.emojiView;
        }
        else
        {
            currentWidth = itemViewWidth;
            itemView = [[SBItemView alloc]initWithFrame:CGRectMake(currentX, 0.0f, itemViewWidth, itemViewHeight)
                                           andItemModel:itemModel];
        }

        itemView.translatesAutoresizingMaskIntoConstraints = NO;
        itemView.translatesAutoresizingMaskIntoConstraints = NO;

        [self.zeroLevelView addSubview:itemView];

        [self.zeroLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                       attribute:NSLayoutAttributeLeft
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.zeroLevelView
                                                                       attribute:NSLayoutAttributeLeft
                                                                      multiplier:1.0f
                                                                        constant:currentX]];

        [itemView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1.0f
                                                              constant:currentWidth]];

        [self.zeroLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.zeroLevelView
                                                                       attribute:NSLayoutAttributeBottom
                                                                      multiplier:1.0f
                                                                        constant:0.0f]];

        if ([itemView isKindOfClass:[SBTextItemView class]])
        {
            [self.zeroLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.zeroLevelView
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0f
                                                                            constant:0.0f]];
        }
        else
        {
            [self.zeroLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0f
                                                                            constant:itemViewHeight]];
        }

        itemView.hidesTitle = YES;
        itemView.delegate = self;
        if (self.barModel.mainTextColor)
            itemView.titleTextColor = [[SenderCore sharedCore].stylePalette colorWithHexString:self.barModel.mainTextColor];

        currentX += currentWidth;
    }

    [self setZeroLevelHeight:zeroLevelHeight];
    if (textInputExpanded) [self.textItemView setText:newMessageText];
    return shouldActivateTextItem;
}

- (BOOL)setFirstLevelItems:(NSArray *)items
{
    BOOL shouldActivateZeroLevelView = items.count > 0;

    if ([items isEqualToArray:self.currentFirstLevelItems])
        return shouldActivateZeroLevelView;

    self.currentFirstLevelItems = items;

    self.backButton.hidden = YES;

    CGFloat itemViewHeight = 108.0f;

    NSUInteger rowsCount = [items count] == 0 ? 0 : ([items count] > firstLevelViewsPerRow ? 2 : 1);

    NSInteger itemNumber;
    NSInteger itemsPerRow = 0;
    CGFloat currentX = 0.0f;
    CGFloat itemViewWidth = 0.0f;
    CGFloat contentWidth = 0.0f;

    NSMutableArray *itemsTemp = [NSMutableArray array];

    for (NSNumber *itemID in items)
    {
        for (BarItem *itemModel in self.barModel.barItems)
        {
            if ([@([itemModel.itemID integerValue]) isEqualToNumber:itemID])
            {
                if ([self isValidBarItem:itemModel])
                    [itemsTemp addObject:itemModel];
                break;
            }
        }
    }

    [self.firstLevelView mw_removeAllSubviews];

    NSArray *itemModels = [itemsTemp copy];
    NSInteger itemsCount = [itemModels count];

    for (BarItem *itemModel in itemModels)
    {
        itemNumber = [itemModels indexOfObject:itemModel];

        if (itemNumber % firstLevelViewsPerRow == 0)
        {
            itemsPerRow = (itemsCount - itemNumber >= firstLevelViewsPerRow) ? firstLevelViewsPerRow : itemsCount - itemNumber;
            itemViewWidth = self.view.frame.size.width / itemsPerRow;
        }

        currentX = itemViewWidth * (itemNumber % firstLevelViewsPerRow) + (self.firstLevelView.frame.size.width * (NSInteger) (itemNumber / (rowsCount * firstLevelViewsPerRow)));


        SBItemView *itemView = [[SBItemView alloc] initWithFrame:CGRectMake(currentX, (itemNumber / firstLevelViewsPerRow) % 2 * itemViewHeight, itemViewWidth, itemViewHeight) andItemModel:itemModel];

        itemView.translatesAutoresizingMaskIntoConstraints = NO;
        itemView.delegate = self;

        if (self.barModel.mainTextColor)
            itemView.titleTextColor = [[SenderCore sharedCore].stylePalette colorWithHexString:self.barModel.mainTextColor];

        [self.firstLevelView addSubview:itemView];


        [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                        attribute:NSLayoutAttributeLeft
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.firstLevelView
                                                                        attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0f
                                                                         constant:currentX]];

        [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.firstLevelView
                                                                        attribute:NSLayoutAttributeTop
                                                                       multiplier:1.0f
                                                                         constant:(itemNumber / firstLevelViewsPerRow) % 2 * itemViewHeight]];

        [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0f
                                                                         constant:itemViewWidth]];

        [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:itemView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0f constant:itemViewHeight]];

        contentWidth = CGRectGetMaxX(itemView.frame) > contentWidth ? CGRectGetMaxX(itemView.frame) : contentWidth;
    }

    [self setFirstLevelContentSize:CGSizeMake(contentWidth, itemViewHeight * rowsCount)];
    [self.firstLevelBackground setHeight:itemViewHeight * rowsCount];

    return shouldActivateZeroLevelView;
}

- (void)handleActions:(NSArray *)actions
{
    [self handleActions:actions expandEmoji:NO];
}


- (void)handleActions:(NSArray *)actions expandEmoji:(BOOL)expandEmoji
{
    if (!self.dumbMode)
    {
        NSPredicate * reloadPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary * action, NSDictionary * b) {
            return [action[@"oper"] isEqualToString:@"reload"];
        }];
        NSArray * reloadActions = [actions filteredArrayUsingPredicate:reloadPredicate];
        NSMutableArray * sortedActions = [NSMutableArray arrayWithArray:actions];
        [sortedActions removeObjectsInArray:reloadActions];
        [sortedActions addObjectsFromArray:reloadActions];

        BOOL expandTextInput = NO;
        BOOL expandEmojiOnZeroLevelReload = expandEmoji;

        for (NSDictionary * action in sortedActions)
        {
            NSString * operation = action[@"oper"];
            if ([operation isEqualToString:@"sendMsg"])
            {
                expandTextInput = YES;
            }
            else if ([operation isEqualToString:@"reload"])
            {
                isReloading = YES;
                BOOL shouldActivateZeroLevelView = [self setFirstLevelItems:action[@"_1"]];
                if (shouldActivateZeroLevelView)
                {
                    if (![self.zeroLevelView isFirstResponder])
                        [self.zeroLevelView becomeFirstResponder];
                    if ([self.delegate respondsToSelector:@selector(coordinatorDidActivateFirstLevel:)])
                        [self.delegate coordinatorDidActivateFirstLevel:self];
                    [self setMessageEditingViewHeight:0.0f];
                }

                BOOL shouldActivateTextItem = NO;
                if (action[@"_0"])
                    shouldActivateTextItem = [self setZeroLevelItems:action[@"_0"]
                                                     expandTextInput:expandTextInput
                                                         expandEmoji:expandEmojiOnZeroLevelReload];
                if (shouldActivateTextItem)
                {
                    if (![self isEnteringText])
                        [self.textItemView.inputField becomeFirstResponder];
                    if (isEditingText)
                        [self editMessageWithText:editMessageText];
                }
                else if (!shouldActivateZeroLevelView)
                {
                    if ([self isEnteringText])
                        [self.textItemView.inputField resignFirstResponder];
                    else if ([self.zeroLevelView isFirstResponder])
                        [self.zeroLevelView resignFirstResponder];
                }
            }
            else if ([operation isEqualToString:@"sendMedia"])
            {
                BOOL shouldActivateZeroLevelView = NO;
                BOOL shouldActivateTextItem = NO;

                NSString *mediaType = action[@"type"];
                if ([mediaType isEqualToString:@"sticker"])
                    shouldActivateZeroLevelView = [self showActionsView:SBCoordinatorViewStickers];
                else if ([mediaType isEqualToString:@"smile"])
                {
                    expandEmojiOnZeroLevelReload = YES;
                    shouldActivateTextItem = [self startEmojiInput];
                }
                else if ([mediaType isEqualToString:@"voice"])
                    shouldActivateZeroLevelView = [self showActionsView:SBCoordinatorViewAudio];

                if (shouldActivateTextItem)
                {
                    if (![self isEnteringText])
                        [self.textItemView.inputField becomeFirstResponder];
                }
                else if (shouldActivateZeroLevelView)
                {
                    if (![self.zeroLevelView isFirstResponder]) [self.zeroLevelView becomeFirstResponder];
                    if ([self.delegate respondsToSelector:@selector(coordinatorDidActivateFirstLevel:)])
                        [self.delegate coordinatorDidActivateFirstLevel:self];
                }
            }
        }
    }
    isReloading = NO;

    if (actions && [self.delegate respondsToSelector:@selector(coordinator:didSelectItemWithActions:)])
        [self.delegate coordinator:self didSelectItemWithActions:actions];
}

- (void)setZeroLevelHeight:(CGFloat)height
{
    self.expectedZeroLevelViewHeight = height;
    [self setViewHeight:self.expectedZeroLevelViewHeight + self.expectedMessageEditingViewHeight];
}

- (void)setMessageEditingViewHeight:(CGFloat)height
{
    self.messageEditingViewHeightConstraint.constant = height;
    self.expectedMessageEditingViewHeight = height;
    [self setViewHeight:self.expectedZeroLevelViewHeight + self.expectedMessageEditingViewHeight];
}

- (void)setViewHeight:(CGFloat)height
{
    self.expectedViewHeight = height;
    [self.emptyInputAccessoryView setHeight:self.expectedViewHeight];
    if ([self.delegate respondsToSelector:@selector(coordinator:didChangeZeroLevelHeight:)])
        [self.delegate coordinator:self didChangeZeroLevelHeight:height];
}

- (void)setFirstLevelHeight:(CGFloat)height
{
    self.expectedFirstLevelHeight = height;
    if ([self.delegate respondsToSelector:@selector(coordinator:didChangeInputViewHeight:)])
        [self.delegate coordinator:self didChangeInputViewHeight:height];
}

- (void)setFirstLevelContentSize:(CGSize)contentSize
{
    self.firstLevelView.contentSize = contentSize;
    self.pageControl.numberOfPages = contentSize.width / self.view.frame.size.width;
    self.firstLevelView.scrollEnabled = self.pageControl.numberOfPages > 1;
    self.firstLevelView.pagingEnabled = self.pageControl.numberOfPages > 1;
    self.pageControl.hidden = self.pageControl.numberOfPages < 2;
}

- (BOOL)textItemViewShouldBeginEditing:(SBTextItemView *)textItem
{
    textItem.inputField.inputView = emojiExpanded ? self.emojiView : nil;
    return YES;
}

-(void)textItemViewDidBeginEditing:(SBTextItemView *)textItem
{
    if ([self.delegate respondsToSelector:@selector (coordinatorDidExpandTextView:)])
        [self.delegate coordinatorDidExpandTextView:self];
}

- (void)textItemViewDidEndEditing:(SBTextItemView *)textItem
{
    if (!isEditingText)
        newMessageText = textItem.inputField.text;

    if (!isReloading && [self.zeroLevelView isFirstResponder])
        [self.zeroLevelView resignFirstResponder];
}

- (void)textItemViewDidType:(SBTextItemView *)textItem
{
    if ([self.delegate respondsToSelector:@selector(coordinatorDidType:)])
        [self.delegate coordinatorDidType:self];
}

#pragma mark - Keyboard Handling Methods

- (void)keyboardWillHide:(NSNotification *)notification
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_main_queue(), ^{
        if (!(textInputExpanded && [self.text length]))
            [self initSendBar];
    });
}

- (BOOL)startEmojiInput
{
    emojiExpanded = YES;
    if (!textInputExpanded)
    {
        [self handleActions:reloadInputAction expandEmoji:YES];
        return NO;
    }
    else
    {
        self.textItemView.inputField.inputView = self.emojiView;
        [self.textItemView.inputField reloadInputViews];
        return YES;
    }
}

#pragma mark - Adding Actions View

- (BOOL)showActionsView:(SBCoordinatorView)viewType
{
    [self.firstLevelView mw_removeAllSubviews];

    BOOL shouldActivateZeroLevelView = NO;
    switch (viewType) {
        case SBCoordinatorViewAudio:
        {
            if (self.audioView.isSetUp) [self.audioView setUpView];
            shouldActivateZeroLevelView = [self addNativeViewToFirstLevel:self.audioView];
        }
            break;
        case SBCoordinatorViewStickers:
        {
            shouldActivateZeroLevelView = [self addNativeViewToFirstLevel:self.stickerView];
            [self goToStickerChoose];
        }
            break;

        default:
            break;
    }
    return shouldActivateZeroLevelView;
}

- (BOOL)addNativeViewToFirstLevel:(UIView *)view
{
    if (view)
    {
        if (view == self.audioView)
        {
            [self.textItemView.inputField resignFirstResponder];
        }

        [self.firstLevelView addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;

        [self fixViewConstraints:view];
    }
    [self.firstLevelBackground setHeight:view.frame.size.height];
    [self setFirstLevelContentSize:view.frame.size];
    return YES;
}

- (void)fixViewConstraints:(UIView *)view
{
    [self.firstLevelView removeConstraints:self.firstLevelView.constraints];

    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeLeft
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.firstLevelView
                                                                    attribute:NSLayoutAttributeLeft
                                                                   multiplier:1.0f
                                                                     constant:0.0f]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.firstLevelView
                                                                    attribute:NSLayoutAttributeTop
                                                                   multiplier:1.0f
                                                                     constant:0.0f]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0f
                                                                     constant:view.frame.size.width]];
    [self.firstLevelView addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute:NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1.0f
                                                                     constant:view.frame.size.height]];
}

#pragma mark - SBItemView Delegate Methods

- (void)itemView:(SBItemView *)itemView didChooseActionsWithData:(NSArray *)actionsData
{
    [self handleActions:actionsData expandEmoji:NO];
}

#pragma mark - SBTextItemView Delegate Methods

- (void)textItemView:(SBTextItemView *)textItem didChangeHeight:(CGFloat)height
{
    [self setZeroLevelHeight:height];
}

- (void)textItemView:(SBTextItemView *)textItem didPressSendWithText:(NSString *)text
{
    if ([self.delegate respondsToSelector:@selector(coordinator:didEnterText:)])
        [self.delegate coordinator:self didEnterText:text];

    if (!isEditingText) newMessageText = nil;

    [self setMessageEditingViewHeight:0.0f];
    [self stopEditing];

    if (![self isEnteringText])
        [self initSendBar];
}


#pragma mark - EmptyInputAccessoryView Delegate Methods

- (void)emptyInputAccessoryView:(EmptyInputAccessoryView *)emptyInputAccessoryView didChangeFrame:(CGRect)newFrame
{
    CGFloat newHeight = CGRectGetMaxY([self.view superview].frame) - CGRectGetMaxY(newFrame) - newFrame.size.height;
    newHeight = newHeight >= 0.0f ? newHeight : 0.0f;
    [self setFirstLevelHeight:newHeight];
}

- (void)emptyInputAccessoryViewDidBecomeInactive:(EmptyInputAccessoryView *)emptyInputAccessoryView
{
    CGFloat newHeight = 0.0f;
    [self setFirstLevelHeight:newHeight];
}

#pragma mark - MessageEditingView Delegate Methods

- (void)messageEditingViewDidCancelEditing:(MWMessageEditingView *)messageEditingView
{
    [self stopEditing];
}

#pragma StickerView Delegate

- (void)stickerViewDidSelectedSticker:(NSString *)stickerID
{
    if ([self.delegate respondsToSelector:@selector(coordinator:didSelectStickerWithID:)])
        [self.delegate coordinator:self didSelectStickerWithID:stickerID];
}

- (void)goToStickerChoose
{
    [self fixViewConstraints:self.stickerView];
    [self.stickerView goBack];
    self.backButton.hidden = YES;
    [self.backButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self setFirstLevelContentSize:self.stickerView.frame.size];
}

-(void)stickerViewDidOpenedStickerPack
{
    [self fixViewConstraints:self.stickerView];
    [self setFirstLevelContentSize:self.stickerView.frame.size];
    self.backButton.hidden = NO;
    [self.backButton addTarget:self action:@selector(goToStickerChoose) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.firstLevelView.frame.size.width;
    int page = (int)floor((self.firstLevelView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

#pragma mark - RecordAudioView Delegate

- (void)recordAudioViewDidRecordedTrack:(NSData *)data
{
    if ([self.delegate respondsToSelector:@selector(coordinator:didRecordedAudioWithData:)])
        [self.delegate coordinator:self didRecordedAudioWithData:data];
}

#pragma mark - MWFirstResponderView Delegate

- (void)firstResponderViewDidBecomeFirstResponder:(MWFirstResponderView *)firstResponderView
{
}

- (void)firstResponderViewDidResignFirstResponder:(MWFirstResponderView *)firstResponderView
{

}

#pragma mark - EmojiLauncher Delegate

-(void)emojiLauncherDidSelectedEmoji:(NSString *)emoji
{
    [self.textItemView.inputField insertText:emoji];
}

-(void)emojiLauncherDidSelectedBackspace
{
    [self.textItemView.inputField deleteBackward];
}

- (id)findViewsSubviewWithTextInput:(UIView*)item
{
    if ([item conformsToProtocol:@protocol(UITextInput)]) return item;

    for (UIView * v in [item subviews]) {
        id res = [self findViewsSubviewWithTextInput:v];
        if (res) return res;
    }
    return nil;
}

- (NSRange)makeSimpleRangeFromTextRange:(UITextRange*)textRange forTextInput:(id<UITextInput>)input
{
    NSUInteger length = (NSUInteger)[input offsetFromPosition:textRange.start toPosition:textRange.end];
    NSUInteger location = (NSUInteger)[input offsetFromPosition:input.beginningOfDocument toPosition:textRange.start];
    return NSMakeRange(location, length);
}

- (void)editMessageWithText:(NSString *)text
{
    isEditingText = YES;
    [self setEditText:text];
    if (!textInputExpanded) [self handleActions:reloadInputAction expandEmoji:NO];
    [self.textItemView.inputField becomeFirstResponder];
    self.messageEditingView.messageText.text = text;
    [self setMessageEditingViewHeight:44.0f];
}

- (void)stopEditing
{
    isEditingText = NO;
    [self setEditText:@""];
    [self setMessageEditingViewHeight:0.0f];
    if ([self.delegate respondsToSelector:@selector(coordinatorDidCancelEditingText:)])
        [self.delegate coordinatorDidCancelEditingText:self];

    if (![self isEnteringText])
        [self initSendBar];
}

- (void)setNewMessageText:(NSString *)text
{
    newMessageText = text;
    self.textItemView.text = text;
    
    [self textItemView:self.textItemView didPressSendWithText:text];
}

- (void)setEditText:(NSString *)text
{
    editMessageText = text;
    self.textItemView.text = text;
}

- (NSString *)text
{
    if (isEditingText)
        return newMessageText;
    else
        return self.isEnteringText ? self.textItemView.text : newMessageText;
}

- (BOOL)isValidBarItem:(BarItem *)barItem
{
    return ![barItem hasFileAction] && ![barItem hasCryptoAction];
}

@end
