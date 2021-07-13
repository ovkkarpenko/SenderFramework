//
// Created by Roman Serga on 28/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(MessageViewAction)
@interface MWMessageViewAction: NSObject

@property (class, nonatomic, strong, readonly, nonnull) MWMessageViewAction * edit;
@property (class, nonatomic, strong, readonly, nonnull) MWMessageViewAction * delete;

@property (nonatomic, strong, readonly, nonnull) NSString * name;
@property (nonatomic, strong, nullable) NSDictionary * userInfo;

- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name NS_DESIGNATED_INITIALIZER;

@end

NS_SWIFT_NAME(MessageViewUpdate)
@interface MWMessageViewUpdate: NSObject

@property (nonatomic, strong, readonly, nonnull) NSString * name;
@property (nonatomic, strong, nullable) NSDictionary * userInfo;

- (instancetype _Nonnull)initWithName:(NSString * _Nonnull)name NS_DESIGNATED_INITIALIZER;

@end

@class MWMessageView;
NS_SWIFT_NAME(MessageViewActionHandler)
@protocol MWMessageViewActionHandler

- (void)messageView:(MWMessageView *_Nonnull)messageView
    didSelectAction:(MWMessageViewAction * _Nonnull)action NS_SWIFT_NAME(messageView(_:didSelectAction:));
- (BOOL)messageView:(MWMessageView *_Nonnull)messageView
   canPerformAction:(MWMessageViewAction * _Nonnull)action NS_SWIFT_NAME(messageView(_:canPerformAction:));

@end

NS_SWIFT_NAME(MessageView)
@interface MWMessageView : UIView

@property (nonatomic, weak) id <MWMessageViewActionHandler> _Nullable actionsHandler;

- (void)setUpView;
- (void)handleUpdate:(MWMessageViewUpdate *)messageViewUpdate NS_SWIFT_NAME(handleUpdate(_:));;

@end
