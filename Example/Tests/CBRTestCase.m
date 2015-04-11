//
//  CBRTest.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestCase.h"
@import CloudBridge;

@implementation CBRTestCase

- (void)setUp
{
    [super setUp];
    _context = [CBRTestDataStore sharedStore].mainThreadManagedObjectContext;
}

- (void)tearDown
{
    [super tearDown];
    [[CBRTestDataStore sharedStore] wipeAllData];
}

@end
