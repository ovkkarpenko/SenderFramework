//
//  RequestHolder.h
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ SenderRequestCompletionHandler )(NSDictionary * response, NSError * error);

typedef NS_ENUM(NSInteger, SRequestType) {
    SStandartType,
    SFileType,
    SFileUploadType
};

@interface RequestHolder : NSObject

@property SRequestType requestType;
@property (nonatomic, strong) NSString * path;
@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) NSDictionary * urlParams;
@property (nonatomic, strong) id postData;
@property (copy) SenderRequestCompletionHandler completionHandler;
@property (nonatomic, strong) NSURL * localFileUrl;

- (id)initWithPath:(NSString *)path_
          postData:(id)postData_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_;

- (id)initWithPath:(NSString *)path_
         urlParams:(NSDictionary *)params_
          postData:(id)postData_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_;

- (id)initWithUrl:(NSString *)url_ completionHandler:(SenderRequestCompletionHandler)completionHandler_;
- (id)initWithPath:(NSString *)path_
         urlParams:(NSDictionary *)params_
      localFileUrl:(NSURL *)localFileUrl_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_;
@end
