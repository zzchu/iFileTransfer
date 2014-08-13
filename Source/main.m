//
//  main.m
//  mobileDeviceManager
//
//  Created by Taras Kalapun on 12.01.11.
//  Copyright 2011 Ciklum. All rights reserved.
//  SVN: http://slim@svn.dev.iccoss.com/repos/trunk/Mac/mobile_device_manager/
//

#import <Foundation/Foundation.h>
#import "DeviceAdapter.h"
#import "MobileDeviceAccess.h"

int main (int argc, const char * argv[]) {

    //NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    
    //get arguments
	NSUserDefaults *arguments = [NSUserDefaults standardUserDefaults];
	NSString *option = [arguments stringForKey:@"o"];
    
    if	(!option) {
        printf("\n\
The script usage:\n\n\
Copy file from desktop to device (App Documents) or specify path with filename:\n\
    iFileTransfer -o copy -id \"Device_ID\"  -app \"Application_ID\" -from \"from file\" [-to \"to file\"]\n\
download file from device to MAC:\n\
    iFileTransfer -o download -id \"Device_ID\" -app \"Application_ID\" -from \"from file\" -to \"to file\"\n\
List Applications:\n\
    iFileTransfer -o list -id \"Device_ID\"\n\
List Files in Application Documents (path):\n\
    iFileTransfer -o listFiles -id \"Device_ID\" -app Appliction_ID [-path /Documents]\n\
Get appId for application name:\n\
    iFileTransfer -o getAppId -id \"Device_ID\" -name Application_Name\n\
Show device info:\n\
    iFileTransfer -o info -id \"Device_ID\"\n");
        return 1001;
	}
    
    DeviceAdapter *adapter = [[DeviceAdapter alloc] init];
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    
    if(![adapter isDeviceConnected]) {
        NSLog(@"No device detected!");
        return 1001;
    }
    
    NSString *deviceId = [arguments stringForKey:@"id"];
    AMDevice *device = nil;
    if(deviceId.length > 0)
        device = [adapter getDeviceForId: deviceId];
    else
        device = adapter.iosDevices.lastObject;
    
    if ([option isEqualToString:@"download"]) {
        NSLog(@"Will download file from Device: %@", device);
        
        NSString *fromFile = [arguments stringForKey:@"from"];
        NSString *toFile = [arguments stringForKey:@"to"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!fromFile || !appId || !toFile) {
            NSLog(@"no fromFile | no appId | no toFile");
            return 1001;
        }
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isdir;
        isdir = NO;
        
        if (NO == [appDir fileExistsAtPath:fromFile isDirectory:&isdir]) {
            NSLog(@"the source :%@ isn't exist", fromFile);
            return 1001;
        }
        if (isdir == YES)
        {
            if ([fm fileExistsAtPath:toFile isDirectory:&isdir] && isdir) {
                
                //download the folder content
                NSArray *files = [appDir recursiveDirectoryContents:fromFile];
                
                for (NSString *filePath in files) {
                    NSError *error;
                    [appDir fileExistsAtPath:filePath isDirectory:&isdir];
                    
                    //Get the target file path
                    NSArray *fromFileComponents = [fromFile pathComponents];
                    NSArray *filePathComponents = [filePath pathComponents];
                    NSArray *toFileComponents = [toFile pathComponents];
                    
                    NSUInteger commonComponentNum = [fromFileComponents count]-1;
                    NSUInteger arrayCapacity = [filePathComponents count] + [toFileComponents count];
                    NSMutableArray *finalComponents = [NSMutableArray arrayWithCapacity:arrayCapacity];
                    
                    [finalComponents addObjectsFromArray:toFileComponents];
                    [finalComponents addObjectsFromArray:[filePathComponents subarrayWithRange:NSMakeRange(commonComponentNum, [filePathComponents count]-commonComponentNum)]];
                    NSString *toFileFullPath = [NSString pathWithComponents:finalComponents];
                    
                    if (isdir == YES) {
                        if (NO == [fm createDirectoryAtPath:toFileFullPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                            NSLog(@"create directory:%@ failed!", toFileFullPath);
                        };
                    }
                    else
                    {
                        if ([fm fileExistsAtPath:toFileFullPath]) {
                            //remove the old file
                            NSError *error;
                            
                            BOOL success = [fm removeItemAtPath:toFileFullPath error:&error];
                            if (!success) NSLog(@"Error: %@", [error localizedDescription]);
                        }
                        
                        if (YES == [appDir copyRemoteFile:filePath toLocalFile:toFileFullPath])
                        {
                            NSLog(@"download file:%@ successfully!", filePath);
                        }
                        else
                        {
                            NSLog(@"download failed!");
                            return 1001;
                        }
                    }
                }
            }
            else
            {
                NSLog(@"Error:the target folder :%@ is uncorrect!", toFile);
                return 1001;
            }
        }
        else //the fromFile is a file not a folder
        {
        if ([fm fileExistsAtPath:toFile isDirectory:&isdir]) {
            if (isdir) {
                if (YES == [appDir copyRemoteFile:fromFile toLocalDir:toFile])
                {
                    NSLog(@"download successfully!");
                }
                else
                {
                    NSLog(@"download failed!");
                    return 1001;
                }
                
            }
            else
            {
                long suffixCount = 0;
                NSString *newToFile;
                NSString *suffix;
                
                do {
                    suffixCount ++;
                    suffix = [NSString stringWithFormat:@"(%ld)", suffixCount] ;
                    newToFile = [toFile stringByAppendingString:suffix];
 
                } while ([fm fileExistsAtPath:newToFile]);
                
                if (YES == [appDir copyRemoteFile:fromFile toLocalFile:newToFile])
                {
                    NSLog(@"download successfully!");
                }
                else
                {
                    NSLog(@"download failed!");
                    return 1001;
                }
            }
        }
        else
        {
            if (YES == [appDir copyRemoteFile:fromFile toLocalFile:toFile])
            {
                NSLog(@"download successfully!");
            }
            else
            {
                NSLog(@"download failed!");
                return 1001;
            }

        }
        }
        
    } else if ([option isEqualToString:@"copy"]) {
        NSLog(@"Will copy to Device: %@", device);
        
        NSString *fromFile = [arguments stringForKey:@"from"];
        NSString *toFile = [arguments stringForKey:@"to"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!fromFile || !appId) {
            NSLog(@"no fromFile | no appId");
            return 1001;
        }
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        NSArray *files = [appDir directoryContents:@"/Documents"];
        NSLog(@"app Documents files: %@", files);
        
        if (!toFile) {
            [appDir copyLocalFile:fromFile toRemoteDir:@"/Documents"];
        } else {
            [appDir copyLocalFile:fromFile toRemoteFile:toFile];
        }
        
        files = [appDir directoryContents:@"/Documents"];
        NSLog(@"app Documents files: %@", files);
        
    } else if ([option isEqualToString:@"listFiles"]) {
        
        NSString *path = [arguments stringForKey:@"path"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!appId) {
            NSLog(@"no appId");
            return 1001;
        }
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        if (!path) path = @"/Documents";

        NSArray *files = [appDir directoryContents:path];
        
        NSLog(@"Files in %@ : %@", path, files);
        
    } else if ([option isEqualToString:@"list"]) {
        NSArray *apps = [device installedApplications];
        NSLog(@"Installed Applications: %@", apps);

    } else if ([option isEqualToString:@"info"]) {
        NSLog(@"Device connected: %@", device);
    } else if ([option isEqualToString:@"getAppId"]) {
        NSString *appName = [arguments stringForKey:@"name"];
        NSArray *appList = [device installedApplications];
        for (AMApplication *app in appList) {
            if ([[app appname] isEqualToString:appName]) {
                NSString *appId = [app bundleid];
                printf("%s\n", [appId UTF8String]);
                break;
            }
            
        }
    }
    
    //[pool drain];
    return 0;
}

