//
//  LiveTrackManager.m
//  
//
//  Created by Arjan on 13/03/15.
//  Copyright (c) 2015 Auxilium. All rights reserved.
//

#import "LiveTrackManager.h"
#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"

@interface LiveTrackManager () <CLLocationManagerDelegate>
@property (nonatomic, strong) NSTimer *liveTrackStopLatentStartActiveTimer;
@property (nonatomic, strong) NSTimer *liveTrackStopActiveStartLatentTimer;
@property (nonatomic, strong) CLLocation *bestLocation;

// DEBUG
@property (nonatomic, strong) NSURLSession *sharedURLSession;
@end

@implementation LiveTrackManager

#pragma mark - Initialization
+ (instancetype)sharedManager
{
    static id shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareManager = [[self alloc] init];
    });
    return shareManager;
}

-(instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.pausesLocationUpdatesAutomatically = NO;
        }
    });
    return _locationManager;
}

#pragma mark - Start/Stop Tracking
-(void)startTracking
{
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    
    CLLocationManager *locationManager = [[self class] sharedLocationManager];
    if ([self conditionsMetForLocationManager:locationManager]) {
        [self switchToTrackingType:LiveTrackTrackingTypeActive locationManager:locationManager];
        [locationManager startUpdatingLocation];
    }
}

-(void)stopTracking
{
    // Stop all tracking and invalidate timers
    CLLocationManager *locationManager = [[self class] sharedLocationManager];
    [self.liveTrackStopActiveStartLatentTimer invalidate];
    self.liveTrackStopActiveStartLatentTimer = nil;
    [self.liveTrackStopLatentStartActiveTimer invalidate];
    self.liveTrackStopLatentStartActiveTimer = nil;
    [locationManager stopUpdatingLocation];
}



#pragma mark - Change tracking
-(void)switchTrackingType:(NSTimer *)timer {
    NSDictionary *userInfo = timer.userInfo;
    CLLocationManager *locationManager = [[self class] sharedLocationManager];
    NSString *trackingTypeToSwitchTo = [userInfo valueForKeyPath:TRACKINGTYPE_NAME];
    if ([trackingTypeToSwitchTo isEqualToString:LATENT]) {
        // Stop actively tracking the location, and stop receiving delegate calls for locationManager
        [self switchToTrackingType:LiveTrackTrackingTypeLatent locationManager:locationManager];
        NSLog(@"locationManager stopped active tracking after %f seconds", kLiveTrackUpdateTimeout);
        
        // Invalide the timer, will be populated again once the first location is found,
        // after self.liveTrackStopLatentStartActiveTimer has fired.
        [self.liveTrackStopActiveStartLatentTimer invalidate];
        self.liveTrackStopActiveStartLatentTimer = nil;
        
        // Optionally send data to the server
        //[self createUpdateForLocation:self.bestLocation];
        
        // Plan active livetracking again after x seconds
        self.liveTrackStopLatentStartActiveTimer = [NSTimer scheduledTimerWithTimeInterval:kLiveTrackUpdateInterval target:self
                                                                                  selector:@selector(switchTrackingType:)
                                                                                  userInfo: @{ TRACKINGTYPE_NAME : ACTIVE }
                                                                                   repeats:NO];
    } else if ([trackingTypeToSwitchTo isEqualToString:ACTIVE])
    {
        // Stop and invalidate the timer, will be set again the next time we switch to LATENT location updates
        [self.liveTrackStopLatentStartActiveTimer invalidate];
        self.liveTrackStopLatentStartActiveTimer = nil;
        
        // Start actively tracking the location, which will be automatically stopped after x seconds
        [self switchToTrackingType:LiveTrackTrackingTypeActive locationManager:locationManager];
    }
}

-(void)switchToTrackingType:(LiveTrackTrackingType)trackingType locationManager:(CLLocationManager *)locationManager
{
    if (trackingType == LiveTrackTrackingTypeActive) {
        NSLog(@"ARLiveTrackManager switching to active tracking");
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        locationManager.delegate = self;
    } else if (trackingType == LiveTrackTrackingTypeLatent) {
        NSLog(@"ARLiveTrackManager switching to latent tracking");
        locationManager.delegate = nil;
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        locationManager.distanceFilter = CLLocationDistanceMax;
        locationManager.pausesLocationUpdatesAutomatically = YES;
        
    }
}



#pragma mark - CLLocationManager Delegate Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //[((AppDelegate *)[UIApplication sharedApplication].delegate) runDidReceiveRemoteNotificationFetchCompletionHandler];
    NSLog(@"locationManager didUpdateLocations");
    
    for(int i=0;i<locations.count;i++){
        CLLocation * location = [locations objectAtIndex:i];
        CLLocationCoordinate2D locationCoordinate = location.coordinate;
        CLLocationAccuracy locationAccuracy = location.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[location.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
            continue;
        
        //Select only valid location and also location with good accuracy
        if(location!=nil&&locationAccuracy>0
           &&locationAccuracy<ACCURACY_MAX_NUMBER_OF_METERS
           &&(!(locationCoordinate.latitude==0.0&&locationCoordinate.longitude==0.0))) {
            
           self.bestLocation = location;
        }
    }
    
    if (self.liveTrackStopActiveStartLatentTimer) {
        return;
    }

    self.liveTrackStopActiveStartLatentTimer = [NSTimer scheduledTimerWithTimeInterval:kLiveTrackUpdateTimeout target:self
                                                                              selector:@selector(switchTrackingType:)
                                                                              userInfo: @{ TRACKINGTYPE_NAME : LATENT }
                                                                              repeats:NO];
    NSLog(@"locationManager will stop updating after %f seconds", kLiveTrackUpdateTimeout);
    //NSTimeInterval remaining = [UIApplication sharedApplication].backgroundTimeRemaining;
    //DLog(@"%f",remaining);
}



#pragma mark - API Connection / Update save methods
-(void)createUpdateForLocation:(CLLocation *)location {
    NSString *urlString = @"";
    if (DEBUG && [urlString length]) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        int batteryLevel = (int)([[UIDevice currentDevice] batteryLevel] * 100);
        NSString * params = [NSString stringWithFormat:@"lat=%f&lng=%f&accuracy=%f&batterylevel=%d", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy, batteryLevel];
        [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSession *session = self.sharedURLSession;
        NSURLSessionDownloadTask *task;
        task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if ((([httpResponse statusCode]/100) == 2)) {
                self.bestLocation = nil;
            } else if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
        [task resume];
    }
}



#pragma mark NSURLSession
-(NSURLSession *)sharedURLSession {
    if (!_sharedURLSession) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _sharedURLSession = [NSURLSession sessionWithConfiguration:configuration];
    }
    return _sharedURLSession;
}



#pragma mark - Conditions and authorizations
-(BOOL)conditionsMetForLocationManager:(CLLocationManager *)locationManager {
    // We're usually in the background when this happens, so no possibility to show an alert.
    // But below code is checked elsewhere as well, when on screen.
    
    // Onderstaande wordt op gecheckt in de app maar kan theoretisch uitgezet zijn terwijl de app in de achtergrond draait
    if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
        return NO;
    }
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if (authorizationStatus != kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"authorizationStatus failed");
        return NO;
    } else if ([[UIApplication sharedApplication] backgroundRefreshStatus] != UIBackgroundRefreshStatusAvailable) {
        NSLog(@"backgroundRefreshStatus failed");
        return NO;
    }
    return YES;
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    // Theoretically possible
    if (status != kCLAuthorizationStatusAuthorizedAlways) {
        [self stopTracking];
    }
}

- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
    switch([error code])
    {
        // TODO
        case kCLErrorNetwork: // general, network-related error
        case kCLErrorDenied: // User turned off location
        default:
            [self stopTracking];
            break;
    }
}
@end
