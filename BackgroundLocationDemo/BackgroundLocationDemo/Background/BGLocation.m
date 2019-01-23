//
//  BGLocation.m
//  myHome
//
//  Created by wf on 2019/1/21.
//  Copyright © 2019 zhangxiang. All rights reserved.
//

#import "BGLocation.h"
#import "BgTask.h"
#import "MapManager.h"
#import "BgDispatchTimer.h"

@interface BGLocation ()
@property (nonatomic,strong) BgTask *bgTask;///<后台任务
@property (nonatomic,strong) MapManager *mapManager;///<地图管理器
@property (nonatomic,strong) NSMutableArray <NSString *> *upLocations;///<上传的地址数组

@property (nonatomic,strong) CLLocation *lastLocation;///<x最后定位点
@property (nonatomic,assign) BOOL isConfig;///<是否配置过

@end
@implementation BGLocation

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bgTask = [BgTask shareBgTask];
        self.mapManager = [MapManager sharedManager];
        //不移动也定位，不然长后台会挂
        self.mapManager.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.mapManager.locationManager.allowsBackgroundLocationUpdates = YES;
        self.mapManager.locationManager.pausesLocationUpdatesAutomatically = NO;
        self.mapManager.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        
        self.upLocations = @[].mutableCopy;
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationEnterfontground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

//开启定位和定时器，外部开启
- (void)initConfigTimerAndLocation{
    self.isConfig = YES;
    [self startLocation];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self saveLocationTimer];
    [self uploadLocationsToServer];
}

//开启上传定时器
- (void)uploadLocationsToServer{
    //半小时上传 1800
    [BgDispatchTimer scheduleDispatchTimerWithName:@"UpLoad" timeInterval:1800 queue:nil repeats:YES action:^{
        if (self.upLocations.count > 0) {
            //这里上传
        }
    }];
}
//开启保存定位定时器
- (void)saveLocationTimer{
    //120秒后重启定位 2分钟存一下
    [BgDispatchTimer scheduleDispatchTimerWithName:@"saveLocation" timeInterval:10 queue:nil repeats:YES action:^{
        //开启定位
        [self startLocation];
    }];
}

//监听进入前台方法
- (void)applicationEnterfontground{
    //先判断是否配置过了
    if (self.isConfig) {
        return;
    }
    //判断是否开启定位权限
    if ([CLLocationManager isLocationUpdatesAvailable]) {
        [self initConfigTimerAndLocation];
    }
}

//监听进入后台方法
- (void)applicationEnterBackground{
    NSLog(@"come in background");
    [self startLocation];
}

//重新开启定位
- (void)startLocation{
    __weak typeof(self)WeakSelf = self;
    //要在主线程，不然定位不回调
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapManager getLastLocation:^(CLLocation *location, NSString *address) {
            __strong typeof(self)self = WeakSelf;
            [self saveLocationWithinfo:location addderes:address];
        }];
    });
    //开启新的后台任务
    [self.bgTask beginNewBackgroundTask];
}

- (void)saveLocationWithinfo:(CLLocation *)location addderes:(NSString *)address{
    //保存定位
    NSLog(@"尝试保存定位");
    //判断两点之间不能少于50米
    //if (self.lastLocation && [self.lastLocation distanceFromLocation:location] < 50) {
    //    return;
    //}
    ////判断速度不能大于28m/s
    //if (location.speed > 28) {
    //    return;
    //}
    //code 保存到数据库,这个先用数组保存一下
    NSLog(@"当前定位%@",address);
    NSLog(@"正在保存定位");

    [self.upLocations addObject:address];
    //最后设置
    self.lastLocation = location;
}

@end

