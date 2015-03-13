//
//  LiveTrackManager.h
//
//
//  Created by Arjan on 13/03/15.
//  Copyright (c) 2015 Auxilium. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LiveTrackTrackingType) {
    LiveTrackTrackingTypeActive,
    LiveTrackTrackingTypeLatent
};

const float kLiveTrackUpdateInterval = 110.f;
const float kLiveTrackUpdateTimeout = 10.f;

#define TRACKINGTYPE_NAME @"TRACKINGTYPE_NAME"
#define ACTIVE @"ACTIVE"
#define LATENT @"LATENT"
#define ACCURACY_MAX_NUMBER_OF_METERS 2000

#define IS_OS_7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define ALERT(title,msg) [[[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show]

@interface LiveTrackManager : NSObject
+(instancetype)sharedManager;
-(void)startTracking;
-(void)stopTracking;
@end
