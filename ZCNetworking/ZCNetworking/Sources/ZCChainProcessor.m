//
//  ZCChainProcessor.m
//  ZCNetworking
//
//  Created by charles on 16/6/5.
//  Copyright © 2016年 charles. All rights reserved.
//

#import "ZCChainProcessor.h"
#import "ZCApiRunner.h"

@interface ZCChainProcessor ()

@property (nonatomic, strong) NSArray<ZCApiAction *> *actions;
@property (nonatomic, assign) NSInteger              currentIndex;
@property (nonatomic, strong) NSMutableDictionary    *resultDict;
@property (nonatomic, copy)   ZCDictBlock            success;
@property (nonatomic, copy)   ZCErrorBlock           failure;

@end

@implementation ZCChainProcessor

- (instancetype)initWithActions:(NSArray<ZCApiAction *> *)actions {
    if (self = [super init]) {
        _actions = actions;
        _resultDict = @{}.mutableCopy;
        [self addObserver:self forKeyPath:@"currentIndex" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (_currentIndex > 0 && _currentIndex < _actions.count) {
        [self runActions];
    }
}

- (NSError *)valiedate {
    if (_actions.count == 0) {
        return [NSError errorWithDomain:@"No Actions" code:-500 userInfo:nil];
    }
    
    if (_currentIndex < 0 || _currentIndex > _actions.count - 1) {
        return [NSError errorWithDomain:@"Inner Error" code:600 userInfo:nil];
    }
    
    return nil;
}

- (void)startWithSuccess:(ZCDictBlock)success failure:(ZCErrorBlock)failure {
    _success = success;
    _failure = failure;
    
    NSError *error = [self valiedate];
    if (!error) {
        [self runActions];
    }
    else {
        !failure ? : failure(error);
    }
}

- (void)runActions {
    ZCApiAction *action = _actions[_currentIndex];
    __weak typeof(self) weakSelf = self;
    [[ZCApiRunner sharedInstance] runAction:action success:^(id object) {
        weakSelf.resultDict[@(weakSelf.currentIndex)] = object;
        if (weakSelf.currentIndex == weakSelf.actions.count - 1) {
            !weakSelf.success? : weakSelf.success(weakSelf.resultDict);
        }
        else {
            weakSelf.currentIndex++;
        }
    } failure:^(NSError *error) {
        !weakSelf.failure ? : weakSelf.failure(error);
    }];
}

@end
