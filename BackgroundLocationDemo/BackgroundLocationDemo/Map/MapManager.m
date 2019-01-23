//
//  MapManager.m
//  TrackingLineDemo
//
//  Created by wf on 2019/1/15.
//  Copyright © 2019 wf. All rights reserved.
//

#import "MapManager.h"

typedef void(^LocationBlock)(CLLocation *location, NSString *address);
@interface MapManager ()<MKMapViewDelegate>
@property (nonatomic,copy) LocationBlock locationBlock;///<本类block
@property (nonatomic,strong) CLLocation *lastLocation;///<记录上一次的定位

@end
@implementation MapManager
+ (instancetype)sharedManager{
    static MapManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MapManager alloc] init];
    });
    return instance;
}
- (void)initMapView{
    if (self.controller) {
        [self initMapViewWithController:self.controller];
    }
}

//提供mapview给外部使用，需要自己在外部设置frame
- (void)initMapViewWithController:(UIViewController *)controller{
    self.mapview = [[MKMapView alloc] initWithFrame:CGRectZero];
    //添加到controller
    [controller.view addSubview:self.mapview];
    //进来就定位的开启方法
    self.mapview.showsUserLocation = YES;
    self.mapview.userTrackingMode = MKUserTrackingModeFollow;
    //设置地图缩放比例，显示区域
    self.mapview.delegate = self;
    self.mapview.zoomEnabled = YES;
    [self.mapview setRegion:(MKCoordinateRegionMakeWithDistance(self.currentLocation.coordinate, 5000,5000)) animated:YES];
    //设置定位为中心点
    self.mapview.centerCoordinate = self.currentLocation.coordinate;
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    [self.mapview setRegion:(MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000,1000)) animated:YES];
}

- (void)getLastLocation:(void (^)(CLLocation *, NSString *))location{
    //精度80米，时间1秒
    self.locationManager = [CLLocationManager updateManagerWithAccuracy:80.0 locationAge:1.0 authorizationDesciption:CLLocationUpdateAuthorizationDescriptionAlways];
    self.locationBlock = location;
    if ([CLLocationManager isLocationUpdatesAvailable]) {
        __weak typeof(self)weakself = self;
        [self.locationManager startUpdatingLocationWithUpdateBlock:^(CLLocationManager *manager, CLLocation *location, NSError *error, BOOL *stopUpdating) {
            NSLog(@"定位信息为: %@", location);
            *stopUpdating = YES;
            weakself.currentLocation = location;
            [weakself reGeoCoding];
        }];
    }
    else{//没有就开启定位
        [self showOpenLocationSetting];
    }
}
//开启定位权限设置
- (void)showOpenLocationSetting{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"打开定位开关"
                                                                   message:@"请点击设置打开定位服务"
                                                            preferredStyle:(UIAlertControllerStyleAlert)];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [[NSURL alloc] initWithString:UIApplicationOpenSettingsURLString];
        
        if ([[UIDevice currentDevice].systemVersion doubleValue] > 10.0) {
            [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionsSourceApplicationKey : @YES}  completionHandler:^(BOOL success) {
                //这里不能直接开启定时器，会有坑
            }];
        }
        else{
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }]];
    
    [[self findCurrentViewController] presentViewController:alert animated:YES completion:nil];
}
#pragma mark 逆地理编码,经纬度编码成地址
-(void)reGeoCoding{
    if (self.currentLocation) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            // 判断反编码是否成功
            if (error || 0 == placemarks.count) {
                NSLog(@"erroe = %@, placemarks.count = %lu", error, placemarks.count);
            } else {
                // 反编码成功（找到了具体的位置信息）
                // 显示最前面的地标信息
                CLPlacemark *firstPlacemark = [placemarks firstObject];
                
                NSString *address = [NSString stringWithFormat:@"%@%@%@",firstPlacemark.locality, firstPlacemark.subLocality,firstPlacemark.name];
                
                if (self.locationBlock) {
                    self.locationBlock(self.currentLocation, address);
                }
            }
        }];
    }
}
#pragma mark --地址编码成经纬度
-(void)GeocodingWithAddress:(NSString *)address{

}

#pragma mark --当前最顶层vc
- (UIViewController *)findCurrentViewController
{
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    UIViewController *topViewController = [window rootViewController];
    
    while (true) {
        
        if (topViewController.presentedViewController) {
            
            topViewController = topViewController.presentedViewController;
            
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)topViewController topViewController]) {
            
            topViewController = [(UINavigationController *)topViewController topViewController];
            
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
            
        } else {
            break;
        }
    }
    return topViewController;
}

@end
