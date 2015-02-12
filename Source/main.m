//
//  main.m
//  mobileDeviceManager
//
//  Created by Taras Kalapun on 12.01.11.
//  Copyright 2011 Ciklum. All rights reserved.
//  SVN: http://slim@svn.dev.iccoss.com/repos/trunk/Mac/mobile_device_manager/
//

//Ruling about the return value
// 0: iFileTransfer work successfully
// 0x01: iFileTransfer failed, and the failed cannot be recovered by re-run
// 0x02: iFileTransfer is unstable, you can re-run iFileTransfer to make it successful.

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
download file or directory from device to MAC:\n\
    iFileTransfer -o download -id \"Device_ID\" -app \"Application_ID\" -from \"from file or directory\" -to \"to file or directory\"\n\
delete file or directory from device:\n\
    iFileTransfer -o delete -id \"Device_ID\" -app \"Application_ID\" -target \"target file or directory\"\n\
List Applications:\n\
    iFileTransfer -o list -id \"Device_ID\"\n\
List Files in Application Documents (path):\n\
    iFileTransfer -o listFiles -id \"Device_ID\" -app Appliction_ID [-path /Documents]\n\
Get appId for application name:\n\
    iFileTransfer -o getAppId -id \"Device_ID\" -name Application_Name\n\
Get the version of iFileTransfer tool:\n\
    iFileTransfer -o version\n\
Show device info:\n\
    iFileTransfer -o info -id \"Device_ID\"\n");
        return 0x01;
	}

    DeviceAdapter *adapter = [[DeviceAdapter alloc] init];
RUN_AGAIN:
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    if(![adapter isDeviceConnected]) {
        NSLog(@"No device detected!");
        return 0x01;
    }
    NSString *deviceId = [arguments stringForKey:@"id"];
    AMDevice *device = nil;
    if(deviceId.length > 0)
        device = [adapter getDeviceForId: deviceId];
    else
        device = adapter.iosDevices.lastObject;
    
    if ([option isEqualToString:@"download"]) {
        
        NSString *fromFile = [arguments stringForKey:@"from"];
        NSString *toFile = [arguments stringForKey:@"to"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!fromFile || !appId || !toFile) {
            NSLog(@"no fromFile | no appId | no toFile");
            return 0x01;
        }
        
        NSLog(@"Will download file: %@ from Device: %@", fromFile, device);
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isdir;
        isdir = NO;
        
        if (NO == [appDir fileExistsAtPath:fromFile isDirectory:&isdir]) {
            NSLog(@"the source :%@ isn't exist", fromFile);
            return 0x01;
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
                            return 0x01;
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
                            //NSLog(@"download file:%@ successfully!", filePath);
                        }
                        else
                        {
                            NSLog(@"download failed and try it again!");
                            //return 0x02;
                            //[pool drain];
                            goto RUN_AGAIN;
                        }
                    }
                }
            }
            else
            {
                NSLog(@"Error:the target folder :%@ is uncorrect!", toFile);
                return 0x01;
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
                    return 0x01;
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
                    return 0x01;
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
                return 0x01;
            }

        }
        }
        
    } else if ([option isEqualToString:@"copy"]) {
        NSString *fromFile = [arguments stringForKey:@"from"];
        NSString *toFile = [arguments stringForKey:@"to"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!fromFile || !appId) {
            NSLog(@"no fromFile | no appId");
            return 0x01;
        }
        
        NSLog(@"Will upload file: %@ to Device: %@", fromFile, device);
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL isdir;
        isdir = NO;
        
        if (NO == [fm fileExistsAtPath:fromFile isDirectory:&isdir]) {
            NSLog(@"the source :%@ isn't exist", fromFile);
            return 0x01;
        }
        if (isdir == YES)
        {
            //NSArray* dirs = [fm subpathsOfDirectoryAtPath:fromFile error:NULL];
            if ([appDir fileExistsAtPath:toFile isDirectory:&isdir] && isdir) {
                
                //download the folder content
                NSArray *files = [fm subpathsOfDirectoryAtPath:fromFile error:NULL];

                if ([fromFile hasSuffix:@"/"] == NO) {
                    NSString *toDir = [toFile stringByAppendingPathComponent:[fromFile lastPathComponent]];
                    [appDir mkdir:toDir];
                }

                for (NSString *filePath in files) {

                    //Get the target file path
                    NSArray *fromFileComponents = [fromFile pathComponents];
                    NSArray *filePathComponents = [filePath pathComponents];
                    NSArray *toFileComponents = [toFile pathComponents];
                    
                    NSUInteger commonComponentNum = [fromFileComponents count]-1;
                    NSUInteger targetArrayCapacity = [filePathComponents count] + [toFileComponents count] + 1;
                    NSUInteger sourceArrayCapacity = [filePathComponents count] + [fromFileComponents count] + 1;
                    NSMutableArray *finalComponents = [NSMutableArray arrayWithCapacity:targetArrayCapacity];
                    NSMutableArray *sourceComponents = [NSMutableArray arrayWithCapacity:sourceArrayCapacity];
                    
                    [finalComponents addObjectsFromArray:toFileComponents];
                    [finalComponents addObjectsFromArray:[fromFileComponents subarrayWithRange:NSMakeRange(commonComponentNum, 1)]];
                    [finalComponents addObjectsFromArray:filePathComponents];
                    
                    [sourceComponents addObjectsFromArray:fromFileComponents];
                    [sourceComponents addObjectsFromArray:filePathComponents];
                    
                    NSString *toFileFullPath = [NSString pathWithComponents:finalComponents];
                    NSString *fromFileFullPath = [NSString pathWithComponents:sourceComponents];
                    
                    if ([fm fileExistsAtPath:fromFileFullPath isDirectory:&isdir] && isdir) {
                        if ((YES == [appDir fileExistsAtPath:toFileFullPath isDirectory:&isdir]) && (isdir==YES)) {
                            continue;
                        }
                        if (NO == [appDir mkdir:toFileFullPath]) {
                            NSLog(@"create directory:%@ failed and try it again!", toFileFullPath);
                            //return 0x02;
                            //[pool drain];
                            goto RUN_AGAIN;
                        };
                    }
                    else
                    {
                        if ((YES == [appDir fileExistsAtPath:toFileFullPath isDirectory:&isdir]) && (isdir==NO)) {
                            NSError *error;
                            BOOL success = [appDir unlink:toFileFullPath];
                            if (!success) NSLog(@"Error: %@", [error localizedDescription]);
                        }
                        
                        if (YES == [appDir copyLocalFile:fromFileFullPath toRemoteFile:toFileFullPath])
                        {
                            //NSLog(@"upload file to:%@ successfully!", toFileFullPath);
                        }
                        else
                        {
                            NSLog(@"upload file to:%@ failed and try it again!", toFileFullPath);
                            //return 0x02;
                            //[pool drain];
                            goto RUN_AGAIN;
                        }
                    }
                }
            }
            else
            {
                NSLog(@"Error:the target folder :%@ is uncorrect!", toFile);
                return 0x01;
            }

        }
        else
        {
            BOOL bRet;
//            NSArray *files = [appDir directoryContents:@"/Documents"];
//            NSLog(@"app Documents files: %@", files);
            
            if (!toFile) {
                bRet = [appDir copyLocalFile:fromFile toRemoteDir:@"/Documents"];
            } else {
                if ((YES == [appDir fileExistsAtPath:toFile isDirectory:&isdir]) && (isdir==NO)) {
                    bRet = YES;
                    NSLog(@"file:%@ alread exist", toFile);
                }
                else
                {
                    bRet = [appDir copyLocalFile:fromFile toRemoteFile:toFile];
                }
            }
            
            if (NO == bRet)
            {
                NSLog(@"upload file:%@ failed!", fromFile);
                return 0x01;
            }
            
//            files = [appDir directoryContents:@"/Documents"];
//            NSLog(@"app Documents files: %@", files);
        }
        
    }else if ([option isEqualToString:@"delete"]) {
        
        NSString *targetFile = [arguments stringForKey:@"target"];
        NSString *appId = [arguments stringForKey:@"app"];
        NSLog(@"Will delete:%@ from Device: %@", targetFile, device);
        
        if (!targetFile || !appId) {
            NSLog(@"no target file | no appId");
            return 0x01;
        }
        
        AFCApplicationDirectory *appDir = [device newAFCApplicationDirectory:appId];
        
        BOOL isdir;
//        NSArray *files = [appDir directoryContents:@"/Documents"];
//        NSLog(@"app Documents files: %@", files);
        
        //Delete the target diretory or file
        if( YES == [appDir fileExistsAtPath:targetFile isDirectory:&isdir] )
        {
            if(isdir)
            {
                NSArray *files = [appDir recursiveDirectoryContents:targetFile];
                NSArray* reversedArray = [[files reverseObjectEnumerator] allObjects];
                for (NSString *filePath in reversedArray) {
                    if (NO == [appDir unlink:filePath])
                    {
                        NSLog(@"remove path: %@ failed!!", filePath);
                        return 0x01;
                    }
                }
            }
            else {
                if (NO == [appDir unlink:targetFile] )
                {
                     NSLog(@"remove path: %@ failed!!", targetFile);
                    return 0x01;
                }
            }
        }
        else{
            NSLog(@"Can't find: %@", targetFile);
            return 0x01;
        }
        
//        files = [appDir directoryContents:@"/Documents"];
//        NSLog(@"app Documents files: %@", files);
        
    }else if ([option isEqualToString:@"listFiles"]) {
        
        NSString *path = [arguments stringForKey:@"path"];
        NSString *appId = [arguments stringForKey:@"app"];
        
        if (!appId) {
            NSLog(@"no appId");
            return 0x01;
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
    } else if ([option isEqualToString:@"version"]) {
        NSLog(@"version: 10.0.0");
        NSLog(@"main update: fix the crash issue when can't find connected device");
    }
    
    //[pool drain];
    NSLog(@"iFileTransfer done well!");
    return 0;
}

