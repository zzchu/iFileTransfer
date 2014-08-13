//
//  DeviceAdapter.h
//  mobileDeviceManager
//
//  Created by Taras Kalapun on 12.01.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileDeviceAccess.h"

@class DeviceAdapter;

/*
@protocol
@optional
- (void)deviceConnected:(AMDevice *)device;
@end
*/

@interface DeviceAdapter : NSObject 
<MobileDeviceAccessListener>
{
    NSMutableArray *iosDevices;
}

@property (nonatomic, retain) NSMutableArray *iosDevices;

- (BOOL)isDeviceConnected;

- (AMDevice*)getDeviceForId:(NSString*)deviceId;

@end
