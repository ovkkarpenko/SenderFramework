//
//  SenderRequestBuilder.m
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "SenderRequestBuilder.h"
#import "NSString+WebService.h"
#import "NSDictionaryToURLString.h"
#import "ServerFacade.h"
#import "SecGenerator.h"
#import "Owner.h"
#import "Settings.h"
#import "MWLocationFacade.h"
#import <SenderFramework/SenderFramework-Swift.h>

static SenderRequestBuilder * requestBuilder;

@interface SenderRequestBuilder()
{
    NSMutableDictionary * requestParams;
    NSMutableArray * prodServersArray;
}

@end

@implementation SenderRequestBuilder

+ (SenderRequestBuilder *)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        requestBuilder = [[SenderRequestBuilder alloc] init];
    });
    
    return requestBuilder;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        requestParams = [NSMutableDictionary dictionary];
        
        [self initServersUrls];
    }
    return self;
}



- (void)initServersUrls
{
    if (!prodServersArray) {
        prodServersArray = [[NSMutableArray alloc] init];
    }
    else {
        [prodServersArray removeAllObjects];
    }
    
    [self addProdURL];
}

- (void)addProdURL
{
//    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"knownServerIP"]) {
//        
//        prodServersArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"knownServerIP"]];
////        if ([prodServersArray[0] isEqualToString:prodServerURL] || [prodServersArray[0] isEqualToString:@"https://api.sender.mobi"]) {
////            [self changeServerURL];
////        }
//    }
//    else {
//        [prodServersArray addObject:prodServerURL];
//        [prodServersArray addObject:@"https://api.sender.mobi"];
//        [prodServersArray addObject:@"https://52.19.31.81"];
//        [prodServersArray addObject:@"https://52.19.35.245"];
//        [prodServersArray addObject:@"https://52.16.6.226"];
//        [[NSUserDefaults standardUserDefaults] setObject:prodServersArray forKey:@"knownServerIP"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
}

- (void)gotNewIP:(NSDictionary *)newIPs
{
    return;
    
    //TO DO
//    [prodServersArray removeAllObjects];
//    [self addProdURL];
//    
//    for (id key in newIPs) {
//        
//        NSString * newString = [NSString stringWithFormat: @"https://%@", newIPs[key]];
//        
//       [prodServersArray addObject:newString];
//    }
//    
//    [[NSUserDefaults standardUserDefaults] setObject:prodServersArray forKey:@"knownServerIP"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)changeServerURL
{
    if ([prodServersArray count] > 1)
    {
        NSString * tempString = [prodServersArray firstObject];
        [prodServersArray removeObject:tempString];
        [prodServersArray addObject:tempString];
    }
}

- (NSString *)httpServerUrl
{
    return [SenderCore sharedCore].configuration.onlineKeyServerAddress;
}

- (NSString *)senderServerURL
{
    return [SenderCore sharedCore].configuration.serverAddress;
}

- (NSMutableDictionary *)getParams
{
    if ([[ServerFacade sharedInstance] sid])
    {
        requestParams[@"sid"] = [ServerFacade sharedInstance].sid;
    }
    else
    {
        [requestParams removeAllObjects];
    }
    return requestParams;
}

- (nonnull NSMutableURLRequest *)requestWithPath:(NSString *)path
                               urlParams:(NSDictionary *)params
                                postData:(id)data
{
    if ([path isEqualToString:@"sync_ct"] || [path isEqualToString:@"sync_dlg"]) {
        return [self requestWithPath:path urlParams:params postData:data timeOutInterval:45];
    }
    return [self requestWithPath:path urlParams:params postData:data timeOutInterval:20];
}

- (nonnull NSMutableURLRequest *)requestWithPath:(NSString *)path
                                       urlParams:(NSDictionary *)params
                                        postData:(id)data
                                 timeOutInterval:(int)timeOutInterval
{
    NSString * urlAsString  = [[self senderServerURL] stringByAppendingString:[NSString stringWithFormat:@"/%@/%@",[SENDER_SHARED_CORE senderVersion],path]];
    if (params) {
        urlAsString = [urlAsString stringByAppendingString:@"?"];
        urlAsString = [urlAsString stringByAppendingString:[NSDictionaryToURLString convertToULRString:params]];
    }
    
    NSURL * url = [NSURL URLWithString:urlAsString];
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeOutInterval];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [request addValue:@"Upgrade" forHTTPHeaderField:@"Connection"];

    if (data) {
        NSData * jsonData;
        if (![data isKindOfClass:[NSData class]]) {
            NLog(@"(%lu_%p) REQUEST (%@) TO PATH: %@\n%@\nPARAMS : %@\nBODY DATA:%@", request.hash, &request, request.HTTPMethod, request.URL.path, request.URL.absoluteString, [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params ?: @{} options:0 error:nil]encoding:4], [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data ?: @{} options:0 error:nil]encoding:4]);            //            [SENDER_SHARED_CORE addLogToLoger:[NSString stringWithFormat:@"CREATE REQUEST  -- \n%@", data]];
            NSError *error;
            jsonData = [NSJSONSerialization dataWithJSONObject:(NSDictionary *)data
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
        }
        else
        {
            jsonData = data;
        }
        
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[jsonData length]] forHTTPHeaderField:@"Content-Lenght"];
        [request setHTTPBody:jsonData];
    }
    
    return request;
}

- (NSDictionary *)urlStringParams
{
    NSString * activeChat = [SenderCore sharedCore].activeChatsCoordinator.activeChatID ?: @"";
    NSMutableDictionary * urlDict = [NSMutableDictionary dictionary];
    [urlDict addEntriesFromDictionary:[[MWLocationFacade sharedInstance]locationDictionary]];
    NSString * udid = [[SecGenerator sharedInstance] hashedDeviceUDID];
    [urlDict addEntriesFromDictionary:@{@"token":[SecGenerator sharedInstance].tempTokken,
                                        @"udid":udid,
                                        @"ac":activeChat}];
    return urlDict;
}

//
//- (NSMutableURLRequest *)uploadRequestWithPath:(NSString *)path urlParams:(NSDictionary *)params
//{
//    NSString * urlAsString  = [SenderServerURL stringByAppendingString:[NSString stringWithFormat:@"/%@",path]];
//    //    NSMutableDictionary * urlParams = [self getParams];
//    //    [urlParams addEntriesFromDictionary:params];
//    if (params) {
//        urlAsString = [urlAsString stringByAppendingString:@"?"];
//        urlAsString = [urlAsString stringByAppendingString:[NSDictionaryToURLString convertToULRString:params]];
//    }
//    
//    NSURL *url=[NSURL URLWithString:urlAsString];
//    
//    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
//    [request setHTTPMethod:@"POST"];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    return request;
//}


@end
