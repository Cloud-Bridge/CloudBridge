//
//  CBRTest.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestCase.h"

@implementation CBRTestCase

- (void)setUp
{
    [super setUp];
    _context = [CBRTestDataStore sharedInstance].mainThreadManagedObjectContext;
}

- (void)tearDown
{
    [super tearDown];
    [[CBRTestDataStore sharedInstance] wipeAllData];
}

@end
