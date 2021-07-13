//
//  BitcoinUtils.m
//  SENDER
//
//  Created by Roman Serga on 22/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "BitcoinUtils.h"
#import <CoreBitcoin/BTCTransactionOutput.h>

NSDictionary * parseBitcoinQRString(NSString * qrString)
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    result[kBitcoinQROriginalString] = qrString;
    
    if ([qrString hasPrefix:@"bitcoin:"])
    {
        NSArray * stringComponents = [qrString componentsSeparatedByString:@"?"];
        for (NSString * component in stringComponents) {
            if ([component hasPrefix:kBitcoinQRPublicAddress])
            {
                NSArray * bitcoinAddressComponents = [component componentsSeparatedByString:@":"];
                result[kBitcoinQRPublicAddress] = [bitcoinAddressComponents lastObject];
            }
            else
            {
                NSArray * paramComponents = [component componentsSeparatedByString:@"="];
                if ([paramComponents count] == 2)
                {
                    NSString * key = [paramComponents firstObject];
                    NSString * value = [paramComponents lastObject];
                    result[key] = value;
                }
            }
        }
    }
    
    return [result copy];
}


NSString * balanceFromUnspentTransactions(NSArray<BTCTransactionOutput *> * transactions)
{
    BTCAmount balance = 0;
    for (BTCTransactionOutput * output in transactions) {
        balance += output.value;
    }
    return formattedBalance(balance);
}

NSString * formattedBalance(BTCAmount balance)
{
    if (balance > 0) {
        return [NSString stringWithFormat:@"%lld.%@", balance / BTCCoin, [NSString stringWithFormat:@"%08lld", balance % BTCCoin]];
    }
    else {
        return @"0.00";
    }
}
