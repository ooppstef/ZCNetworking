//
//  ZCNetworking.h
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZCBlockDefine.h"

@class AFHTTPSessionManager;

typedef NS_ENUM(NSInteger, ZCConnectionType){
    ZCConnectionTypeWifi = 0,
    ZCConnectionTypeWWAN,
    ZCConnectionTypeNone
};

@interface ZCNetworking : NSObject

@property (nonatomic, strong, readonly) NSURLSessionConfiguration *defaultConfigration;

/**
 *  单例
 *
 *  @return ZCNetworking instance
 */
+ (instancetype)sharedInstance;

/**
 *  获取当前网络状态
 *
 *  @return ZCConnectionType
 */
- (enum ZCConnectionType)getConnectionType;

/**
 *  通过url获取cookie
 *
 *  @param url url
 *
 *  @return 包含cookie的字典
 */
- (NSDictionary *)cookieForURL:(NSString *)url;

/**
 *  通过url删除cookie
 *
 *  @param url url
 */
- (void)deleteCookieWithURL:(NSString *)url;

/**
 *  设置默认的NSURLSessionConfiguration
 *
 *  @param configuration NSURLSessionConfiguration
 */
- (void)setDefaultSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 *  默认状态,通过url,method,params发送request
    url为包含host的绝对路径,例如:http://www.baidu.com/action=user?uid=10
    methods:get/post/delete/put/head/patch
 *
 *  @param url     url:包含host
 *  @param method  method:get/post/delete/put/head/patch
 *  @param params  参数
 *  @param success 包含id类型的block
 *  @param failure 包含NSError类型的block
 *
 *  @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)sendRequestWithURL:(NSString *)url method:(NSString *)method params:(NSDictionary *)params success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

/**
 *  自定义状态,通过configuration,url,method,params发送request
    configuration:NSURLSessionConfigurationr,自定义configuration
    url为包含host的绝对路径,例如:http://www.baidu.com/action=user?uid=10
    methods:get/post/delete/put/head/patch
 *
 *  @param configuration NSURLSessionConfiguration
 *  @param url           url:包含host
 *  @param method        method:get/post/delete/put/head/patch
 *  @param params        参数
 *  @param success       包含id类型的block
 *  @param failure       包含NSError类型的block
 *
 *  @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)sendRequestWithConfiguration:(NSURLSessionConfiguration *)configuration url:(NSString *)url method:(NSString *)method params:(NSDictionary *)params success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

/**
 *  默认状态,通过url获取图片
 *
 *  @param url     url为包含host的绝对路径
 *  @param success 包含UIImage类型的block
 *  @param failure 包含NSError类型的block
 *
 *  @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)loadImageWithURL:(NSString *)url success:(ZCImageBlock)success failure:(ZCErrorBlock)failure;

/**
 *  自定义状态,可自定义request的header/cache policy等
 *
 *  @param request NSURLRequest
 *  @param success 包含UIImage类型的block
 *  @param failure 包含NSError类型的block
 *
 *  @return NSURLSessionDataTask
 */
- (NSURLSessionDataTask *)loadImageWithRequest:(NSURLRequest *)request success:(ZCImageBlock)success failure:(ZCErrorBlock)failure;

/**
 *  默认状态,下载文件
 *
 *  @param url     url
 *  @param path    文件保存地址
 *  @param process 文件下载进度
 *  @param success 下载完毕block
 *  @param failure 包含NSError类型的block
 *
 *  @return NSURLSessionDownloadTask
 */
- (NSURLSessionDownloadTask *)downloadFileByURL:(NSString *)url savePath:(NSString *)path process:(void (^) (NSProgress *downloadProgress))process success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure;

/**
 *  自定义状态下载文件
 *
 *  @param configuration NSURLSessionConfiguration
 *  @param request       NSURLRequest
 *  @param path          文件保存地址
 *  @param process       文件下载进度
 *  @param success       下载完毕block
 *  @param failure       包含NSError类型的block
 *
 *  @return NSURLSessionDownloadTask
 */
- (NSURLSessionDownloadTask *)downloadFileWithConfiguration:(NSURLSessionConfiguration *)configuration request:(NSURLRequest *)request savePath:(NSString *)path process:(void (^) (NSProgress *downloadProgress))process success:(ZCVoidBlock)success failure:(ZCErrorBlock)failure;

/**
 *  默认状态,上传文件,data存放于http的body stream
 *
 *  @param request NSURLRequest
 *  @param process 文件上传进度
 *  @param success 上传完毕block
 *  @param failure 包含NSError类型的block
 *
 *  @return NSURLSessionUploadTask
 */
- (NSURLSessionUploadTask *)uploadTaskByRequest:(NSURLRequest *)request process:(void (^) (NSProgress *uploadProgress))process success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

/**
 *  自定义状态上传文件
 *
 *  @param configuration NSURLSessionConfiguration
 *  @param request       NSURLRequest
 *  @param process       文件上传进度
 *  @param success       上传完毕block
 *  @param failure       包含NSError类型的block
 *
 *  @return NSURLSessionUploadTask
 */
- (NSURLSessionUploadTask *)uploadTaskWithConfiguration:(NSURLSessionConfiguration *)configuration request:(NSURLRequest *)request process:(void (^) (NSProgress *uploadProgress))process success:(ZCTypeBlock)success failure:(ZCErrorBlock)failure;

@end
