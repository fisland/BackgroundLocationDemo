//
//  BgDispatchTimer.m
//  myHome
//
//  Created by wf on 2019/1/21.
//  Copyright © 2019 zhangxiang. All rights reserved.
//

#import "BgDispatchTimer.h"
//声明静态数组
static NSMutableDictionary *timeContainer;

@implementation BgDispatchTimer
+ (void)initialize{
    timeContainer = [NSMutableDictionary dictionary];
}

//执行命令
+ (void)scheduleDispatchTimerWithName:(NSString *)timerName
                         timeInterval:(double)interval
                                queue:(dispatch_queue_t)queue
                              repeats:(BOOL)repeats
                               action:(dispatch_block_t)action{
    if (nil == timerName) {
        return;
    }
    
    if (nil == queue) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    
    dispatch_source_t timer = [timeContainer objectForKey:timerName];
    
    if (nil == timer) {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        [timeContainer setObject:timer forKey:timerName];
        
        //执行timer 一定放在这里 放下面会造成野地址
        dispatch_resume(timer);
    }
    
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC);
    dispatch_source_set_timer(timer, start, interval * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        action();
        if (!repeats) {
            [weakSelf cancelTimerWithName:timerName];
        }
    });
}

+ (void)cancelTimerWithName:(NSString *)timerName{
    dispatch_source_t timer = [timeContainer objectForKey:timerName];
    if (nil == timer) {
        return;
    }
    [timeContainer removeObjectForKey:timer];
    dispatch_source_cancel(timer);
}

+ (void)cancelAllTimer{
    [timeContainer enumerateKeysAndObjectsUsingBlock:^(NSString * key, dispatch_source_t timer, BOOL * _Nonnull stop) {
        [timeContainer removeObjectForKey:key];
        dispatch_source_cancel(timer);
    }];
}
@end
