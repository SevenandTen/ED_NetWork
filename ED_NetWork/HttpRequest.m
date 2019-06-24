//
//  HttpRequest.m
//  TestApp
//
//  Created by 崎崎石 on 2018/1/29.
//  Copyright © 2018年 崎崎石. All rights reserved.
//

#import "HttpRequest.h"

#define kBoundary @"dijfojoidshdijffi"

@interface HttpRequest ()<NSURLSessionDataDelegate>

@property (nonatomic , strong) NSURLSession *session;

@property (nonatomic , assign) NSInteger type;

@property (nonatomic , weak) id<HttpRequestDelegate>delegate;

@property (nonatomic , strong) NSMutableData *data;

@property (nonatomic , assign) HttpDataType dataType;

@property (nonatomic , strong) NSURLRequest *urlRequest;

@property (nonatomic , copy) void(^complete)(id response , NSError *error);


@end


@implementation HttpRequest

#pragma mark - Init
- (instancetype)initWithCustomType:(NSInteger)type httpDataType:(HttpDataType)dataType delegate:(id<HttpRequestDelegate>)delegate {
    if (self = [super init]) {
        _type = type;
        _delegate = delegate;
        _dataType = dataType;
    }
    return self;
}

- (instancetype)initWithDelegate:(id<HttpRequestDelegate>)delegate {
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - Public

+ (instancetype)startRequestWithUrlString:(NSString *)url httpMethod:(HttpMethod)method getParam:(NSDictionary *)getParam postParam:(NSDictionary *)postParam headerParam:(NSDictionary *)headerParam customServiceType:(NSInteger)type httpDataType:(HttpDataType)dataType delegate:(id<HttpRequestDelegate>)delegate {
    HttpRequest *httpRequest = [[self alloc] initWithCustomType:type httpDataType:dataType delegate:delegate];
    NSURLRequest *request = [self getRequestWithUrl:url httpMethod:method getParam:getParam postParam:postParam headerParam:headerParam httpDatatype:dataType];
    httpRequest.urlRequest = request;
    [httpRequest startConnect];
    
    return httpRequest;
}

+ (instancetype)startRequestWithUrlString:(NSString *)url httpMethod:(HttpMethod)method getParam:(NSDictionary *)getParam postParam:(NSDictionary *)postParam headerParam:(NSDictionary *)headerParam customServiceType:(NSInteger)type httpDataType:(HttpDataType)dataType complete:(void (^)(id, NSError *))complete {
    HttpRequest *httpRequest = [[self alloc] initWithCustomType:type httpDataType:dataType delegate:nil];
    NSURLRequest *request = [self getRequestWithUrl:url httpMethod:method getParam:getParam postParam:postParam headerParam:headerParam httpDatatype:dataType];
    httpRequest.urlRequest = request;
    httpRequest.complete = complete;
    [httpRequest startConnect];

    return httpRequest;
}

+ (id)startSynRequestWithUrlString:(NSString *)url httpMethod:(HttpMethod)method getParam:(NSDictionary *)getParam postParam:(NSDictionary *)postParam headerParam:(NSDictionary *)headerParam customService:(NSInteger)type httpDataType:(HttpDataType)dataType error:(NSError *__autoreleasing *)error {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0); //创建信号量
    NSURLRequest *request = [self getRequestWithUrl:url httpMethod:method getParam:getParam postParam:postParam headerParam:headerParam httpDatatype:dataType];
    __block id responseData = nil;
    __block NSError *responeseErr = nil;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable err) {
            responeseErr = err;
        if (data) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            }else{
                responeseErr = [NSError errorWithDomain:@"请求错误" code:1077 userInfo:nil];
            }
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    
    
    dispatch_semaphore_wait(semaphore,DISPATCH_TIME_FOREVER);  //等待
    if (responeseErr) {
        *error = responeseErr;
    }
    return responseData;
}


+ (instancetype)startUpLoadFileWithUrl:(NSString *)url fileArray:(NSArray<NSData *> *)file customServiceType:(NSInteger)type fileKey:(NSString *)fileKey fileName:(NSString *)fileName fileType:(NSString *)fileType headerParam:(NSDictionary *)headerParam delegate:(id<HttpRequestDelegate>)delegate {
    HttpRequest *httpRequest = [[HttpRequest alloc] initWithDelegate:delegate];
    NSURLRequest *request = [self getRequestWithUrl:url fileArray:file fileKey:fileKey fileName:fileName fileType:fileType headerParam:headerParam];
    httpRequest.urlRequest = request;
    [httpRequest startConnect];    
    return httpRequest;
}

+ (instancetype)startUpLoadFileWithUrl:(NSString *)url fileArray:(NSArray<NSData *> *)file customServiceType:(NSInteger)type fileKey:(NSString *)fileKey fileName:(NSString *)fileName fileType:(NSString *)fileType headerParam:(NSDictionary *)headerParam complete:(void (^)(id, NSError *))complete {
    HttpRequest *httpRequest = [[HttpRequest alloc] initWithDelegate:nil];
    NSURLRequest *request = [self getRequestWithUrl:url fileArray:file fileKey:fileKey fileName:fileName fileType:fileType headerParam:headerParam];
    httpRequest.complete = complete;
    httpRequest.urlRequest = request;
    [httpRequest startConnect];
    return httpRequest;
    
}


+ (NSURLRequest *)getRequestWithUrl:(NSString *)url fileArray:(NSArray<NSData *> *)dataArray fileKey:(NSString *)fileKey fileName:(NSString *)fileName fileType:(NSString *)fileType headerParam:(NSDictionary *)headerParam {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.timeoutInterval = 10;
    request.HTTPMethod = @"POST";
    NSMutableDictionary *dic = nil;
    if (headerParam.count == 0) {
        dic = [[NSMutableDictionary alloc] init];
    }else{
        dic = [[NSMutableDictionary alloc] initWithDictionary:headerParam];
    }
    [dic setObject:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",kBoundary]
                            forKey:@"Content-Type"];
    headerParam = dic;
    [request setAllHTTPHeaderFields:headerParam];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    //添加边界
    for (NSData *data in dataArray) {
        NSString * tmpStr = [NSString stringWithFormat:@"--%@\r\n",kBoundary];
        [bodyData appendData:[tmpStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        //设置参数key和名称
        tmpStr = @"Content-Disposition: form-data";
        
        if (fileKey.length) { //设置key
            tmpStr = [tmpStr stringByAppendingFormat:@"; name=\"%@\"",fileKey];
        }
        
        if (fileName.length) { //设置文件名
            tmpStr = [tmpStr stringByAppendingFormat:@"; filename=\"%@\"",fileName];
        }
        
        tmpStr = [tmpStr stringByAppendingString:@"\r\n"];
        [bodyData appendData:[tmpStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        //类型
        if (fileType.length) {
            tmpStr = [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n",fileType];
            [bodyData appendData:[tmpStr dataUsingEncoding:NSUTF8StringEncoding]];
        }else{
            [bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        //数据
        [bodyData appendData:data];
        [bodyData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
  
    if (bodyData.length) {
        NSString * endStr = [NSString stringWithFormat:@"--%@--",kBoundary];
        [bodyData appendData:[endStr dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [request setHTTPBody:bodyData];
    return request;
}

+ (NSURLRequest *)getRequestWithUrl:(NSString *)url httpMethod:(HttpMethod)method getParam:(NSDictionary *)getParam postParam:(NSDictionary *)postParam headerParam:(NSDictionary *)headerParam httpDatatype:(HttpDataType)dataType{
    NSMutableURLRequest *request = nil;
    NSString *urlString = nil;
    if (getParam.count > 0 && getParam) {
        NSString *paramString = [self paramFromDicToString:getParam];
        urlString = [NSString stringWithFormat:@"%@?%@",url,paramString];
    }else{
        urlString = url;
    }
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    if (method == HttpGet) {
        [request setHTTPMethod:@"GET"];
    }else{
        [request setHTTPMethod:@"POST"];
        if (postParam.count > 0 && postParam) {
            if (dataType == HttpDataForm) {
                NSString *paramString = [self paramFromDicToString:postParam];
                NSData *data = [paramString dataUsingEncoding:NSUTF8StringEncoding];
                [request setHTTPBody:data];
            }else if (dataType == HttpDataJson){
                NSError *error = nil;
                id data = [NSJSONSerialization dataWithJSONObject:postParam options:NSJSONWritingPrettyPrinted error:&error];
                if (!error) {
                    [request setHTTPBody:data];
                }else{
                    NSLog(@"参数转换失败");
                }
            }
        }
        
    }
    NSMutableDictionary *dic = nil;
    if (headerParam.count > 0) {
        dic = [[NSMutableDictionary alloc] initWithDictionary:headerParam];
    }else{
        dic = [[NSMutableDictionary alloc] init];
    }
    if (dataType == HttpDataJson) {
        [dic setObject:@"application/json" forKey:@"Content-Type"];
    }else if (dataType == HttpDataForm) {
        [dic setObject: @"application/x-www-form-urlencoded" forKey:@"Content-Type"];
    }
    headerParam = dic ;
    [request setAllHTTPHeaderFields:headerParam];
    request.timeoutInterval = 10 ;
    return request;
}

- (NSInteger)getCustomType {
    return self.type;
}

- (void)restartConnect {
    if (self.urlRequest) {
        [self startConnect];
    }
}

#pragma mark - Private

+ (NSString *)paramFromDicToString:(NSDictionary *)param {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSString *key in param) {
        [array addObject:[NSString stringWithFormat:@"%@=%@",key,[param objectForKey:key]]];
    }
    
    return [array componentsJoinedByString:@"&"];
}

- (void)startConnectWithRequest:(NSURLRequest *)request {
    self.urlRequest= request;
    [[self.session dataTaskWithRequest:request] resume];
}

- (void)startConnect {
    self.data = nil;
    [[self.session dataTaskWithRequest:self.urlRequest] resume];
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask
didReceiveResponse:(nonnull NSURLResponse *)response
completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler {
   
    completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.data appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        if (self.complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.complete(nil, error);
            });
        }else {
            if ([self.delegate respondsToSelector:@selector(httpRequest:didFailConnectWithCustomServiceType:erroer:)]) {
                [self.delegate httpRequest:self didFailConnectWithCustomServiceType:self.type erroer:error];
            }
        }
        
        
    }else{
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        if (response.statusCode / 200 == 1) {
            if (self.complete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.complete(self.data, nil);
                });
            }else {
                if ([self.delegate respondsToSelector:@selector(httpRequest:didSuccessConnectWithCustomServiceType:data:)]) {
                    [self.delegate httpRequest:self didSuccessConnectWithCustomServiceType:self.type data:self.data];
                }
            }
            
        }else{
            NSError *httpError = [NSError errorWithDomain:@"请求错误" code:response.statusCode userInfo:nil];
            if (self.complete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.complete(nil, httpError);
                });
            }else {
                if ([self.delegate respondsToSelector:@selector(httpRequest:didFailConnectWithCustomServiceType:erroer:)]) {
                    [self.delegate httpRequest:self didFailConnectWithCustomServiceType:self.type erroer:httpError];
                }
            }
            
        }
        
        
    }
}




#pragma mark - Getter

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
}

- (NSMutableData *)data {
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    return _data;
}



@end
