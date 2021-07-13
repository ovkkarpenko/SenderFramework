//
//  BitcoinUtils.h
//  SENDER
//
//  Created by Roman Serga on 22/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#define kBitcoinQRPublicAddress @"bitcoin"
#define kBitcoinQRAmount @"amount"
#define kBitcoinQRName @"name"
#define kBitcoinQRMessage @"message"
#define kBitcoinQROriginalString @"original"

#import <Foundation/Foundation.h>
#import <CoreBitcoin/BTCUnitsAndLimits.h>

@class BTCTransactionOutput;

NSDictionary * parseBitcoinQRString(NSString * qrString);
NSString * balanceFromUnspentTransactions(NSArray<BTCTransactionOutput *> * transactions);
NSString * formattedBalance(BTCAmount balance);
