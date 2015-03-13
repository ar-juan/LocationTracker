//
//  AppDelegate.m
//  LocationTracker
//
//  Created by Arjan on 13/03/15.
//  Copyright (c) 2015 Auxilium. All rights reserved.
//

#import "AppDelegate.h"
#import "LiveTrackManager.h"
@import CoreLocation;

@interface AppDelegate ()
@property (nonatomic, strong) LiveTrackManager *liveTrackManager;
@property (nonatomic, strong) CLLocationManager *keepAppAliveLocationManager;
@end

@implementation AppDelegate

-(CLLocationManager *)keepAppAliveLocationManager {
    if (!_keepAppAliveLocationManager) {
        _keepAppAliveLocationManager = [[CLLocationManager alloc] init];
    }
    return _keepAppAliveLocationManager;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.liveTrackManager = [LiveTrackManager sharedManager];
    [self.keepAppAliveLocationManager startMonitoringSignificantLocationChanges];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Just to show that it can start while in the background, and run indefinitely
    [self.liveTrackManager startTracking];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Just to show that it can start while in the background, and run indefinitely until stopped
    [self.liveTrackManager stopTracking];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.liveTrackManager stopTracking];
    [self.keepAppAliveLocationManager stopMonitoringSignificantLocationChanges];
}

@end
