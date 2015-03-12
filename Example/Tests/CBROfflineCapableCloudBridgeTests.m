//
//  CBROfflineCapableCloudBridge.m
//  CloudBridge
//
//  Created by Oliver Letterer on 21.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge/CloudBridge.h>

#import "CBRTestCase.h"
#import "CBRTestConnection.h"

@interface CBROfflineCapableCloudBridgeTests : CBRTestCase
@property (nonatomic, strong) CBROfflineCapableCloudBridge *cloudBridge;
@property (nonatomic, strong) CBRTestConnection *connection;
@end

@implementation CBROfflineCapableCloudBridgeTests

- (void)setUp
{
    [super setUp];

    self.connection = [[CBRTestConnection alloc] init];
    self.cloudBridge = [[CBROfflineCapableCloudBridge alloc] initWithCloudConnection:self.connection coreDataStack:[CBRTestDataStore sharedInstance]];
    [NSManagedObject setCloudBridge:self.cloudBridge];

    [self.cloudBridge setValue:@NO forKey:NSStringFromSelector(@selector(isRunningInOfflineMode))];
    __block BOOL called = NO;
    [self.cloudBridge reenableOnlineModeWithCompletionHandler:^(NSError *error) {
        called = YES;
    }];

    expect(called).will.beTruthy();
    NSParameterAssert(called == YES);
}

- (void)testThatCloudBridgeDoesntTouchOnlineEntity
{
    OnlyOnlineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OnlyOnlineEntity class]) inManagedObjectContext:self.context];

    self.connection.objectsToReturn = @[ @{@"identifier": @1337} ];

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge createManagedObject:entity withCompletionHandler:NULL];

    expect(entity.identifier).will.equal(1337);
}

- (void)testThatDeletingObjectRemovedLocalManagedObject
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.hasPendingCloudBridgeChanges = @YES;

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge deleteManagedObject:entity withCompletionHandler:NULL];

    expect(entity.managedObjectContext).will.beNil();
}

- (void)testThatDeletingObjectSetPendingDeletionFlag
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.identifier = @5;
    entity.hasPendingCloudBridgeChanges = @YES;

    self.connection.errorToReturn = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];
    [self.cloudBridge deleteManagedObject:entity withCompletionHandler:NULL];

    expect(entity.hasPendingCloudBridgeDeletion.boolValue).will.beTruthy();
    expect(entity.hasPendingCloudBridgeChanges.boolValue).to.beFalsy();
}

- (void)testThatSavingObjectSetsChangesFlagInOfflineMode
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge saveManagedObject:entity withCompletionHandler:NULL];

    expect(entity.hasPendingCloudBridgeChanges.boolValue).will.beTruthy();
}

- (void)testThatSavingObjectSetsChangesFlagInOnline
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    self.connection.errorToReturn = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil];
    [self.cloudBridge saveManagedObject:entity withCompletionHandler:NULL];

    expect(entity.hasPendingCloudBridgeChanges.boolValue).will.beTruthy();
}

- (void)testThatDisablingOfflineModeDeletesPreviousManagedObjects
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.identifier = @5;
    entity.hasPendingCloudBridgeDeletion = @YES;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    self.connection.objectsToReturn = @[
                                        [[CBRDeletedObjectIdentifier alloc] initWithCloudIdentifier:@5 entitiyName:entity.entity.name],
                                        ];

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge reenableOnlineModeWithCompletionHandler:NULL];

    expect(entity.isDeleted).will.beTruthy();
}

- (void)testThatDisablingOfflineModeCreatesPendingCloudObjects
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.hasPendingCloudBridgeChanges = @YES;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    self.connection.objectsToReturn = @[
                                        @{ @"identifier": @5 },
                                        ];

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge reenableOnlineModeWithCompletionHandler:NULL];

    expect(entity.identifier).will.equal(5);
}

- (void)testThatDisablingOfflineModeSavePendingCloudObjects
{
    OfflineEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OfflineEntity class]) inManagedObjectContext:self.context];
    entity.identifier = @5;
    entity.hasPendingCloudBridgeChanges = @YES;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    self.connection.objectsToReturn = @[
                                        @{ @"identifier": @6 },
                                        ];

    [self.cloudBridge enableOfflineMode];
    [self.cloudBridge reenableOnlineModeWithCompletionHandler:NULL];

    expect(entity.identifier).will.equal(6);
}

@end
