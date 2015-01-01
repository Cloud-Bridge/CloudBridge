//
//  CBRAppDelegate.m
//  CloudBridge
//
//  Created by CocoaPods on 01/01/2015.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import "CBRAppDelegate.h"
#import "CBRViewController.h"

@implementation CBRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[CBRViewController alloc] init] ];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
