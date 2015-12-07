//
//  CBRRESTConnectionTests.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 10.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CBRRESTConnection/CBRRESTConnection.h>

#import "CBRTestCase.h"
#import "CBRTestDataStore.h"
#import <OCMock/OCMock.h>

typedef void(^AFSuccessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void(^AFErrorBlock)(NSURLSessionDataTask *task, NSError *error);

@interface AFQueryDescription : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) id parameters;
@property (nonatomic, copy) AFSuccessBlock successBlock;
@property (nonatomic, copy) AFErrorBlock errorBlock;
@end

@implementation AFQueryDescription @end


@interface OCMStubRecorder (CBRRESTConnectionTests)

#define andQuery(aBlock) _andQuery(aBlock)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andQuery)(void (^)(AFQueryDescription *query));

@end

@implementation OCMStubRecorder (CBRRESTConnectionTests)

- (OCMStubRecorder *(^)(void (^)(AFQueryDescription *query)))_andQuery
{
    id (^theBlock)(void (^)(AFQueryDescription *query)) = ^ (void (^ blockToCall)(AFQueryDescription *query))
    {
        return [self andDo:^(NSInvocation *invocation) {
            AFQueryDescription *query = [[AFQueryDescription alloc] init];

            __unsafe_unretained NSString *path = nil;
            __unsafe_unretained id parameters = nil;
            __unsafe_unretained AFSuccessBlock successBlock = nil;
            __unsafe_unretained AFErrorBlock errorBlock = nil;

            [invocation getArgument:&path atIndex:2];
            [invocation getArgument:&parameters atIndex:3];
            [invocation getArgument:&successBlock atIndex:4];
            [invocation getArgument:&errorBlock atIndex:5];

            query.path = path;
            query.parameters = parameters;
            query.successBlock = successBlock;
            query.errorBlock = errorBlock;

            blockToCall(query);
        }];
    };
    return theBlock;
}

@end

@interface CBRRESTConnectionTests : CBRTestCase
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPSessionManager *mockedSessionManager;

@property (nonatomic, strong) CBRRESTConnection *connection;
@property (nonatomic, strong) CBRCoreDataDatabaseAdapter *adapter;
@end

@implementation CBRRESTConnectionTests

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

    self.connection = [[CBRRESTConnection alloc] initWithPropertyMapping:propertyMapping sessionManager:self.mockedSessionManager];
    self.adapter = [[CBRCoreDataDatabaseAdapter alloc] initWithCoreDataStack:[CBRTestDataStore testStore]];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection databaseAdapter:self.adapter];

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

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity6Child class]];

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

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity6Child class]];

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
