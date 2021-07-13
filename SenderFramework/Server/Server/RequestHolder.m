//
//  RequestHolder.m
//  SENDER
//
//  Created by Nick Gromov on 10/2/14.
//  Copyright (c) 2014 Middleware Inc. All rights reserved.
//

#import "RequestHolder.h"

@implementation RequestHolder

- (id)initWithPath:(NSString *)path_
          postData:(id)postData_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_
{
    if (self = [super init]) {
        self.requestType = SStandartType;
        self.path = path_;
        self.postData = postData_;
        self.completionHandler = completionHandler_;
    }
    return self;
}

- (id)initWithPath:(NSString *)path_
         urlParams:(NSDictionary *)params_
          postData:(id)postData_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_
{
    self = [self initWithPath:path_ postData:postData_ completionHandler:completionHandler_];
    if(self)
    {
        self.urlParams = params_;
        self.requestType = SStandartType;
        self.path = path_;
        self.postData = postData_;
        self.completionHandler = completionHandler_;
    }
    return self;
}

- (id)initWithUrl:(NSString *)url_ completionHandler:(SenderRequestCompletionHandler)completionHandler_
{
    self = [super init];
    if(self)
    {
        self.requestType = SFileType;
        self.completionHandler = completionHandler_;
        self.url = url_;
    }
    return self;
}

- (id)initWithPath:(NSString *)path_
         urlParams:(NSDictionary *)params_
      localFileUrl:(NSURL *)localFileUrl_
 completionHandler:(SenderRequestCompletionHandler)completionHandler_
{
    self = [self initWithPath:path_ postData:nil completionHandler:completionHandler_];
    if(self)
    {
        self.urlParams = params_;
        self.localFileUrl = localFileUrl_;
    }
    return self;
}

//
///*
// Attempt to fetch the NAPTR from the stored server address.  Since iOS will continue waiting
// until told directly to stop (even if there is no result) we must set our own timeout on the
// request (set to 5 seconds).
// On success, the callback function is called.  On timeout, the kSRVLookupComplete notification
// is sent.
// */
//- (void)attemptNAPTRFetch {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        DNSServiceRef sdRef;
//        DNSServiceErrorType err;
//        
//        err = DNSServiceQueryRecord(&sdRef, 0, 0,
//                                    [server cStringUsingEncoding:[NSString defaultCStringEncoding]],
//                                    kDNSServiceType_NAPTR,
//                                    kDNSServiceClass_IN,
//                                    callback,
//                                    NULL);
//        
//        // This stuff is necessary so we don't hang forever if there are no results
//        int dns_sd_fd = DNSServiceRefSockFD(sdRef);
//        int nfds = dns_sd_fd + 1;
//        fd_set readfds;
//        struct timeval tv;
//        int result;
//        
//        int stopNow = 0;
//        int timeOut = 5; // Timeout in seconds
//        
//        while (!stopNow) {
//            FD_ZERO(&readfds);
//            FD_SET(dns_sd_fd, &readfds);
//            tv.tv_sec = timeOut;
//            tv.tv_usec = 0;
//            
//            result = select(nfds, &readfds, (fd_set*)NULL, (fd_set*)NULL, &tv);
//            if (result > 0) {
//                if(FD_ISSET(dns_sd_fd, &readfds)) {
//                    err = DNSServiceProcessResult(sdRef);
//                    if (err != kDNSServiceErr_NoError){
//                        // NSLog(@"There was an error");
//                    }
//                    stopNow = 1;
//                }
//            }
//            else {
//                printf("select() returned %d errno %d %s\n", result, errno, strerror(errno));
//                if (errno != EINTR) {
//                    stopNow = 1;
//                    postNotification(kSRVLookupComplete, nil);
//                }
//            }
//        }
//        
//        DNSServiceRefDeallocate(sdRef);
//    });
//}
//
//static void callback(DNSServiceRef sdRef,
//                     DNSServiceFlags flags,
//                     uint32_t interfaceIndex,
//                     DNSServiceErrorType errorCode,
//                     const char *fullname,
//                     uint16_t rrtype,
//                     uint16_t rrclass,
//                     uint16_t rdlen,
//                     const void *rdata,
//                     uint32_t ttl,
//                     void *context)
//{
//    uint16_t order, pref;
//    char flag;
//    NSMutableString *service = [[NSMutableString alloc] init];
//    NSMutableString *replacement = [[NSMutableString alloc] init];
//    
//    const char *data = (const char*)rdata;
//    
//    order = data[1];
//    pref = data[3];
//    flag = data[5];
//    int i = 7;
//    while (data[i] != 0){
//        [service appendString:[NSString stringWithFormat:@"%c", data[i]]];
//        i++;
//    }
//    i += 2;
//    while(data[i] != 0){
//        if(data[i] >= 32 && data[i] <= 127)
//            [replacement appendString:[NSString stringWithFormat:@"%c", data[i]]];
//        else
//            [replacement appendString:@"."];
//        i++;
//    }
//    // NSLog(@"\nOrder: %i\nPreference: %i\nFlag: %c\nService: %@\nReplacement: %@\n", order, pref, flag, service, replacement);
//}
//
@end
