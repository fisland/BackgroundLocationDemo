//
//  BgTask.h
//  myHome
//
//  Created by wf on 2019/1/21.
//  Copyright © 2019 zhangxiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BgTask : NSObject
//单例后台管理器
+ (instancetype)shareBgTask;
//开启新的后台任务
- (UIBackgroundTaskIdentifier)beginNewBackgroundTask;
@end
