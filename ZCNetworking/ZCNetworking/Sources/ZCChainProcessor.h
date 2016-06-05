//
//  ZCChainProcessor.h
//  ZCNetworking
//
//  Created by charles on 16/6/5.
//  Copyright © 2016年 charles. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCApiAction.h"
#import "ZCBlockDefine.h"

@interface ZCChainProcessor : NSObject

- (instancetype)initWithActions:(NSArray<ZCApiAction *> *)actions;
- (void)startWithSuccess:(ZCDictBlock)success failure:(ZCErrorBlock)failure;

@end
