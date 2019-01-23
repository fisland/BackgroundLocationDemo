//
//  BgTask.m
//  myHome
//
//  Created by wf on 2019/1/21.
//  Copyright © 2019 zhangxiang. All rights reserved.
//

#import "BgTask.h"
@interface BgTask()
@property (nonatomic,strong) NSMutableArray *bgTaskIdList;///<后台任务数组
@property (assign) UIBackgroundTaskIdentifier  masterTaskId;///<当前后台任务ID
@end

@implementation BgTask
+ (instancetype)shareBgTask{
    static dispatch_once_t onceToken;
    static BgTask *task;
    dispatch_once(&onceToken, ^{
        task = [[BgTask alloc] init];
    });
    return task;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bgTaskIdList = @[].mutableCopy;
        self.masterTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}

//开启新的后台任务
-(UIBackgroundTaskIdentifier)beginNewBackgroundTask
{
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTaskId = UIBackgroundTaskInvalid;
    if([application respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)])
    {
        bgTaskId = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"bgTask 过期 %lu",(unsigned long)bgTaskId);
            [self.bgTaskIdList removeObject:@(bgTaskId)];//过期任务从后台数组删除
            bgTaskId = UIBackgroundTaskInvalid;
            [application endBackgroundTask:bgTaskId];
        }];
    }
    //如果上次记录的后台任务已经失效了，就记录最新的任务为主任务
    if (_masterTaskId == UIBackgroundTaskInvalid) {
        self.masterTaskId = bgTaskId;
        NSLog(@"开启后台任务 %lu",(unsigned long)bgTaskId);
    }
    else //如果上次开启的后台任务还未结束，就提前关闭了，使用最新的后台任务
    {
        //add this id to our list
        NSLog(@"保持后台任务 %lu", (unsigned long)bgTaskId);
        [self.bgTaskIdList addObject:@(bgTaskId)];
        [self endBackGroundTask:NO];//留下最新创建的后台任务
    }
    
    return bgTaskId;
}
/**
 *
 @param all : yes 关闭所有 ,no 只留下主后台任务
 all:yes 为了去处多余残留的后台任务，只保留最新的创建的
 *
 **/
-(void)endBackGroundTask:(BOOL)all
{
    UIApplication *application = [UIApplication sharedApplication];
    //如果为all 清空后台任务数组
    //不为all 留下数组最后一个后台任务,也就是最新开启的任务
    if ([application respondsToSelector:@selector(endBackGroundTask:)]) {
        for (int i = 0; i < (all ? _bgTaskIdList.count :_bgTaskIdList.count -1); i++) {
            UIBackgroundTaskIdentifier bgTaskId = [self.bgTaskIdList[0]integerValue];
            NSLog(@"关闭后台任务 %lu",(unsigned long)bgTaskId);
            [application endBackgroundTask:bgTaskId];
            [self.bgTaskIdList removeObjectAtIndex:0];
        }
    }
    ///如果数组大于0 所有剩下最后一个后台任务正在跑
    if(self.bgTaskIdList.count > 0)
    {
        NSLog(@"后台任务正在保持运行 %ld",(long)[_bgTaskIdList[0]integerValue]);
    }
    if(all)
    {
        [application endBackgroundTask:self.masterTaskId];
        self.masterTaskId = UIBackgroundTaskInvalid;
    }
    else
    {
        NSLog(@"kept master background task id %lu", (unsigned long)self.masterTaskId);
    }
}
@end


