//
//  CBRRESTConnectionTests.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 10.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge/CBRRESTConnection.h>

#import "CBRTestCase.h"
#import "CBRTestDataStore.h"
#import "OCMStubRecorder+Tests.h"

#import <OCMock/OCMock.h>

@interface CBRRESTConnection_CoreDataTests : CBRTestCase
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPSessionManager *mockedSessionManager;

@property (nonatomic, strong) CBRRESTConnection *connection;
@property (nonatomic, strong) CBRCoreDataInterface *adapter;
@property (nonatomic, strong) CBRThreadingEnvironment *environment;
@end

@implementation CBRRESTConnection_CoreDataTests

- (void)setUp
{
    [super setUp];

    CBRUnderscoredPropertyMapping *propertyMapping = [[CBRUnderscoredPropertyMapping alloc] init];
    [propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://localhost/v1"]];
    self.sessionManager.requestSerializer = [AFJSONRequestSerializer serializerWithWritingOptions:kNilOptions];
    self.sessionManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:kNilOptions];
    [self.sessionManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self.sessionManager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];

    self.mockedSessionManager = OCMPartialMock(self.sessionManager);

    __block __weak CBRCloudBridge *bridge = nil;
    self.connection = [[CBRRESTConnection alloc] initWithPropertyMapping:propertyMapping sessionManager:self.mockedSessionManager];
    self.adapter = [[CBRCoreDataInterface alloc] initWithStack:[CBRTestDataStore testStore]];
    self.environment = [[CBRThreadingEnvironment alloc] initWithCoreDataAdapter:self.adapter];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection interface:self.adapter threadingEnvironment:self.environment];
    bridge = self.cloudBridge;

    [NSManagedObject setCloudBridge:self.cloudBridge];
}

- (void)testThatConnectionPostsCloudObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";

    NSDictionary *parameters = [self.connection.objectTransformer cloudObjectFromPersistentObject:entity];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager POST:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    [self.connection createCloudObject:parameters forPersistentObject:entity withUserInfo:nil completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"entity4");
    expect(query.parameters).to.equal(parameters);
}

- (void)testThatConnectionSavesLatestCloudObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";
    entity.identifier = @5;

    NSDictionary *parameters = [self.connection.objectTransformer cloudObjectFromPersistentObject:entity];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager PUT:OCMOCK_ANY parameters:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    [self.connection saveCloudObject:parameters forPersistentObject:entity withUserInfo:nil completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"entity4/5");
    expect(query.parameters).to.equal(parameters);
}

- (void)testThatConnectionFetchesLatesCloudObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager GET:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    [self.connection latestCloudObjectForPersistentObject:entity withUserInfo:nil completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"entity4/5");
}

- (void)testThatConnectionDeletesManagedObject
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager DELETE:OCMOCK_ANY parameters:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    [self.connection deleteCloudObject:nil forPersistentObject:entity withUserInfo:nil completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"entity4/5");
}

- (void)testThatConnectionFetchesObjectsForRelationship
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    CBREntityDescription *entityDescription = self.adapter.entitiesByName[NSStringFromClass([SLEntity6Child class])];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager GET:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parent == %@", entity];
    [self.connection fetchCloudObjectsForEntity:entityDescription withPredicate:predicate userInfo:nil completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"entity6/5/children");
}

- (void)testThatConnectionFetchesObjectsFromAPath
{
    SLEntity6 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity6 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    CBREntityDescription *entityDescription = self.adapter.entitiesByName[NSStringFromClass([SLEntity6Child class])];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager GET:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: @"some_path/with_suffix" };
    [self.connection fetchCloudObjectsForEntity:entityDescription withPredicate:nil userInfo:userInfo completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"some_path/with_suffix");
}

- (void)testThatConnectionPostsCloudObjectToPath
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";

    NSDictionary *parameters = [self.connection.objectTransformer cloudObjectFromPersistentObject:entity];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager POST:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: @"some_path/:number" };
    [self.connection createCloudObject:parameters forPersistentObject:entity withUserInfo:userInfo completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"some_path/5");
    expect(query.parameters).to.equal(parameters);
}

- (void)testThatConnectionSavesCloudObjectToPath
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";
    entity.identifier = @5;

    NSDictionary *parameters = [self.connection.objectTransformer cloudObjectFromPersistentObject:entity];

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager PUT:OCMOCK_ANY parameters:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: @"some_path/:id" };
    [self.connection saveCloudObject:parameters forPersistentObject:entity withUserInfo:userInfo completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"some_path/5");
    expect(query.parameters).to.equal(parameters);
}

- (void)testThatConnectionFetchesLatesCloudObjectFromPath
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager GET:OCMOCK_ANY parameters:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: @"some_path/:id" };
    [self.connection latestCloudObjectForPersistentObject:entity withUserInfo:userInfo completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"some_path/5");
}

- (void)testThatConnectionDeletesManagedObjectToPath
{
    SLEntity4 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity4 class]) inManagedObjectContext:self.context];
    entity.identifier = @5;

    __block AFQueryDescription *query = nil;
    OCMStub([self.mockedSessionManager DELETE:OCMOCK_ANY parameters:OCMOCK_ANY success:OCMOCK_ANY failure:OCMOCK_ANY]).andQuery(^(AFQueryDescription *theQuery) {
        query = theQuery;
    });

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: @"some_path/:id" };
    [self.connection deleteCloudObject:nil forPersistentObject:entity withUserInfo:userInfo completionHandler:NULL];

    expect(query).willNot.beNil();
    expect(query.path).to.endWith(@"some_path/5");
}

@end
