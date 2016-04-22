//
//  ZCBlockDefine.h
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ZCVoidBlock) (void);
typedef void (^ZCArrayBlock) (NSArray *array);
typedef void (^ZCDictBlock) (NSDictionary *dict);
typedef void (^ZCErrorBlock) (NSError *error);
typedef void (^ZCTypeBlock) (id object);
typedef void (^ZCImageBlock) (UIImage *image);
typedef void (^ZCWarningCodesHandler) (NSString *code);
typedef void (^ZCActionComplation) (BOOL isSuccess);