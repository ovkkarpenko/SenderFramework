//
//  SBCoordinator.h
//  SENDER
//
//  Created by Roman Serga on 4/9/15.
//  Copyright (c) 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarModel.h"
#import "SBItemView.h"
#import "SBTextItemView.h"
#import "RecordAudioView.h"
#import "StickerView.h"

typedef NS_ENUM(NSUInteger, SBCoordinatorView) {
    SBCoordinatorViewStickers,
    SBCoordinatorViewAudio
};

@class SBCoordinator;
@class EmptyInputAccessoryView;
@class EmptyInputView;

@protocol MWFirstResponderViewDelegate;
@protocol EmptyInputAccessoryViewDelegate;
@protocol EmojiLauncherViewControllerDelegate;
@protocol MWMessageEditingViewDelegate;

@protocol SBCoordinatorDelegate <NSObject>

@optional

- (void)coordinator:(SBCoordinator *)coordinator didChangeZeroLevelHeight:(CGFloat)newHeight;
- (void)coordinator:(SBCoordinator *)coordinator didChangeInputViewHeight:(CGFloat)newHeight;
- (void)coordinatorDidActivateFirstLevel:(SBCoordinator *)coordinator;
- (void)coordinatorDidExpandTextView:(SBCoordinator *)coordinator;

- (void)coordinatorDidType:(SBCoordinator *)coordinator;
- (void)coordinator:(SBCoordinator *)coordinator didEnterText:(NSString *)text;
- (void)coordinator:(SBCoordinator *)coordinator didSelectStickerWithID:(NSString *)stickerID;
- (void)coordinator:(SBCoordinator *)coordinator didRecordedAudioWithData:(NSData *)audioData;
- (void)coordinator:(SBCoordinator *)coordinator didSelectItemWithActions:(NSArray *)actionsArray;
- (void)coordinatorDidCancelEditingText:(SBCoordinator *)coordinator;

@end

@interface SBCoordinator : UIViewController <SBItemViewDelegate,
                                             SBTextItemViewDelegate,
                                             UITextViewDelegate,
                                             UIScrollViewDelegate,
                                             RecordAudioViewDelegate,
                                             StickerViewDelegate,
                                             EmojiLauncherViewControllerDelegate,
                                             EmptyInputAccessoryViewDelegate,
                                             MWFirstResponderViewDelegate,
                                             MWMessageEditingViewDelegate>

//In dumb mode SBCoordinator doesn't refresh. Just transfers actions to delegate
@property (nonatomic) BOOL dumbMode;
@property (nonatomic) BOOL expandTextButtonSize;
@property (nonatomic, readonly, nullable) NSString * text;

@property (nonatomic, readonly) BOOL isActive;

@property (nonatomic, readonly) CGFloat expectedViewHeight;
@property (nonatomic, readonly) CGFloat expectedFirstLevelHeight;

@property (nonatomic, weak) id<SBCoordinatorDelegate> delegate;

-(instancetype _Nonnull)initWithBarModel:(BarModel *)barModel;
-(instancetype _Nonnull)initWithFrame:(CGRect)frame andBarModel:(BarModel *)barModel;

- (void)updateWithModel:(BarModel *)barModel;

- (void)handleActions:(NSArray *)actions;

- (void)editMessageWithText:(NSString *)text;

- (void)stopEditing;

- (void)setNewMessageText:(NSString *)text;

@end

