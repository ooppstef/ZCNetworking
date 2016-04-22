//
//  ZCApiRunner.h
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCBlockDefine.h"

@class ZCApiAction;
@class ZCApiUploadAction;
@class ZCApiDownloadAction;

@interface ZCApiRunner : NSObject

/**
 *  强制使用domain,而非根据编译环境
 */
@property (nonatomic, copy)   NSString     *forceDomain;

/**
 *  全局参数,例如version/platform等
 */
@property (nonatomic, strong) NSDictionary *globleParams;

/**
 *  单例
 *
 *  @return ZCApiRunner
 */
+ (instancetype)sharedInstance;

/**
 *  根据编译环境配置host,使得不会因为疏忽导致服务器错误
 *
 *  @param debug   测试服务器host
 *  @param release 正式服务器host
 */
- (void)startWithDebugDomain:(NSString *)debug releaseDomain:(NSString *)release;

/**
 *  获取当前host
 *
 *  @return 当前host
 */
- (NSString *)currentDomain;

/**
 *  是否为测试服务器host
 *
 *  @return 是否为测试服务器host
 */
- (BOOL)isDebugDomain;

/**
 *  添加请求的http header
 *
 *  @param dict http header
 */
- (void)headerForSessionConfiguration:(NSDictionary *)dict;

/**
 *  添加请求的http header
 *
 *  @param value value
 *  @param key   key
 */
- (void)addValue:(id)value forHeaderKey:(NSString *)key;

/**
 *  删除请求的header
 *
 *  @param key key
 */
- (void)removeHeaderKey:(NSString *)key;

/**
 *  请求逻辑成功标志,不设置则默认所有请求物理成功(http 200)则逻辑也成功
 *
 *  @param key 逻辑成功标志
 */
- (void)codeKey:(NSString *)key;

/**
 *  请求逻辑成功codes
 *
 *  @param codes 逻辑成功codes
 */
- (void)successCodes:(NSArray<NSString *> *)codes;

/**
 *  请求逻辑失败后,一些典型/公共codes以及处理回调.例如登录失效
 *
 *  @param codes   逻辑失败codes
 *  @param handler 逻辑失败回调
 */
- (void)warningReturnCodes:(NSArray<NSString *> *)codes withHandler:(void (^) (NSString *code))handler;

/**
 *  通过action进行数据任务
 *
 *  @param action ZCApiAction
 *  @param success 成功回调(物理&&逻辑成功)
 *  @param failure 失败回调(物理||逻辑失败)
 *
 *  @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)runAction:(ZCApiAction *)action success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

/**
 *  通过action进行上传任务
 *
 *  @param action ZCApiUploadAction
    @param action NSProgress
 *  @param success 成功回调(物理&&逻辑成功)
 *  @param failure 失败回调(物理||逻辑失败)
 *
 *  @return NSURLSessionUploadTask
 */
- (NSURLSessionUploadTask *)uploadAction:(ZCApiUploadAction *)action progress:(void (^) (NSProgress *uploadProgress))progress success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

/**
 *  通过action进行下载任务
 *
 *  @param action   ZCApiDownloadAction
 *  @param progress NSProgress
 *  @param success  成功回调
 *  @param failure  失败回调
 *
 *  @return NSURLSessionDownloadTask
 */
- (NSURLSessionDownloadTask *)downloadAction:(ZCApiDownloadAction *)action progress:(void (^) (NSProgress *downloadProgress))progress success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure;

/**
 *  批量请求,顺序为止,所有请求成功后执行success,某个请求失败后立即执行failure
 *
 *  @param actions 请求列表
 *  @param success 成功回调
 *  @param failure 失败回调
 */
- (void)batchTasksWithActions:(NSArray<ZCApiAction *> *)actions success:(ZCDictBlock)success failure:(ZCErrorBlock)failure;

- (void)chainTasksWithActions:(NSArray<ZCApiAction *> *)actions success:(ZCDictBlock)success failure:(ZCErrorBlock)failure;

@end
