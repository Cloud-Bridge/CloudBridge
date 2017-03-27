//
//  CBRCloudBridgeTests.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge/CloudBridge.h>

#import "CBRTestCase.h"
#import "CBRTestDataStore.h"
#import "CBRTestConnection.h"

@interface CBRCloudBridge_CoreDataTests : CBRTestCase
@property (nonatomic, strong) CBRCoreDataDatabaseAdapter *adapter;
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) CBRTestConnection *connection;
@end

@implementation CBRCloudBridge_CoreDataTests

- (void)setUp
{
    [super setUp];

    self.connection = [[CBRTestConnection alloc] init];
    self.adapter = [[CBRCoreDataDatabaseAdapter alloc] initWithCoreDataStack:[CBRTestDataStore testStore]];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection databaseAdapter:self.adapter];
    [NSManagedObject setCloudBridge:self.cloudBridge];
}

- (void)testInverseRelation
{
    CBREntityDescription *parent = [self.adapter entityDescriptionForClass:[SLEntity6 class]];
    CBREntityDescription *child = [self.adapter entityDescriptionForClass:[SLEntity6Child class]];

    expect(parent.relationshipsByName[@"children"].inverseRelationship.name).to.equal(@"parent");
    expect(child.relationshipsByName[@"parent"].inverseRelationship.name).to.equal(@"children");
}

- (void)testThatManagedObjectReturnsGlobalCloudBridge
{
    expect([NSManagedObject cloudBridge]).to.equal(self.cloudBridge);
}

- (void)testThatSubclassesOverrideGlobalCloudBridge
{
    CBRCloudBridge *otherCloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection databaseAdapter:self.adapter];
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
    [self.cloudBridge createPersistentObject:entity withCompletionHandler:NULL];
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
    [self.cloudBridge savePersistentObject:entity withCompletionHandler:NULL];

    expect(entity.string).will.equal(@"bla");
}

- (void)testThatBackendReloadsManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": entity.identifier, @"string": @"bla" } ];
    [self.cloudBridge reloadPersistentObject:entity withCompletionHandler:NULL];

    expect(entity.string).will.equal(@"bla");
}

- (void)testThatBackendDeletesManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    [self.cloudBridge deletePersistentObject:entity withCompletionHandler:NULL];
    expect(entity.isDeleted).will.beTruthy();
}

- (void)testThatConnectionFetchesObjectsForRelationship
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[SLEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
}

- (void)testThatConnectionDeletesEveryOtherObjectWhenFetchingObjectsForRelationship
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    SLEntity6Child *child = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6Child class]) inManagedObjectContext:self.context];
    child.identifier = @5;
    entity.children = [NSSet setWithObject:child];

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[SLEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
    expect(entity.children).toNot.contain(child);
    expect(child.isDeleted).to.beTruthy();
}

- (void)testThatConnectionOnlyDeletesEveryOtherObjectFromTheRelationshipWhenFetchingObjectsForRelationship
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    SLEntity6Child *child = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6Child class]) inManagedObjectContext:self.context];
    child.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[SLEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
    expect(entity.children).toNot.contain(child);
    expect(child.isDeleted).to.beFalsy();
}

@end
