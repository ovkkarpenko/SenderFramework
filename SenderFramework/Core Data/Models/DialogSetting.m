//
//  DialogSetting.m
//  SENDER
//
//  Created by Eugene Gilko on 4/18/16.
//  Copyright © 2016 Middleware Inc. All rights reserved.
//

#import "DialogSetting.h"
#import "Dialog.h"

ChatSettingsNotificationType chatSettingsNotificationTypeFromString(NSString * string)
{
    ChatSettingsNotificationType notificationType;

    if ([string isEqualToString:@"this"])
        notificationType = ChatSettingsNotificationTypeEnabledLocally;
    else if ([string isEqualToString:@"all"])
        notificationType = ChatSettingsNotificationTypeEnabled;
    else
        notificationType = ChatSettingsNotificationTypeDisabled;

    return notificationType;
}

NSString * stringFromChatSettingsNotificationType(ChatSettingsNotificationType notificationType)
{
    NSString * notificationTypeString;
    switch (notificationType) {
        case ChatSettingsNotificationTypeDisabled:
            notificationTypeString = @"off";
            break;
        case ChatSettingsNotificationTypeEnabledLocally:
            notificationTypeString = @"this";
            break;
        case ChatSettingsNotificationTypeEnabled:
            notificationTypeString = @"all";
            break;
    }
    return notificationTypeString;
}

ChatSettingsSoundScheme chatSettingsSoundSchemeFromString(NSString * string)
{
    ChatSettingsSoundScheme soundScheme;

    if ([string isEqualToString:@"1"])
        soundScheme = ChatSettingsSoundSchemePersonal;
    else if ([string isEqualToString:@"2"])
        soundScheme = ChatSettingsSoundSchemeBusiness;
    else if ([string isEqualToString:@"3"])
        soundScheme = ChatSettingsSoundSchemeAlert;
    else
        soundScheme = ChatSettingsSoundSchemeDefault;

    return soundScheme;
}

NSString * stringFromChatSettingsSoundScheme(ChatSettingsSoundScheme soundScheme)
{
    NSString * soundSchemeString;

    switch (soundScheme) {
        case ChatSettingsSoundSchemeDefault:
            soundSchemeString = @"0";
            break;
        case ChatSettingsSoundSchemePersonal:
            soundSchemeString = @"1";
            break;
        case ChatSettingsSoundSchemeBusiness:
            soundSchemeString = @"2";
            break;
        case ChatSettingsSoundSchemeAlert:
            soundSchemeString = @"3";
            break;
    }

    return soundSchemeString;
}

@interface DialogSetting ()

@property (nonatomic, retain, readwrite) NSString *ntfMuteChat;
@property (nonatomic, retain, readwrite) NSString *ntfHidePush;
@property (nonatomic, retain, readwrite) NSString *ntfSmartPush;
@property (nonatomic, retain, readwrite) NSString *ntfTextHidden;
@property (nonatomic, retain, readwrite) NSString *ntfCounter;

@property (nonatomic, retain, readwrite) NSString *soundScheme;

@end

@implementation DialogSetting

@dynamic blockChat;
@dynamic favChat;
@dynamic soundScheme;
@dynamic ntfMuteChat;
@dynamic ntfHidePush;
@dynamic ntfSmartPush;
@dynamic ntfTextHidden;
@dynamic ntfCounter;

@dynamic dialog;

- (void)dialogSetting:(NSDictionary *)jsonData
{
    self.blockChat = [NSNumber numberWithBool:[jsonData[@"block"] boolValue]];
    self.favChat = [NSNumber numberWithBool:[jsonData[@"fav"] boolValue]];
    self.soundScheme = jsonData[@"snd"];
    self.ntfMuteChat = jsonData[@"ntf"][@"m"];
    self.ntfHidePush = jsonData[@"ntf"][@"h"];
    self.ntfSmartPush = jsonData[@"ntf"][@"s"];
    self.ntfTextHidden = jsonData[@"ntf"][@"t"];
    self.ntfCounter = jsonData[@"ntf"][@"c"];
}

- (BOOL)takenIntoAccountWhenCalculatingBadge
{
    return self.hidePushNotification == ChatSettingsNotificationTypeDisabled &&
            self.hideCounterNotification == ChatSettingsNotificationTypeDisabled;
}

- (NSDictionary *)paramsForSend
{
    NSMutableDictionary * paramsNtf = [[NSMutableDictionary alloc] init];
    [paramsNtf setObject:self.soundScheme forKey:@"snd"];
    [paramsNtf setObject:self.ntfMuteChat forKey:@"m"];
    [paramsNtf setObject:self.ntfHidePush forKey:@"h"];
    [paramsNtf setObject:self.ntfSmartPush forKey:@"s"];
    [paramsNtf setObject:self.ntfTextHidden forKey:@"t"];
    [paramsNtf setObject:self.ntfCounter  forKey:@"c"];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:self.dialog.chatID forKey:@"id"];
    [params setObject:self.blockChat forKey:@"block"];
    [params setObject:self.favChat forKey:@"fav"];
    [params setObject:@"0" forKey:@"snd"];
    [params setObject:paramsNtf forKey:@"ntf"];
    
    return params;
}

- (void)initDefaultValue
{
    [self dialogSetting:[self defaultSettings]];
}

- (NSDictionary *)defaultSettings
{
    return  @{@"block":@NO,
              @"fav":@"NO",
              @"snd":@"0",
              @"ntf":@{
                      @"m":@"off",
                      @"h":@"off",
                      @"s":@"off",
                      @"t":@"off",
                      @"c":@"off"
                      }
              };
}

//    "block": <boolean>,
//    "fav": <boolean>,
//    "snd": "<sound_scheme>",
//    "ntf": {
//        "m": "<all/this/off>",
//        "h": "<all/this/off>",
//        "s": "<all/this/off>",
//        "t": "<all/this/off>",
//        "c": "<all/this/off>"
//    }

#pragma mark - Mute Chat Notification

- (void)setMuteChatNotification:(ChatSettingsNotificationType)muteChatNotification
{
    self.ntfMuteChat = stringFromChatSettingsNotificationType(muteChatNotification);
}

- (ChatSettingsNotificationType)muteChatNotification
{
    return chatSettingsNotificationTypeFromString(self.ntfMuteChat);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingMuteChatNotification
{
    return [NSSet setWithObject:@"ntfMuteChat"];
}

#pragma mark - Hide Push Notification

- (void)setHidePushNotification:(ChatSettingsNotificationType)hidePushNotification
{
    self.ntfHidePush = stringFromChatSettingsNotificationType(hidePushNotification);
}

- (ChatSettingsNotificationType)hidePushNotification
{
    return chatSettingsNotificationTypeFromString(self.ntfHidePush);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingHidePushNotification
{
    return [NSSet setWithObject:@"ntfHidePush"];
}

#pragma mark - Smart Push Notification

- (void)setSmartPushNotification:(ChatSettingsNotificationType)smartPushNotification
{
    self.ntfSmartPush = stringFromChatSettingsNotificationType(smartPushNotification);
}

- (ChatSettingsNotificationType)smartPushNotification
{
    return chatSettingsNotificationTypeFromString(self.ntfSmartPush);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingSmartPushNotification
{
    return [NSSet setWithObject:@"ntfSmartPush"];
}

#pragma mark - Hide Text Notification

- (void)setHideTextNotification:(ChatSettingsNotificationType)hideTextNotification
{
    self.ntfTextHidden = stringFromChatSettingsNotificationType(hideTextNotification);
}

- (ChatSettingsNotificationType)hideTextNotification
{
    return chatSettingsNotificationTypeFromString(self.ntfTextHidden);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingHideTextNotification
{
    return [NSSet setWithObject:@"ntfTextHidden"];
}

#pragma mark - Hide Counter Notification

- (void)setHideCounterNotification:(ChatSettingsNotificationType)hideCounterNotification
{
    self.ntfCounter = stringFromChatSettingsNotificationType(hideCounterNotification);
}

- (ChatSettingsNotificationType)hideCounterNotification
{
    return chatSettingsNotificationTypeFromString(self.ntfCounter);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingHideTextHideCounterNotification
{
    return [NSSet setWithObject:@"ntfCounter"];
}

#pragma mark - Sound Scheme

- (void)setChatSoundScheme:(ChatSettingsSoundScheme)chatSoundScheme
{
    self.soundScheme = stringFromChatSettingsSoundScheme(chatSoundScheme);
}

- (ChatSettingsSoundScheme)chatSoundScheme
{
    return chatSettingsSoundSchemeFromString(self.soundScheme);
}

- (NSSet<NSString *> *)keyPathsForValuesAffectingChatSoundScheme
{
    return [NSSet setWithObject:@"soundScheme"];
}

@end
