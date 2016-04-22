//
//  ZCApiAction.m
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import "ZCApiAction.h"

@interface ZCApiAction ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *params;
@property (nonatomic, copy, readwrite)   NSString            *method;

@end

@implementation ZCApiAction

#pragma mark - life cycle

- (instancetype)init {
    if (self = [super init]) {
        _method = @"GET";
        _params = [NSMutableDictionary dictionary];
        _timeout = 180;
    }
    return self;
}

- (instancetype)initWithURL:(NSString *)url {
    self = [self init];
    _url = url;
    return self;
}

- (void)setHttpMethod:(enum HttpMethod)method {
    switch (method) {
        case httpGet:
            self.method = @"GET";
            break;
        case HttpPost:
            self.method = @"POST";
            break;
        case HttpDelete:
            self.method = @"DELETE";
            break;
        case HttpPut:
            self.method = @"PUT";
            break;
        default:
            break;
    }
}

@end
