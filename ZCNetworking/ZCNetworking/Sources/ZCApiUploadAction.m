//
//  ZCApiUploadAction.m
//  MeClassManager
//
//  Created by charleszhang on 15/9/14.
//  Copyright (c) 2015年 com.meclass. All rights reserved.
//

#import "ZCApiUploadAction.h"

@implementation ZCApiUploadAction

- (BOOL)isValidMultiObjectUploadAction {
    BOOL flag = NO;
    NSInteger dataArrayCount = [self.dataArray count];
    if ([self.dataArray count] > 0) {
        if (dataArrayCount == [self.uploadNameArray count] && dataArrayCount == [self.fileNameArray count] && [self.mimeTypeArray count] > 0) {
            flag = YES;
        }
    }
    return flag;
}

@end
