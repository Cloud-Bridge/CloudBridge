//
//  CBRViewController.m
//  CloudBridge
//
//  Created by Oliver Letterer on 01/01/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import "CBRViewController.h"

@interface CBRViewController ()

@end



@implementation CBRViewController

#pragma mark - setters and getters

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - View lifecycle

//- (void)loadView
//{
//    [super loadView];
//
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - Private category implementation ()

@end
