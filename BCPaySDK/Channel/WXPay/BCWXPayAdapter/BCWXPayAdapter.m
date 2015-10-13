//
//  BCWXPayAdapter.m
//  BeeCloud
//
//  Created by Ewenlong03 on 15/9/9.
//  Copyright (c) 2015年 BeeCloud. All rights reserved.
//

#import "BCWXPayAdapter.h"
#import "WXApi.h"
#import "BeeCloudAdapterProtocol.h"
#import "BCPayUtil.h"

@interface BCWXPayAdapter ()<BeeCloudAdapterDelegate, WXApiDelegate>

@end

@implementation BCWXPayAdapter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BCWXPayAdapter *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BCWXPayAdapter alloc] init];
    });
    return instance;
}

- (BOOL)registerWeChat:(NSString *)appid {
    return [WXApi registerApp:appid];
}

- (BOOL)handleOpenUrl:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:[BCWXPayAdapter sharedInstance]];
}

- (BOOL)isWXAppInstalled {
    return [WXApi isWXAppInstalled];
}

- (void)wxPay:(NSMutableDictionary *)dic {
    
    PayReq *request = [[PayReq alloc] init];
    request.partnerId = [dic objectForKey:@"partner_id"];
    request.prepayId = [dic objectForKey:@"prepay_id"];
    request.package = [dic objectForKey:@"package"];
    request.nonceStr = [dic objectForKey:@"nonce_str"];
    NSMutableString *time = [dic objectForKey:@"timestamp"];
    request.timeStamp = time.intValue;
    request.sign = [dic objectForKey:@"pay_sign"];
    [WXApi sendReq:request];
}

#pragma mark - Implementation WXApiDelegate

- (void)onResp:(BaseResp *)resp {
    
    if ([resp isKindOfClass:[PayResp class]]) {
        PayResp *tempResp = (PayResp *)resp;
        NSString *strMsg = nil;
        int errcode = 0;
        switch (tempResp.errCode) {
            case WXSuccess:
                strMsg = @"支付成功";
                errcode = BCSuccess;
                break;
            case WXErrCodeUserCancel:
                strMsg = @"支付取消";
                errcode = BCErrCodeUserCancel;
                break;
            default:
                strMsg = @"支付失败";
                errcode = BCErrCodeSentFail;
                break;
        }
        NSString *result = tempResp.errStr.isValid?[NSString stringWithFormat:@"%@,%@",strMsg,tempResp.errStr]:strMsg;
        BCPayResp *resp = (BCPayResp *)[BCPayCache sharedInstance].bcResp;
        resp.resultCode = errcode;
        resp.resultMsg = result;
        resp.errDetail = result;
        [BCPayCache beeCloudDoResponse];
    }
}

@end
