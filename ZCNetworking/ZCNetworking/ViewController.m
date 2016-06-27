//
//  ViewController.m
//  ZCNetworking
//
//  Created by charles on 16/4/15.
//  Copyright © 2016年 charles. All rights reserved.
//

#import "ViewController.h"
#import "ZCApiLauncher.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    //在app delegate里面设置比较好,任意地点设置也没问题,不过需要在调用api之前设置
    [[ZCApiRunner sharedInstance] startWithDebugDomain:@"http://api.budejie.com/" releaseDomain:@"http://api.budejie.com/"];
    
//    可以要可以不要
//    [self globleSettings];
    

    [self nomarlActionTest];
//    [self uploadActionTest];
}

#pragma mark - 使用说明

/**
 *  一切全局的设置,可有可没有.
    一般api会返回一个code表示api逻辑是否成功.
    如果有设置了codekey,则需要设置成功code.当api返回时,会根据code key和success code的设置进行判定进入success还是failure回调
    是否成功仅仅依赖success codes,不依赖warning codes.
    对于一些全局的warning codes,可以设置handler.比如登录失效,可以设置一个handler进行登录.
 */
- (void)globleSettings {
    [[ZCApiRunner sharedInstance] codeKey:@"code"];
    [[ZCApiRunner sharedInstance] successCodes:@[@"0"]];
    [[ZCApiRunner sharedInstance] warningReturnCodes:@[@"-1"] withHandler:^(NSString *code) {
        if ([code isEqualToString:@"-1"]) {
            //做自己的操作,例如登录等
        }
    }];
}

/**
 *  api from 百思不得姐,随时失效.请用有效的api进行测试
    这是普通的api请求,获取数据.ZCApiAction中有更多的属性可以设置.
 */
- (void)nomarlActionTest {
    ZCApiAction *action = [[ZCApiAction alloc] initWithURL:@"api/api_open.php"];
    //参数
    action.params[@"a"] = @"user_login_report";
    action.params[@"appname"] = @"baisishequ";
    action.params[@"c"] = @"user";
    action.params[@"client"] = @"iphone";
    
    //可选属性
    action.showLog = YES;
    action.actionWillInvokeBlock = ^{
        NSLog(@"will start");
    };
    
    action.actionDidInvokeBlock = ^(BOOL isSuccess) {
        if (isSuccess) {
            NSLog(@"success");
        }
        else {
            NSLog(@"failure");
        }
    };
    
    [[ZCApiRunner sharedInstance] runAction:action success:^(id object) {
        
    } failure:^(NSError *error) {
        
    }];
}

/**
 *  没有相关的api,只能做个使用示例
 */
- (void)uploadActionTest {
    ZCApiUploadAction *action = [[ZCApiUploadAction alloc] initWithURL:@"xxx"];
    //参数,同普通action一样
    action.params[@""] = @"";
    
    //根据上传任务调整timeout
    action.timeout = 300;
    
    //上传必要参数,由server端提供
    action.data = [NSData data];
    action.fileName = @"xxx";
    action.uploadName = @"xxx";
    action.mimeType = @"xxx";
    
    /*
     如果是多data上传(例如一个身份证上传api,需要上传身份证正反面)
     可以使用数组形式的参数,不过单个data上传和多个data上传需要互斥
     并且多个data上传,需要统一,也就是data/filename/uploadname/mimetype的数组数量一致
     因为是通过index来进行匹配的.
     */
//    action.dataArray = @[];
//    action.uploadNameArray = @[];
//    action.fileNameArray = @[];
//    action.mimeTypeArray = @[];
    
    [[ZCApiRunner sharedInstance] uploadAction:action progress:nil success:^(id object) {
        
    } failure:^(NSError *error) {
        
    }];
}

@end
