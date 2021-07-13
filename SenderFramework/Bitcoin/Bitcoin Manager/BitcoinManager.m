//
//  BitcoinManager.m
//  SENDER
//
//  Created by Roman Serga on 23/12/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "BitcoinManager.h"
#import "ServerFacade.h"
#import <CoreBitcoin/BTCTransaction.h>
#import <CoreBitcoin/BTCScript.h>
#import "Owner.h"

@interface BitcoinManager ()

@property (nonatomic, strong) BitcoinWallet * currentWallet;
@property (nonatomic, strong) SenderRequestCompletionHandler completionHandler;

@end

@implementation BitcoinManager

- (NSEnumerator* /* [BTCTransactionOutput] */) unspentOutputsForTransactionBuilder:(BTCTransactionBuilder*)txbuilder
{
    return [NSEnumerator new];
}

- (void)transferMoneyFromWallet:(BitcoinWallet *)wallet
                      toAddress:(NSString *)destinationAddress
                     withAmount:(NSString *)amount
              completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    [self transferMoneyFromWallet:wallet
                        toAddress:destinationAddress
                       withAmount:amount andFee:BTCBit
                completionHandler:completionHandler];
}

-(void)transferMoneyFromWallet:(BitcoinWallet *)wallet
                     toAddress:(NSString *)destinationAddress
                    withAmount:(NSString *)amount
                        andFee:(BTCAmount)fee
             completionHandler:(SenderRequestCompletionHandler)completionHandler
{
    self.currentWallet = wallet;
    self.completionHandler = completionHandler;
    [[ServerFacade sharedInstance] getUnspentTransactionsForWallet:wallet
                                                 completionHandler:^(NSArray *unspentTransactions, NSError *error) {
        if (!error)
        {
            wallet.unspentOutputs = unspentTransactions;
            BTCAmount parsedAmount = atof([amount UTF8String]) * BTCCoin;
            
            BTCTransactionOutput * transactionOutput = [[BTCTransactionOutput alloc]initWithValue:parsedAmount address:[BTCAddress addressWithString:destinationAddress]];
            
            BTCTransactionBuilder * transactionBuilder = [[BTCTransactionBuilder alloc]init];
            transactionBuilder.dataSource = self;
            transactionBuilder.unspentOutputsEnumerator = unspentTransactions.objectEnumerator;
            transactionBuilder.changeAddress = wallet.paymentKey.compressedPublicKeyAddress;
            transactionBuilder.outputs = @[transactionOutput];
            
            BTCTransaction * transacation = [[transactionBuilder buildTransaction:&error] transaction];
            
            if (!error)
            {
                [[ServerFacade sharedInstance] sendTransaction:transacation withCompletionHandler:^(NSDictionary *response, NSError *error)
                {
                    [self finishWithResponse:response error:error];
                }];
            }
            else
            {
                NSError * errorToReturn;
                switch (error.code) {
                    case 3:
                        errorToReturn = [NSError errorWithDomain:error.domain
                                                            code:error.code
                                                        userInfo:@{ NSLocalizedDescriptionKey : SenderFrameworkLocalizedString(@"bitcoin_error_not_enough_funds", nil)}];
                        break;
                    default:
                        errorToReturn = [NSError errorWithDomain:error.domain
                                                            code:error.code
                                                        userInfo:@{ NSLocalizedDescriptionKey : SenderFrameworkLocalizedString(@"bitcoin_error_unknown", nil)}];
                        break;
                }
                [self finishWithResponse:nil error:errorToReturn];
            }
        }
        
        else
        {
            [self finishWithResponse:nil error:error];
        }
    }];
}

-(void)finishWithResponse:(NSDictionary *)response error:(NSError *)error
{
    if (self.completionHandler)
        self.completionHandler(response, error);
    self.completionHandler = nil;
}

-(BTCKey *)transactionBuilder:(BTCTransactionBuilder *)txbuilder keyForUnspentOutput:(BTCTransactionOutput *)txout
{
    BitcoinWallet * wallet = [[[CoreDataFacade sharedInstance]getOwner]getMainWallet:nil];
    for (int index = 0; index <= 100; index++)
    {
        BTCKey * key = [wallet.paymentKeychain keyAtIndex:index];
        if ([txout.script.standardAddress isEqual:key.compressedPublicKeyAddress])
            return key;
    }
    
    return nil;
}

@end
