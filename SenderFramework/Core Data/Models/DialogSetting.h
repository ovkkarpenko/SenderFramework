//
//  DialogSetting.h
//  SENDER
//
//  Created by Eugene Gilko on 4/18/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Dialog;

typedef NS_ENUM(NSInteger, ChatSettingsNotificationType) {
    ChatSettingsNotificationTypeDisabled = 0,
    ChatSettingsNotificationTypeEnabledLocally,
    ChatSettingsNotificationTypeEnabled
};

typedef NS_ENUM(NSInteger, ChatSettingsSoundScheme) {
    ChatSettingsSoundSchemeDefault = 0,
    ChatSettingsSoundSchemePersonal,
    ChatSettingsSoundSchemeBusiness,
    ChatSettingsSoundSchemeAlert
};

ChatSettingsNotificationType chatSettingsNotificationTypeFromString(NSString * string);
NSString * stringFromChatSettingsNotificationType(ChatSettingsNotificationType notificationType);

ChatSettingsSoundScheme chatSettingsSoundSchemeFromString(NSString * string);
NSString * stringFromChatSettingsSoundScheme(ChatSettingsSoundScheme soundScheme);

@interface DialogSetting : NSManagedObject

@property (nonatomic, retain) Dialog * dialog;

@property (nonatomic, retain) NSNumber *blockChat;
@property (nonatomic, retain) NSNumber *favChat;

@property (nonatomic) ChatSettingsSoundScheme chatSoundScheme;

@property (nonatomic) ChatSettingsNotificationType muteChatNotification;
@property (nonatomic) ChatSettingsNotificationType hidePushNotification;
@property (nonatomic) ChatSettingsNotificationType smartPushNotification;
@property (nonatomic) ChatSettingsNotificationType hideTextNotification;
@property (nonatomic) ChatSettingsNotificationType hideCounterNotification;

//Raw value of muteChatNotification. Use muteChatNotification instead of ntfMuteChat
@property (nonatomic, retain, readonly) NSString *ntfMuteChat;
//Raw value of hidePushNotification. Use hidePushNotification instead of ntfHidePush
@property (nonatomic, retain, readonly) NSString *ntfHidePush;
//Raw value of smartPushNotification. Use smartPushNotification instead of ntfSmartPush
@property (nonatomic, retain, readonly) NSString *ntfSmartPush;
//Raw value of hideTextNotification. Use hideTextNotification instead of ntfTextHidden
@property (nonatomic, retain, readonly) NSString *ntfTextHidden;
//Raw value of hideCounterNotification. Use hideCounterNotification instead of ntfCounter
@property (nonatomic, retain, readonly) NSString *ntfCounter;
//Raw value of chatSoundScheme. Use chatSoundScheme instead of soundScheme
@property (nonatomic, retain, readonly) NSString *soundScheme;

- (void)initDefaultValue;
- (void)dialogSetting:(NSDictionary *)jsonData;
- (NSDictionary *)paramsForSend;

- (BOOL)takenIntoAccountWhenCalculatingBadge;

@end
