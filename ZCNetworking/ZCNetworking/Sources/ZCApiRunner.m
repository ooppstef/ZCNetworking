//
//  ZCApiRunner.m
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import "ZCApiRunner.h"
#import "ZCNetworking.h"
#import "ZCApiAction.h"
#import "ZCApiUploadAction.h"
#import "ZCApiDownloadAction.h"
#import "AFNetworking.h"
#import "ZCChainProcessor.h"

@interface ZCApiRunner ()

@property (nonatomic, copy) NSString *debugDomain;
@property (nonatomic, copy) NSString *releaseDomain;

@property (nonatomic, strong) NSMutableDictionary   *addtionalHeaders;
@property (nonatomic, copy)   NSString              *codeKey;
@property (nonatomic, strong) NSArray<NSString *>   *successCodes;
@property (nonatomic, strong) NSArray<NSString *>   *warningCodes;
@property (nonatomic, copy)   ZCWarningCodesHandler warningCodesHandler;
@property (nonatomic, strong) NSMutableArray        *chainProcessorArray;

@end

@implementation ZCApiRunner

#pragma mark - life cycle

+ (instancetype)sharedInstance {
    static ZCApiRunner *zcApiRunner;
    static dispatch_once_t apiRunnerToken;
    dispatch_once(&apiRunnerToken, ^{
        zcApiRunner = [[ZCApiRunner alloc] init];
    });
    return zcApiRunner;
}

#pragma mark - domain settings

- (void)startWithDebugDomain:(NSString *)debug releaseDomain:(NSString *)release {
    _debugDomain = debug;
    _releaseDomain = release;
}

- (NSString *)currentDomain {
    if (_forceDomain.length > 0) {
        return _forceDomain;
    }
    else {
#ifdef DEBUG
        return _debugDomain;
#else
        return _releaseDomain;
#endif
    }
}

- (BOOL)isDebugDomain {
    return [[self currentDomain] isEqualToString:_debugDomain];
}

#pragma mark - header settings

- (void)headerForSessionConfiguration:(NSDictionary *)dict {
    _addtionalHeaders = [dict mutableCopy];
    NSURLSessionConfiguration *configuration = [ZCNetworking sharedInstance].defaultConfigration;
    NSMutableDictionary *headers = configuration.HTTPAdditionalHeaders.mutableCopy;
    if (!headers) {
        headers = @{}.mutableCopy;
    }
    [headers addEntriesFromDictionary:dict];
    configuration.HTTPAdditionalHeaders = headers;
    [[ZCNetworking sharedInstance] setDefaultSessionConfiguration:configuration];
}

- (void)addValue:(id)value forHeaderKey:(NSString *)key {
    if (!value) {
        return;
    }
    
    if (!_addtionalHeaders) {
        _addtionalHeaders = [NSMutableDictionary dictionary];
    }
    
    _addtionalHeaders[key] = value;
    [self headerForSessionConfiguration:_addtionalHeaders];
}

- (void)removeHeaderKey:(NSString *)key {
    [_addtionalHeaders removeObjectForKey:key];
    [self headerForSessionConfiguration:_addtionalHeaders];
}

#pragma mark - api return codes settings

- (void)codeKey:(NSString *)key {
    _codeKey = key;
}

- (void)successCodes:(NSArray<NSString *> *)codes {
    _successCodes = codes;
}
- (void)warningReturnCodes:(NSArray<NSString *> *)codes withHandler:(void (^) (NSString *code))handler {
    _warningCodes = codes;
    _warningCodesHandler = handler;
}

#pragma mark - api actions

- (NSURLSessionDataTask *)runAction:(ZCApiAction *)action success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    NSError *error = [self validateAction:action];
    if (error) {
        failure(error);
        return nil;
    }
    [action.params addEntriesFromDictionary:self.globleParams];
    [self showLogByAction:action];
    
    NSString *fullURL = [self actionURL:action];
    !action.actionWillInvokeBlock ? : action.actionWillInvokeBlock();
    
    NSURLSessionDataTask *task;
    __weak typeof(self) weakSelf = self;
    if (action.headers) {
        NSURLSessionConfiguration *configuration = [ZCNetworking sharedInstance].defaultConfigration.copy;
        NSMutableDictionary *headers = _addtionalHeaders.mutableCopy;
        [headers addEntriesFromDictionary:action.headers];
        configuration.HTTPAdditionalHeaders = headers;
        task = [[ZCNetworking sharedInstance] sendRequestWithConfiguration:configuration url:fullURL method:action.method params:action.params success:^(id object) {
            [weakSelf handleAction:action withResponse:object success:^(id object) {
                !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(YES);
                !success? : success(object);
            } failure:^(NSError *error) {
                !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(NO);
                !failure ? : failure(error);
            }];
        } failure:^(NSError *error) {
            !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(NO);
            !failure? : failure(error);
        }];
    }
    else {
        task = [[ZCNetworking sharedInstance] sendRequestWithURL:fullURL method:action.method params:action.params success:^(id object) {
            [weakSelf handleAction:action withResponse:object success:^(id object) {
                !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(YES);
                !success? : success(object);
            } failure:^(NSError *error) {
                !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(NO);
                !failure? : failure(error);
            }];
        } failure:^(NSError *error) {
            !action.actionDidInvokeBlock ? : action.actionDidInvokeBlock(NO);
            !failure? : failure(error);
        }];
    }
    return task;
}

- (NSURLSessionUploadTask *)uploadAction:(ZCApiUploadAction *)action progress:(void (^) (NSProgress *uploadProgress))progress success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    NSError *error = [self validateAction:action];
    if (error) {
        !failure? : failure(error);
        return nil;
    }
    [action.params addEntriesFromDictionary:self.globleParams];
    [self showLogByAction:action];
    
    NSString *fullURL = [self actionURL:action];
    !action.actionWillInvokeBlock ? : action.actionWillInvokeBlock();
    
    __weak typeof(self) weakSelf = self;
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:fullURL parameters:action.params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        if ([action isValidMultiObjectUploadAction]) {
            for (NSInteger i = 0;i < [action.dataArray count];i++) {
                NSData *data = action.dataArray[i];
                NSString *uploadName = action.uploadNameArray[i];
                NSString *fileName = action.fileNameArray[i];
                NSString *mimeType;
                if ([action.mimeTypeArray count] > 0) {
                    mimeType = action.mimeTypeArray[i];
                }
                else {
                    mimeType = action.mimeTypeArray[0];
                }
                [formData appendPartWithFileData:data name:uploadName fileName:fileName mimeType:mimeType];
            }
        }
        else if (action.data) {
            [formData appendPartWithFileData:action.data name:action.uploadName fileName:action.fileName mimeType:action.mimeType];
        }
    } error:nil];
    
    request.timeoutInterval = action.timeout;
    NSMutableDictionary *headers = _addtionalHeaders.mutableCopy;
    [headers addEntriesFromDictionary:action.headers];
    request.allHTTPHeaderFields = headers;
    
    NSURLSessionUploadTask *uploadTask = [[ZCNetworking sharedInstance] uploadTaskByRequest:request process:progress success:^(id object) {
        [weakSelf handleAction:action withResponse:object success:^(id object) {
            !success ? : success(object);
        } failure:^(NSError *error) {
            !failure? : failure(error);
        }];
    } failure:^(NSError *error) {
        !failure? : failure(error);
    }];
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadAction:(ZCApiDownloadAction *)action progress:(void (^) (NSProgress *downloadProgress))progress success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure {
    NSError *error = [self validateAction:action];
    if (error) {
        !failure? : failure(error);
        return nil;
    }
    [action.params addEntriesFromDictionary:self.globleParams];
    [self showLogByAction:action];
    
    NSString *fullURL = [self actionURL:action];
    !action.actionWillInvokeBlock ? : action.actionWillInvokeBlock();
    
    NSURLSessionDownloadTask *task;
    if (action.headers) {
        NSURLSessionConfiguration *configuration = [ZCNetworking sharedInstance].defaultConfigration.copy;
        NSMutableDictionary *headers = _addtionalHeaders.mutableCopy;
        [headers addEntriesFromDictionary:action.headers];
        configuration.HTTPAdditionalHeaders = headers;
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
        task = [[ZCNetworking sharedInstance] downloadFileWithConfiguration:configuration request:request savePath:action.path process:progress success:^{
            !success? : success();
        } failure:^(NSError *error) {
            !failure? : failure(error);
        }];
    }
    else {
        task = [[ZCNetworking sharedInstance] downloadFileByURL:fullURL savePath:action.path process:progress success:^{
            !success? : success();
        } failure:^(NSError *error) {
            !failure? : failure(error);
        }];
    }
    return task;
}

- (void)batchTasksWithActions:(NSArray<ZCApiAction *> *)actions success:(ZCDictBlock)success failure:(ZCErrorBlock)failure {
    NSMutableArray *tasks = [@[] mutableCopy];
    NSMutableDictionary *resultDict = [@{} mutableCopy];
    dispatch_group_t group = dispatch_group_create();
    __block BOOL flag = YES;
    __block NSError *err = nil;
    for (ZCApiAction *action in actions) {
        dispatch_group_enter(group);
        __block NSURLSessionTask *task = [self runAction:action success:^(id object) {
            dispatch_group_leave(group);
            if (action.identifier) {
                resultDict[action.identifier] = object;
            }
            else {
                resultDict[action.url] = object;
            }
        } failure:^(NSError *error) {
            err = error;
            dispatch_group_leave(group);
            flag = NO;
            for (NSURLSessionTask *t in tasks) {
                [t cancel];
            }
        }];
        [tasks addObject:task];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (flag) {
            !success? : success(resultDict);
        }
        else {
            !failure? : failure(err);
        }
    });
}

- (void)chainTasksWithActions:(NSArray<ZCApiAction *> *)actions success:(ZCDictBlock)success failure:(ZCErrorBlock)failure {

    /**
     *  该实现会导致死锁(AFHTTPSessionManager的complationQueue为main queue)
        可以将complationQueue替换成globle queue以解决此问题,不过得不偿失.
     */
    
//    NSMutableDictionary *resultDict = [@{} mutableCopy];
//    __block NSError *err = nil;
//    
//    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//
//    [actions enumerateObjectsUsingBlock:^(ZCApiAction * _Nonnull action, NSUInteger idx, BOOL * _Nonnull stop) {
//        [self runAction:action success:^(id object) {
//            resultDict[action.url] = object;
//            dispatch_semaphore_signal(semaphore);
//        } failure:^(NSError *error) {
//            err = err;
//            dispatch_semaphore_signal(semaphore);
//            *stop = YES;
//        }];
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//    }];
//    
//    if (err) {
//        !failure? : failure(err);
//    }
//    else {
//        !success? : success(resultDict);
//    }
    
    ZCChainProcessor *processor = [[ZCChainProcessor alloc] initWithActions:actions];
    
    __weak typeof(self) weakSelf = self;
    void (^complationSuccess) (NSDictionary *dict) = ^ (NSDictionary *dict) {
        [weakSelf.chainProcessorArray removeObject:processor];
        !success? : success(dict);
    };
    void (^complationFailure) (NSError *error) = ^ (NSError *error) {
        [weakSelf.chainProcessorArray removeObject:processor];
        !failure? : failure(error);
    };
    
    [processor startWithSuccess:complationSuccess failure:complationFailure];
    [self.chainProcessorArray addObject:processor];
}

#pragma mark - private methods

- (NSString *)actionURL:(ZCApiAction *)action {
    NSString *domain = [self currentDomain];
    if ([domain hasSuffix:@"/"]) {
        domain = [domain substringToIndex:domain.length - 1];
    }
    if ([action.url hasSuffix:@"/"]) {
        action.url = [action.url substringFromIndex:1];
    }
    NSString *url = [[self currentDomain] stringByAppendingString:action.url];
    return url;
}

- (NSError *)validateAction:(ZCApiAction *)action {
    if (!action) {
        return [NSError errorWithDomain:@"Action is nil" code:-200 userInfo:nil];
    }
    
    if (action.url.length == 0 ) {
        return [NSError errorWithDomain:@"URL is nil" code:-300 userInfo:nil];
    }
    
    return nil;
}

- (void)showLogByAction:(ZCApiAction *)action {
    if (action.showLog) {
        NSString *fullURL = [self actionURL:action];
        NSString *urlToLog = fullURL;
        if (action.params) {
            urlToLog = [urlToLog stringByAppendingString:@"?"];
            for (NSString *key in [action.params allKeys]) {
                urlToLog = [urlToLog stringByAppendingFormat:@"%@=%@&",key,action.params[key]];
            }
            urlToLog = [urlToLog substringToIndex:urlToLog.length - 1];
        }
        NSLog(@"url:%@",urlToLog);
        NSLog(@"methods:%@",action.method);
        NSLog(@"addtional headers:%@",_addtionalHeaders);
        NSLog(@"params:%@",action.params);
    }
}

- (void)handleAction:(ZCApiAction *)action withResponse:(id)object success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure {
    /*
     返回值必须为NSData
     */
    if (![object isKindOfClass:[NSData class]]) {
        if (action.showLog) {
            NSLog(@"Return object is unknown");
        }
        failure([NSError errorWithDomain:@"Return object is not NSData" code:-300 userInfo:nil]);
        return;
    }
    
    /*
     返回值必须为NSDictionary/NSArray类型
     目前仅支持返回值为JSON对象,不支持XML
     */
    id returnObject = [NSJSONSerialization JSONObjectWithData:object options:NSJSONReadingMutableContainers error:nil];

    if (![returnObject isKindOfClass:[NSArray class]] && ![returnObject isKindOfClass:[NSDictionary class]]) {
        if (action.showLog) {
            NSString *returnStr = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
            NSLog(@"error return:%@",returnStr);
        }
        failure([NSError errorWithDomain:@"Return object can not converted to JSON" code:-400 userInfo:nil]);
        return;
    }
    
    //如果是NSArray类型,则无需检查code,直接返回即可
    if ([returnObject isKindOfClass:[NSArray class]]) {
        if (action.showLog) {
            NSLog(@"%@",returnObject);
        }
        success(returnObject);
        return;
    }
    
    //无需检查code key则直接返回
    if (!_codeKey) {
        if (action.showLog) {
            NSLog(@"%@",returnObject);
        }
        success(returnObject);
        return;
    }
    
    //检查code key
    NSDictionary *responseDict = returnObject;
    NSString *returnCode = nil;
    id targetCode = responseDict[_codeKey];
    
    //如果没有targetCode(api不规范等),则直接返回成功
    if (!targetCode) {
        if (action.showLog) {
            NSLog(@"%@",returnObject);
        }
        success(returnObject);
        return;
    }
    
    /*
     使用NSString的Equal而不是转化成NSInteger,是因为非数字的字符串转换后为0
     例如 [@"hello" integerValue] = 0
     
     通过successCodes判定是否成功
     通过warningCodes对错误做出统一处理
     
     既不满足successCodes也不满足warningCodes则自行处理.
     
     */
    
    if ([targetCode isKindOfClass:[NSString class]]) {
        returnCode = targetCode;
    }
    else {
        returnCode = [targetCode stringValue];
    }

    BOOL isSuccess = NO;
    for (NSString *sucCode in _successCodes) {
        if ([sucCode isEqualToString:returnCode]) {
            isSuccess = YES;
            break;
        }
    }
    
    if (isSuccess) {
        if (action.showLog) {
            NSLog(@"%@",returnObject);
        }
        success(returnObject);
    }
    else {
        BOOL isWarningCode = NO;
        for(NSString *warningCode in _warningCodes){
            if([returnCode isEqualToString:warningCode]){
                isWarningCode = YES;;
                break;
            }
        }
        
        if (isWarningCode) {
            if (action.showLog) {
                NSLog(@"%@",returnObject);
                NSLog(@"enter warning code handler process,return code is:%@",returnCode);
            }
            failure(returnObject);
            !_warningCodesHandler ? : _warningCodesHandler(returnCode);
        }
        else {
            if (action.showLog) {
                NSString *returnStr = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
                NSLog(@"Not satisfy success condition!The return info is:%@",returnStr);
            }
            failure([NSError errorWithDomain:@"Not satisfy success condition" code:[returnCode integerValue] userInfo:@{@"object":returnObject}]);
        }
    }
}

#pragma mark - getters

- (NSMutableArray *)chainProcessorArray {
    if (_chainProcessorArray) {
        _chainProcessorArray = @[].mutableCopy;
    }
    
    return _chainProcessorArray;
}

@end
