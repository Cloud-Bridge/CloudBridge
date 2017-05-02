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
#import "CBRTestConnection.h"

#import "RLMEntity4.h"
#import "RLMEntity6.h"

@interface CBRCloudBridge_RealmTests : CBRTestCase
@property (nonatomic, strong) CBRRealmInterface *adapter;
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) CBRTestConnection *connection;
@property (nonatomic, strong) CBRThreadingEnvironment *environment;
@end

@implementation CBRCloudBridge_RealmTests

- (void)setUp
{
    [super setUp];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.inMemoryIdentifier = self.testRun.test.name;
    config.objectClasses = @[ RLMEntity4.class, RLMEntity6.class, RLMEntity6Child.class ];

    self.connection = [[CBRTestConnection alloc] init];
    self.adapter = [[CBRRealmInterface alloc] initWithConfiguration:config];
    self.environment = [[CBRThreadingEnvironment alloc] initWithRealmAdapter:self.adapter];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection interface:self.adapter threadingEnvironment:self.environment];

    [CBRRealmObject setCloudBridge:self.cloudBridge];

    assert([self.adapter assertClassesExcept:nil]);
}

- (void)testInverseRelation
{
    CBREntityDescription *parent = self.adapter.entitiesByName[NSStringFromClass([RLMEntity6 class])];
    CBREntityDescription *child = self.adapter.entitiesByName[NSStringFromClass([RLMEntity6Child class])];

    expect(parent.relationshipsByName[@"children"].inverseRelationship.name).to.equal(@"parent");
    expect(child.relationshipsByName[@"parent"].inverseRelationship.name).to.equal(@"children");
}

- (void)testTransformableAttributes
{
    CBREntityDescription *entity = self.adapter.entitiesByName[NSStringFromClass([RLMEntity4 class])];
    expect(entity).toNot.beNil();

    expect(entity.attributesByName[@"array"]).toNot.beNil();
    expect(entity.attributesByName[@"array"].type).to.equal(CBRAttributeTypeTransformable);
    expect(entity.attributesByName[@"array_Data"]).to.beNil();
}

- (void)testThatManagedObjectReturnsGlobalCloudBridge
{
    expect([CBRRealmObject cloudBridge]).to.equal(self.cloudBridge);
}

- (void)testThatSubclassesOverrideGlobalCloudBridge
{
    CBRCloudBridge *otherCloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection interface:self.adapter threadingEnvironment:self.environment];
    expect(otherCloudBridge).toNot.equal(self.cloudBridge);

    [RLMEntity4 setCloudBridge:otherCloudBridge];

    expect([CBRRealmObject cloudBridge]).to.equal(self.cloudBridge);
    expect([RLMEntity4 cloudBridge]).to.equal(otherCloudBridge);

    [RLMEntity4 setCloudBridge:nil];
    expect([RLMEntity4 cloudBridge]).to.equal(self.cloudBridge);
}

- (void)testThatBackendCreatesManagedObject
{
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
    entity.identifier = @5;

    self.connection.objectsToReturn = @[ @{ @"identifier": entity.identifier, @"string": @"bla" } ];
    [self.cloudBridge reloadPersistentObject:entity withCompletionHandler:NULL];

    expect(entity.string).will.equal(@"bla");
}

- (void)testThatBackendDeletesManagedObject
{
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
    entity.identifier = @5;

    [self.cloudBridge deletePersistentObject:entity withCompletionHandler:NULL];
    expect(entity.invalidated).will.beTruthy();
}

- (void)testThatConnectionFetchesObjectsForRelationship
{
    RLMEntity6 *entity = [[RLMEntity6 alloc] init];
    entity.identifier = @5;

    [self.adapter.realm transactionWithBlock:^{
        [self.adapter.realm addObject:entity];
    }];

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[RLMEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
}

- (void)testThatConnectionDeletesEveryOtherObjectWhenFetchingObjectsForRelationship
{
    RLMEntity6 *entity = [[RLMEntity6 alloc] init];
    entity.identifier = @5;

    RLMEntity6Child *child = [[RLMEntity6Child alloc] init];
    child.identifier = @5;
    child.parent = entity;

    [self.adapter.realm transactionWithBlock:^{
        [self.adapter.realm addObject:entity];
        [self.adapter.realm addObject:child];
    }];

    expect(child.invalidated).to.beFalsy();

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[RLMEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
    expect(entity.children).toNot.contain(child);
    expect(child.invalidated).to.beTruthy();
}

- (void)testThatConnectionOnlyDeletesEveryOtherObjectFromTheRelationshipWhenFetchingObjectsForRelationship
{
    RLMEntity6 *entity = [[RLMEntity6 alloc] init];
    entity.identifier = @5;

    RLMEntity6Child *child = [[RLMEntity6Child alloc] init];
    child.identifier = @5;

    [self.adapter.realm transactionWithBlock:^{
        [self.adapter.realm addObject:entity];
        [self.adapter.realm addObject:child];
    }];

    self.connection.objectsToReturn = @[ @{ @"identifier": @1 }, @{ @"identifier": @2 } ];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.cloudBridge fetchPersistentObjectsOfClass:[RLMEntity6Child class] withPredicate:predicate completionHandler:NULL];

    expect(entity.children).will.haveCountOf(2);
    expect(entity.children).toNot.contain(child);
    expect(child.invalidated).to.beFalsy();
}

@end
