//
//  MapManager.h
//  TrackingLineDemo
//
//  Created by wf on 2019/1/15.
//  Copyright © 2019 wf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "CLLocationManager+blocks.h"


@interface MapManager : NSObject
@property (nonatomic,weak)UIViewController *controller;///<传进来的controller
@property (nonatomic,strong) MKMapView *mapview;///<地图视图
@property (nonatomic,strong) CLLocation *currentLocation;///<当前定位
@property (nonatomic,strong) CLLocationManager *locationManager;///<定位管理器

//初始化单例管理员对象
+(instancetype)sharedManager;
//初始化地图
-(void)initMapView;
- (void)initMapViewWithController:(UIViewController *)controller;
//获取当前定位，只会返回一次
- (void)getLastLocation:(void (^)(CLLocation *location, NSString *address))location;

//打开定位
- (void)showOpenLocationSetting;
@end

