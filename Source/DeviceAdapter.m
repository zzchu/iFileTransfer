//
//  DeviceAdapter.m
//  mobileDeviceManager
//
//  Created by Taras Kalapun on 12.01.11.
//  Copyright 2011 Ciklum. All rights reserved.
//

#import "DeviceAdapter.h"


@implementation DeviceAdapter

@synthesize iosDevices;

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
        self.iosDevices = [NSMutableArray array];
        [[MobileDeviceAccess singleton] setListener:self];
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    self.iosDevices = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark MobileDeviceAccessListener

- (void)deviceConnected:(AMDevice*)device
{
	
    [self.iosDevices addObject: device];
    
    /*
	AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:@"com.lexcycle.stanza"];
	NSLog(@"app dir : %@", appDir);
	
	NSArray *files = [appDir directoryContents:@"/Documents"];
	NSLog(@"app dir files: %@", files);
	
	[appDir copyLocalFile:@"/desktop.p12" toRemoteDir:@"/Documents"];
	
	files = [appDir directoryContents:@"/Documents"];
	NSLog(@"app dir files: %@", files);
    */
}

- (void)deviceDisconnected:(AMDevice*)device
{
    AMDevice* d = [self getDeviceForId: device.udid];
    if(d)
    {
        [self.iosDevices removeObject: d];
    }
}

- (AMDevice*)getDeviceForId:(NSString*)deviceId
{
    for (AMDevice* d in self.iosDevices) {
        if([deviceId isEqualToString:d.udid])
            return d;
    }
    return NULL;
}

- (BOOL)isDeviceConnected {
    
    if ([self.iosDevices count] > 0) return YES;
    
    return NO;
}

@end
