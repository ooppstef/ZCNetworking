//
//  ZCApiAction.h
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCBlockDefine.h"

typedef NS_ENUM(NSInteger, HttpMethod) {
    httpGet = 1,
    HttpPost,
    HttpPut,
    HttpDelete,
    HttpHead
};


@interface ZCApiAction : NSObject

/**
 *  参数,只读.
    已初始化,可以直接使用.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *params;
/**
 *  Http methods,默认Get.只读.
    修改使用setHttpMethod:方法
 */
@property (nonatomic, copy, readonly)   NSString *method;

/**
 *  相对url,不包含domain
 */
@property (nonatomic, copy)   NSString           *url;

/**
 *  超时时间,默认180s
 */
@property (nonatomic, assign) NSTimeInterval     timeout;

/**
 *  Http headers
 */
@property (nonatomic, strong) NSDictionary       *headers;

/**
 *  Http请求log,建议调试的时候打开
 */
@property (nonatomic, assign) BOOL               showLog;

/**
 *  请求即将执行时候的回调,可用于启动hud等
 */
@property (nonatomic, copy)   ZCVoidBlock        actionWillInvokeBlock;

/**
 *  请求执行完毕的回调,可用于关闭hud等.包含参数isSuccess,表示请求是否执行成功.
 */
@property (nonatomic, copy)   ZCActionComplation actionDidInvokeBlock;

/**
 *  标志.执行batch操作的时候,优先通过identifier来汇总结果.如果没有,则通过url来汇总.
 */
@property (nonatomic, copy)   NSString           *identifier;

- (instancetype)initWithURL:(NSString *)url;
- (void)setHttpMethod:(enum HttpMethod)method;

@end
