//
// Created by Roman Serga on 9/8/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

#import "MWFMLStringParser.h"
#import "CoreDataFacade.h"
#import "BitcoinWallet.h"
#import "ServerFacade.h"
#import "Owner.h"
#import "Contact.h"
#import "Dialog.h"


@implementation MWFMLStringParser

+ (void)parseFMLString:(NSString *)originalString
               forChat:(Dialog *)chat
     completionHandler:(void(^)(NSString * parsedString))completionHandler
{
    if (originalString.length > 4 && [[originalString substringToIndex:3] isEqualToString:@"{{!"]) {
        NSString * valName = @"User name hidden";
        NSString * valPhone = @"Phone hidden";
        NSString * valDescription = @"User description hidden";
        NSString * valBtcAddress = @"BTC Address";

        NSString * tmp = [originalString substringFromIndex:8];
        tmp = [tmp substringToIndex:tmp.length - 2];
        NSArray * urls = [tmp componentsSeparatedByString:@"."];

        BOOL isOwnersInfo = NO;
        if ([urls[0] isEqualToString:[CoreDataFacade sharedInstance].ownerUDIDString] || [urls[0] isEqualToString:@"me"])
        {
            isOwnersInfo = YES;
            valName = [CoreDataFacade sharedInstance].getOwner.name;
            valPhone = [CoreDataFacade sharedInstance].getOwner.numberPhone;
            valDescription = [CoreDataFacade sharedInstance].getOwner.desc;
            valBtcAddress = [[CoreDataFacade sharedInstance].getOwner getMainWallet:nil].paymentKey.compressedPublicKeyAddress.string;
        }
        else
        {
            NSString * userID;
            if ([urls[0] isEqualToString:@"!user"])
                userID = userIDFromChatID(chat.chatID);
            else
                userID = urls[0];
            Contact * contact = [[CoreDataFacade sharedInstance] selectContactById:userID];
            if (contact)
            {
                valName = contact.name;
                valPhone = [contact getPhoneFormatted:NO];
                valDescription = contact.contactDescription;
                valBtcAddress = contact.bitcoinAddress;
            }
        }

        if ([urls[1] isEqualToString:@"name"]) {
            completionHandler(valName);
        }
        else if ([urls[1] isEqualToString:@"desc"]) {
            completionHandler(valDescription);
        }
        else if ([urls[1] isEqualToString:@"phone"]) {
            completionHandler(valPhone);
        }
        else if ([urls[1] isEqualToString:@"btc_addr"]) {
            completionHandler(valBtcAddress);
        }
        else if ([urls[1] isEqualToString:@"btc_balance"]) {
            if (!isOwnersInfo)
            {
                completionHandler(@"");
                return;
            }
            BitcoinWallet * defaultWallet = [[CoreDataFacade sharedInstance].getOwner getMainWallet:nil];
            [[ServerFacade sharedInstance] getUnspentTransactionsForWallet:defaultWallet
                                                         completionHandler:^(NSArray *unspentTransactions, NSError *error) {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 defaultWallet.unspentOutputs = unspentTransactions;
                                                                 completionHandler(defaultWallet.balance);
                                                             });
                                                         }];
        }
    }
    else {
        completionHandler(originalString);
    }
}

@end