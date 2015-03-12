//
//  CBRTest.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <CloudBridge/CloudBridge.h>
#import "CBRTestDataStore.h"



@interface CBRTestCase : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end
