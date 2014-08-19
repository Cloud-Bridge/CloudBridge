//
//  CBRCloudBridgeTests.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge.h>

#import "CBRTestCase.h"
#import "CBRTestConnection.h"

@interface CBRCloudBridgeTests : CBRTestCase
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) CBRTestConnection *connection;
@end

@implementation CBRCloudBridgeTests

- (void)setUp
{
    [super setUp];

    self.connection = [[CBRTestConnection alloc] init];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection coreDataStack:[CBRTestDataStore sharedInstance]];
    [NSManagedObject setCloudBridge:self.cloudBridge];
}

- (void)testThatManagedObjectReturnsGlobalCloudBridge
{
    expect([NSManagedObject cloudBridge]).to.equal(self.cloudBridge);
}

- (void)testThatSubclassesOverrideGlobalCloudBridge
{
    CBRCloudBridge *otherCloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection coreDataStack:[CBRTestDataStore sharedInstance]];
    expect(otherCloudBridge).toNot.equal(self.cloudBridge);

    [SLEntity4 setCloudBridge:otherCloudBridge];

    expect([NSManagedObject cloudBridge]).to.equal(self.cloudBridge);
    expect([SLEntity4 cloudBridge]).to.equal(otherCloudBridge);

    [SLEntity4 setCloudBridge:nil];
    expect([SLEntity4 cloudBridge]).to.equal(self.cloudBridge);
}

- (void)testThatBackendCreatesManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";

    self.connection.objectsToReturn = @[ @{@"identifier": @1337} ];
    [self.cloudBridge createManagedObject:entity withCompletionHandler:NULL];
    expect(entity.identifier).will.equal(1337);
}

- (void)testThatBackendUpdatesManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": entity.identifier, @"string": @"bla" } ];
    [self.cloudBridge saveManagedObject:entity withCompletionHandler:NULL];

    expect(entity.string).will.equal(@"bla");
}

- (void)testThatBackendReloadsManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": entity.identifier, @"string": @"bla" } ];
    [self.cloudBridge reloadManagedObject:entity withCompletionHandler:NULL];

    expect(entity.string).will.equal(@"bla");
}

- (void)testThatBackendDeletesManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    [self.cloudBridge deleteManagedObject:entity withCompletionHandler:NULL];
    expect(entity.isDeleted).will.beTruthy();
}

- (void)testThatConnectionFetchesObjectsForRelationship
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([SLEntity6Child class]) inManagedObjectContext:self.context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];

    [self.cloudBridge fetchManagedObjectsOfType:entityDescription.name withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
}

@end
