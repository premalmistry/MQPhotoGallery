//
//  AppDelegate.m
//  MQPhotoGallery
//
//  Created by Premal Mistry on 12/9/14.
//  Copyright (c) 2014 Premal Mistry. All rights reserved.
//

#import "AppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark -
#pragma mark - Application life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self setupDBSession];
    
    return YES;
}

#pragma mark -
#pragma mark - Dropbox Setup

// Setup Dropbox session
- (void) setupDBSession {
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:@"1b7z8qvtujr8saq"
                            appSecret:@"hoas9ywrrdqvh4g"
                            root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation {
    
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
        }
        return YES;
    }

    // Should we notify user of this error message, perhaps an alert ?
    return NO;
}

@end
