//
//  ZCNetworking.m
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import "ZCNetworking.h"
#import "AFNetworking.h"
#import "AFImageDownloader.h"

@interface ZCNetworking ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;
@property (nonatomic, assign) BOOL                 needToResetManager;

@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *defaultConfigration;

@end

@implementation ZCNetworking

#pragma mark - life cycle

+ (instancetype)sharedInstance {
    static ZCNetworking *zcNetworking;
    static dispatch_once_t networkToken;
    dispatch_once(&networkToken, ^{
        zcNetworking = [[ZCNetworking alloc] init];
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024 diskCapacity:20 * 1024 * 1024 diskPath:nil];
        [NSURLCache setSharedURLCache:cache];
    });
    return zcNetworking;
}

#pragma mark - utils

- (enum ZCConnectionType)getConnectionType {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    enum ZCConnectionType type;
    if([manager isReachable]){
        if([manager isReachableViaWiFi]){
            type = ZCConnectionTypeWifi;
        }
        else{
            type = ZCConnectionTypeWWAN;
        }
    }
    else{
        type = ZCConnectionTypeNone;
    }
    return type;
}

- (NSDictionary *)cookieForURL:(NSString *)url {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    storage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
    NSArray *cookieStorage = [storage cookiesForURL:[NSURL URLWithString:url]];
    NSDictionary *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieStorage];
    return cookieHeaders;
}

- (void)deleteCookieWithURL:(NSString *)url {
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookieStorage = [storage cookiesForURL:[NSURL URLWithString:url]];
    for (NSHTTPCookie *cookie in cookieStorage) {
        [storage deleteCookie:cookie];
    }
}

- (void)setDefaultSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    _defaultConfigration = configuration;
}

- (NSURLSessionConfiguration *)defaultConfigration {
    if (!_defaultConfigration) {
        return [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    else {
        return _defaultConfigration;
    }
}

- (NSString *)validURL:(NSString *)url {
    url = url.lowercaseString;
    if ([url hasPrefix:@"http"]) {
        return url;
    }
    else {
        return [NSString stringWithFormat:@"http://%@",url];
    }
    return nil;
}

#pragma mark - actions

- (NSURLSessionDataTask *)sendRequestWithURL:(NSString *)url method:(NSString *)method params:(NSDictionary *)params success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    return [self sendRequestWithConfiguration:nil url:url method:method params:params success:success failure:failure];
}

- (NSURLSessionDataTask *)sendRequestWithConfiguration:(NSURLSessionConfiguration *)configuration url:(NSString *)url method:(NSString *)method params:(NSDictionary *)params success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    url = [self validURL:url];
    NSURL *fullUrl = [NSURL URLWithString:url];
    if (!fullUrl.host) {
        failure([NSError errorWithDomain:@"Illegal URL" code:-100 userInfo:nil]);
        return nil;
    }
    
    if (!_manager || _needToResetManager) {
        _manager = [self defaultManager];
        _needToResetManager = NO;
    }
    if (configuration) {
        [self copyConfiguration:configuration];
        _needToResetManager = YES;
    }
    
    NSURLSessionDataTask *task = nil;
    if ([[method uppercaseString] isEqualToString:@"GET"]) {
        task = [_manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(error);
        }];
    }
    else if ([[method uppercaseString] isEqualToString:@"POST"]) {
        task = [_manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            failure(error);
        }];
    }
    else if ([[method uppercaseString] isEqualToString:@"DELETE"]) {
        task = [_manager DELETE:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            failure(error);
        }];
    }
    else if ([[method uppercaseString] isEqualToString:@"PUT"]) {
        task = [_manager PUT:url parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
            success(responseObject);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            failure(error);
        }];
    }
    else if ([[method uppercaseString] isEqualToString:@"HEAD"]) {
        task = [_manager HEAD:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task) {
            success(task);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            failure(error);
        }];
    }
    return task;
}

- (NSURLSessionDataTask *)loadImageWithURL:(NSString *)url success:(ZCImageBlock)success failure:(ZCErrorBlock)failure {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    return [self loadImageWithRequest:request success:success failure:failure];
}

- (NSURLSessionDataTask *)loadImageWithRequest:(NSURLRequest *)request success:(ZCImageBlock)success failure:(ZCErrorBlock)failure {
    AFImageDownloadReceipt *receipt = [[AFImageDownloader defaultInstance] downloadImageForURLRequest:request success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
        failure(error);
    }];
    return receipt.task;
}

- (NSURLSessionDownloadTask *)downloadFileByURL:(NSString *)url savePath:(NSString *)path process:(void (^) (NSProgress *downloadProgress))process success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    return [self downloadFileWithConfiguration:nil request:request savePath:path process:process success:success failure:failure];;
}

- (NSURLSessionDownloadTask *)downloadFileWithConfiguration:(NSURLSessionConfiguration *)configuration request:(NSURLRequest *)request savePath:(NSString *)path process:(void (^) (NSProgress *downloadProgress))process success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure {
    if (!_manager || _needToResetManager) {
        _manager = [self defaultManager];
        _needToResetManager = NO;
    }
    if (configuration) {
        [self copyConfiguration:configuration];
        _needToResetManager = YES;
    }
    NSURLSessionDownloadTask *downloadTask = [_manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        !process? : process(downloadProgress);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:path];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (!error) {
            success();
        }
        else {
            failure(error);
        }
    }];
    [downloadTask resume];
    return downloadTask;
}

- (NSURLSessionUploadTask *)uploadTaskByRequest:(NSURLRequest *)request process:(void (^) (NSProgress *uploadProgress))process success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    return [self uploadTaskWithConfiguration:nil request:request process:process success:success failure:failure];
}

- (NSURLSessionUploadTask *)uploadTaskWithConfiguration:(NSURLSessionConfiguration *)configuration request:(NSURLRequest *)request process:(void (^) (NSProgress *uploadProgress))process success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    if (!_manager || _needToResetManager) {
        _manager = [self defaultManager];
        _needToResetManager = NO;
    }
    if (configuration) {
        [self copyConfiguration:configuration];
        _needToResetManager = YES;
    }

    NSURLSessionUploadTask *uploadTask = [_manager uploadTaskWithStreamedRequest:request progress:^(NSProgress * _Nonnull uploadProgress) {
        !process? : process(uploadProgress);
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (!error) {
            success(responseObject);
        }
        else {
            failure(error);
        }
    }];
    
    [uploadTask resume];
    return uploadTask;
}

#pragma mark - private methods

- (void)copyConfiguration:(NSURLSessionConfiguration *)configuration {
    if (!_manager || !configuration) {
        return;
    }
    _manager.session.configuration.HTTPAdditionalHeaders = configuration.HTTPAdditionalHeaders;
    _manager.session.configuration.requestCachePolicy = configuration.requestCachePolicy;
    _manager.session.configuration.timeoutIntervalForRequest = configuration.timeoutIntervalForRequest;
    _manager.session.configuration.timeoutIntervalForResource = configuration.timeoutIntervalForResource;
    _manager.session.configuration.networkServiceType = configuration.networkServiceType;
    _manager.session.configuration.discretionary = configuration.discretionary;
    _manager.session.configuration.sharedContainerIdentifier = configuration.sharedContainerIdentifier;
    _manager.session.configuration.sessionSendsLaunchEvents = configuration.sessionSendsLaunchEvents;
    _manager.session.configuration.connectionProxyDictionary = configuration.connectionProxyDictionary;
    _manager.session.configuration.TLSMinimumSupportedProtocol = configuration.TLSMinimumSupportedProtocol;
    _manager.session.configuration.TLSMaximumSupportedProtocol = configuration.TLSMaximumSupportedProtocol;
    _manager.session.configuration.HTTPShouldUsePipelining = configuration.HTTPShouldUsePipelining;
    _manager.session.configuration.HTTPShouldSetCookies = configuration.HTTPShouldSetCookies;
    _manager.session.configuration.HTTPCookieAcceptPolicy = configuration.HTTPCookieAcceptPolicy;
    _manager.session.configuration.HTTPMaximumConnectionsPerHost = configuration.HTTPMaximumConnectionsPerHost;
    _manager.session.configuration.HTTPCookieStorage = configuration.HTTPCookieStorage;
    _manager.session.configuration.URLCredentialStorage = configuration.URLCredentialStorage;
    _manager.session.configuration.URLCache = configuration.URLCache;
}

- (AFHTTPSessionManager *)defaultManager {
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[self defaultConfigration]];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return manager;
}

@end
