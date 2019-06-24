//
//  HttpRequest.h
//  TestApp
//
//  Created by 崎崎石 on 2018/1/29.
//  Copyright © 2018年 崎崎石. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger , HttpMethod) { //请求方法类型
    HttpPost = 1 ,  //POST 请求
    HttpGet , // GET 请求
};

typedef NS_ENUM(NSInteger , HttpDataType) { //HTTP 协议传输的body方式
    HttpDataForm,
    HttpDataJson,
};


@class HttpRequest;
@protocol HttpRequestDelegate<NSObject>

- (void)httpRequest:(HttpRequest *)httpRequest didFailConnectWithCustomServiceType:(NSInteger)type erroer:(NSError *)error;

- (void)httpRequest:(HttpRequest *)httpRequest didSuccessConnectWithCustomServiceType:(NSInteger)type data:(NSData *)data;


@end


@interface HttpRequest : NSObject

// 异步网络请求
+ (instancetype)startRequestWithUrlString:(NSString *)url
                               httpMethod:(HttpMethod)method
                                 getParam:(NSDictionary *)getParam
                                postParam:(NSDictionary *)postParam
                              headerParam:(NSDictionary *)headerParam
                        customServiceType:(NSInteger)type
                             httpDataType:(HttpDataType)dataType
                                 delegate:(id<HttpRequestDelegate>)delegate;


+ (instancetype)startRequestWithUrlString:(NSString *)url
                               httpMethod:(HttpMethod)method
                                 getParam:(NSDictionary *)getParam
                                postParam:(NSDictionary *)postParam
                              headerParam:(NSDictionary *)headerParam
                        customServiceType:(NSInteger)type
                             httpDataType:(HttpDataType)dataType
                                 complete:(void(^)(id response , NSError *error)) complete;


//获取请求状态
- (NSInteger)getCustomType;

//同步网络请求
+ (id)startSynRequestWithUrlString:(NSString *)url
                        httpMethod:(HttpMethod)method
                          getParam:(NSDictionary *)getParam
                         postParam:(NSDictionary *)postParam
                       headerParam:(NSDictionary *)headerParam
                     customService:(NSInteger)type
                      httpDataType:(HttpDataType)dataType
                             error:(NSError * *)error;

// 上传文件


+ (instancetype)startUpLoadFileWithUrl:(NSString *)url
                             fileArray:(NSArray<NSData *> *)file
                     customServiceType:(NSInteger)type
                               fileKey:(NSString *)fileKey
                              fileName:(NSString *)fileName
                              fileType:(NSString *)fileType
                           headerParam:(NSDictionary *)headerParam
                              delegate:(id<HttpRequestDelegate>)delegate;


+ (instancetype)startUpLoadFileWithUrl:(NSString *)url
                             fileArray:(NSArray<NSData *> *)file
                     customServiceType:(NSInteger)type
                               fileKey:(NSString *)fileKey
                              fileName:(NSString *)fileName
                              fileType:(NSString *)fileType
                           headerParam:(NSDictionary *)headerParam
                              complete:(void(^)(id response , NSError *error)) complete;

// 重新开始网络请求
- (void)restartConnect;

@end
