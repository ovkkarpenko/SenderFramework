//
//  BitcoinManager.h
//  SENDER
//
//  Created by Roman Serga on 23/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BitcoinWallet.h"
#import "ServerFacade.h"
#import <CoreBitcoin/BTCTransactionBuilder.h>

#define defaultFee 100

//Right now Bitcoin manager works with only one transaction at the time.
//You can create new transaction only after old transaction fishes.
//Or you create new instance of BitcoinManager to perform simultaneous transactions.

@interface BitcoinManager : NSObject <BTCTransactionBuilderDataSource>

- (void)transferMoneyFromWallet:(BitcoinWallet *)wallet
                      toAddress:(NSString *)destinationAddress
                     withAmount:(NSString *)amount
              completionHandler:(SenderRequestCompletionHandler)completionHandler;


- (void)transferMoneyFromWallet:(BitcoinWallet *)wallet
                      toAddress:(NSString *)destinationAddress
                     withAmount:(NSString *)amount
                         andFee:(BTCAmount)fee
              completionHandler:(SenderRequestCompletionHandler)completionHandler;

@end
