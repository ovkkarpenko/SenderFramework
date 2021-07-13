//
// Created by Roman Serga on 5/7/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWMessagesCryptography.h"
#import "Message.h"
#import "ParamsFacade.h"
#import "Dialog.h"
#import "CoreDataFacade.h"
#import <CoreBitcoin/BTCBase58.h>
#import "ECCWorker.h"
#import "SecGenerator.h"
#import "Owner.h"

NSString * const MWMessagesCryptographyEncryptionPublicKey = @"MWMessagesCryptographyEncryptionPublicKey";
NSString * const MWMessagesCryptographyEncryptionText = @"MWMessagesCryptographyEncryptionText";

@implementation MWMessagesCryptography
{

}

+ (NSString *)decryptedMessageTextOfMessage:(Message *)message inChat:(Dialog *)chat
{
    if (!chat)
        return nil;

    NSDictionary * textData = [[ParamsFacade sharedInstance] dictionaryFromNSData:message.data];

    if (chat.isP2P)
    {
        NSData * keyData = nil;

        if (textData[@"pkey"])
        {
            if ([message.fromId isEqualToString:[CoreDataFacade sharedInstance].ownerUDID]) {
                keyData = chat.p2pBTCKeyData;
            } else {
                keyData = BTCDataFromBase58(textData[@"pkey"]);
            }
        }

        if (keyData.length < 32)
            keyData = chat.p2pBTCKeyData;

        NSString * decryptedString = [[ECCWorker sharedWorker] eciesDecriptMEssage:textData[@"text"]
                                                                    withPubKeyData:keyData
                                                                         shortkEkm:YES
                                                                         usePubKey:NO];

        return decryptedString;
    }
    else
    {
        NSString * decryptedString = [[SecGenerator sharedInstance] decryptMessage:textData[@"text"]
                                                                     withDialogKey:chat.encryptionKey];
        if (!decryptedString)
        {
            for (NSData * oldKeyData in chat.oldGroupKeys)
            {
                decryptedString = [[SecGenerator sharedInstance] decryptMessage:textData[@"text"]
                                                                  withDialogKey:oldKeyData];
                if ([decryptedString length] > 0)
                    break;
            }
        }

        return decryptedString;
    }
}


+ (NSDictionary *)encryptedMessageWithText:(NSString *)text chat:(Dialog *)chat
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    NSString * encryptedString;

    if ([chat chatType] == ChatTypeP2P) {
        NSString * publicKey = [[[[CoreDataFacade sharedInstance] getOwner] getMainWallet:nil] base58PublicKey];
        result[MWMessagesCryptographyEncryptionPublicKey] = publicKey;
        encryptedString = [[ECCWorker sharedWorker] eciesEncriptMEssage:text
                                                         withPubKeyData:chat.p2pBTCKeyData
                                                              shortkEkm:YES
                                                              usePubKey:NO];
    }
    else if ([chat chatType] == ChatTypeGroup) {
        if (chat.encryptionKey)
            encryptedString = [[SecGenerator sharedInstance] encryptMessage:text
                                                              withDialogKey:chat.encryptionKey];
    }
    if (encryptedString)
        result[MWMessagesCryptographyEncryptionText] = encryptedString;

    return result;
}

+ (Message *)encryptMessage:(Message *)message chat:(Dialog *)chat
{
    NSDictionary * messageData = [[ParamsFacade sharedInstance] dictionaryFromNSData:message.data];
    NSString * text = messageData[@"text"];
    if (!text) return nil;

    NSDictionary * encryptionResult = [self encryptedMessageWithText:text chat:chat];
    NSString * publicKey = encryptionResult[MWMessagesCryptographyEncryptionPublicKey];
    NSString * encryptedString = encryptionResult[MWMessagesCryptographyEncryptionText];

    if (!encryptedString) return nil;

    NSDictionary * newMessageData = @{@"text": encryptedString, @"pkey": (publicKey ?: @"")};
    message.encrypted = @YES;
    message.data = [[ParamsFacade sharedInstance] NSDataFromNSDictionary:newMessageData];
    return message;
}

@end
