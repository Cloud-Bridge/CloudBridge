//
//  CBRTest.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestCase.h"
#import "CBRTestDataStore.h"

@implementation CBRTestCase

- (void)setUp
{
    [super setUp];
    _context = [CBRCoreDataStack testStore].mainThreadManagedObjectContext;
}

- (void)tearDown
{
    [super tearDown];
    [[CBRCoreDataStack testStore] wipeAllData];
}

@end
