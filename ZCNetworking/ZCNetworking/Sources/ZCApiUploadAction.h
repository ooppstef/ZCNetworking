//
//  ZCApiUploadAction.h
//  MeClassManager
//
//  Created by charleszhang on 15/9/14.
//  Copyright (c) 2015年 com.meclass. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZCApiAction.h"

@interface ZCApiUploadAction : ZCApiAction

/**
 *  这两组值是互斥的,为了方便单个Object上传任务和多个Object上传任务
    如果每次均以数组的形式上传单个文件,则在实际使用过程中(大部分为单个文件上传,例如上传头像等)会显得麻烦
 */

@property (nonatomic, strong) NSData   *data;
@property (nonatomic, copy)   NSString *uploadName;
@property (nonatomic, copy)   NSString *fileName;
@property (nonatomic, copy)   NSString *mimeType;

@property (nonatomic, strong) NSArray  *dataArray;
@property (nonatomic, strong) NSArray  *uploadNameArray;
@property (nonatomic, strong) NSArray  *fileNameArray;
@property (nonatomic, strong) NSArray  *mimeTypeArray;

/**
 *  检查是否为合格的多个组件Object上传action
 *  必须相关的array count相同并且大于0
 */
- (BOOL)isValidMultiObjectUploadAction;

@end
