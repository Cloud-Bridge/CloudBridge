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
#import <CloudBridge/CBRRealmInterface.h>

#import "CBRTestCase.h"
#import "OCMStubRecorder+Tests.h"

#import <OCMock/OCMock.h>

#import "RLMEntity4.h"
#import "RLMEntity6.h"

@interface CBRRESTConnection_RealmTests : CBRTestCase
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPSessionManager *mockedSessionManager;

@property (nonatomic, strong) CBRRESTConnection *connection;
@property (nonatomic, strong) CBRRealmInterface *adapter;
@property (nonatomic, strong) CBRThreadingEnvironment *environment;
@end

@implementation CBRRESTConnection_RealmTests

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

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.inMemoryIdentifier = self.testRun.test.name;
    configuration.objectClasses = @[ RLMEntity4.class, RLMEntity6.class, RLMEntity6Child.class ];

    __block __weak CBRCloudBridge *bridge = nil;
    self.connection = [[CBRRESTConnection alloc] initWithPropertyMapping:propertyMapping sessionManager:self.mockedSessionManager];
    self.adapter = [[CBRRealmInterface alloc] initWithConfiguration:configuration];
    self.environment = [[CBRThreadingEnvironment alloc] initWithRealmAdapter:self.adapter];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection interface:self.adapter threadingEnvironment:self.environment];
    bridge = self.cloudBridge;

    [CBRRealmObject setCloudBridge:self.cloudBridge];

    assert([self.adapter assertClassesExcept:nil]);
}

- (void)testThatConnectionPostsCloudObject
{
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
    entity.array = @[ @1, @2 ];
    entity.date = [NSDate date];
    entity.number = @5;
    entity.string = @"blubb";

    expect([entity valueForKey:@"array"]).to.beKindOf([NSArray class]);
    expect([entity valueForKey:@"array_Data"]).to.beKindOf([NSData class]);

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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity6 *entity = [[RLMEntity6 alloc] init];
    entity.identifier = @5;

    CBREntityDescription *entityDescription = self.adapter.entitiesByName[NSStringFromClass([RLMEntity6Child class])];

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
    RLMEntity6 *entity = [[RLMEntity6 alloc] init];
    entity.identifier = @5;

    CBREntityDescription *entityDescription = self.adapter.entitiesByName[NSStringFromClass([RLMEntity6Child class])];;

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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
    RLMEntity4 *entity = [[RLMEntity4 alloc] init];
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
