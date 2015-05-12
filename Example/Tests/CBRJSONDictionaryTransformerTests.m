//
//  CBRJSONDictionaryTransformerTests.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 10.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge/CloudBridge.h>
#import <CBRRESTConnection/CBRRESTConnection.h>

#import "CBRTestCase.h"
#import "CBRTestDataStore.h"

@interface CBRJSONDictionaryTransformerTests : CBRTestCase
@property (nonatomic, strong) CBRJSONDictionaryTransformer *transformer;
@property (nonatomic, strong) CBRCloudBridge *cloudBridge;
@property (nonatomic, strong) CBRRESTConnection *connection;
@property (nonatomic, strong) CBRCoreDataDatabaseAdapter *adapter;
@end

@implementation CBRJSONDictionaryTransformerTests

- (void)setUp
{
    [super setUp];

    CBRUnderscoredPropertyMapping *propertyMapping = [[CBRUnderscoredPropertyMapping alloc] init];
    [propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    self.transformer = [[CBRJSONDictionaryTransformer alloc] initWithPropertyMapping:propertyMapping];
    self.connection = [[CBRRESTConnection alloc] initWithBaseURL:[NSURL URLWithString:@"http://google.de"] propertyMapping:propertyMapping];
    self.adapter = [[CBRCoreDataDatabaseAdapter alloc] initWithCoreDataStack:[CBRTestDataStore testStore]];
    self.cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:self.connection databaseAdapter:self.adapter];

    [NSManagedObject setCloudBridge:self.cloudBridge];
}

#pragma mark - NSManagedObject => NSDictionary convertion

- (void)testThatManagedObjectConvertsItselfIntoAnJSONObject
{
    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    JSONEntity1 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([JSONEntity1 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @1;
    entity.string = @"maFooBar";
    entity.date = now;
    entity.floatNumber = @3.5f;
    entity.dictionary = @{ @"key": @"value" };

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);



    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @3.5f,
                                 @"string": @"maFooBar",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    expect([self.transformer cloudObjectFromPersistentObject:entity]).to.equal(dictionary);
}

- (void)testThatManagedObjectConvertsItselfIntoAnJSONObjectWithJSONObjectKeyPaths
{
    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    JSONEntity1 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([JSONEntity1 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @1;
    entity.string = @"maFooBar";
    entity.date = now;
    entity.floatNumber = @3.5f;
    entity.dictionary = @{ @"key": @"value" };
    entity.otherString = @"otherString";

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @3.5f,
                                 @"string": @"maFooBar",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" },
                                 @"some_dictionary": @{
                                         @"string_value": @"otherString"
                                         }
                                 };

    expect([self.transformer cloudObjectFromPersistentObject:entity]).to.equal(dictionary);
}

#pragma mark - NSDictionary => NSManagedObject conversion

- (void)testThatUpdatedObjectWithRawJSONDictionaryCreatesNewInstancesIfNonAlreadyExist
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @1;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @2,
                                 @"float_number": @1337,
                                 @"string": @"blubb",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(newEntity).toNot.beNil();
    expect(newEntity).toNot.equal(entity);

    expect(newEntity.identifier).to.equal(2);
    expect(newEntity.floatNumber).to.equal(@1337);
    expect(newEntity.string).to.equal(@"blubb");
    expect(newEntity.date.timeIntervalSince1970).to.equal(now.timeIntervalSince1970);
    expect(newEntity.dictionary).to.equal(dictionary[@"dictionary"]);
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryCallsUpdateWithRawJSONDictionary
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @1;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @2,
                                 @"float_number": @1337,
                                 @"string": @"blubb",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(newEntity).toNot.beNil();
    expect(newEntity).toNot.equal(entity);
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryUpdatesAnExistingInstances
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @9;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @9,
                                 @"float_number": @1337,
                                 @"string": @"blubb",
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();

    expect(newEntity.identifier).to.equal(9);
    expect(newEntity.floatNumber).to.equal(@1337);
    expect(newEntity.string).to.equal(@"blubb");
    expect(newEntity.date.timeIntervalSince1970).to.equal(now.timeIntervalSince1970);
    expect(newEntity.dictionary).to.equal(dictionary[@"dictionary"]);
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryDoesntTouchValuesWhichAreNotBeingUpdates
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @8;
    entity.string = @"maFooBar";

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @8,
                                 @"float_number": @1337,
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();

    expect(newEntity.string).to.equal(@"maFooBar");
}

- (void)testThatUpdatedObjectWithRawJSONDictionaryClearesValuesForNullUpdates
{
    SLEntity5 *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    entity.identifier = @1;
    entity.string = @"maFooBar";

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @1337,
                                 @"string": [NSNull null],
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(newEntity).toNot.beNil();
    expect(newEntity).to.equal(entity);
    expect(newEntity == entity).to.beTruthy();

    expect(newEntity.string).to.beNil();
}

- (void)testThatManagedObjectDoesntUpdateWithoutIdentifier
{
    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"float_number": @1337,
                                 @"string": [NSNull null],
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" }
                                 };

    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];
    expect(newEntity).to.beNil();
}

- (void)testThatManageObjectUpdatesWithJSONObjectKeyPaths
{
    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];

    NSDate *now = [NSDate date];
    NSString *stringValue = [self.transformer.dateFormatter stringFromDate:now];
    now = [self.transformer.dateFormatter dateFromString:stringValue];

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @1337,
                                 @"string": [NSNull null],
                                 @"date": stringValue,
                                 @"dictionary": @{ @"key": @"value" },

                                 @"some_dictionary": @{
                                         @"string_value": @"wuff"
                                         }
                                 };

    SLEntity5 *newEntity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];
    expect(newEntity.otherString).to.equal(@"wuff");
}

- (void)testThatManagedObjectUpdatesOneToOneRelationshipsWithJSONObjectIdentifier
{
    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];

    SLEntity5Child1 *child = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5Child1 class])
                                                           inManagedObjectContext:self.context];
    child.identifier = @5;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"child_id": @5
                                 };

    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];
    expect(entity.child).to.equal(child);
}

- (void)testThatManagedObjectUpdatesOneToOneRelationshipsWithJSONObject
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"child": @{ @"id": @6 }
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];
    expect(entity.child.identifier).to.equal(6);
}

- (void)testThatManagedObjectUpdatesOneToManyRelationshipsWithJSONObject
{
    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5Child3 class]];

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"parent": @{ @"id": @5 }
                                 };

    SLEntity5Child3 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.parent.identifier).to.equal(5);
    expect(entity.parent.toManyChilds).to.contain(entity);
}

- (void)testThatManagedObjectUpdatesOneToManyRelationshipsWithJSONObjectIdentifier
{
    SLEntity5 *parent = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([SLEntity5 class])
                                                      inManagedObjectContext:self.context];
    parent.identifier = @5;

    NSError *saveError = nil;
    [self.context save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"parent_id": @5
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5Child3 class]];
    SLEntity5Child3 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.parent).to.equal(parent);
    expect(parent.toManyChilds).to.contain(entity);
}

- (void)testThatToManyRelationGetsUpdatedWhenJSONObjectContainsAnArray
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"to_many_childs": @[ @{ @"id": @1 }, @{ @"id": @2 } ]
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.toManyChilds.count).to.equal(2);

    SLEntity5Child3 *child1 = [SLEntity5Child3 objectWithRemoteIdentifier:@1 inManagedObjectContext:self.context];
    SLEntity5Child3 *child2 = [SLEntity5Child3 objectWithRemoteIdentifier:@2 inManagedObjectContext:self.context];

    expect(child1).toNot.beNil();
    expect(child2).toNot.beNil();

    expect(entity.toManyChilds).to.contain(child1);
    expect(entity.toManyChilds).to.contain(child2);
}

- (void)testThatToManyRelationGetsUpdatedWhenJSONObjectContainsAnArrayAndRelationshipIsRegisteredWithAttributeMapping
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"camelizedChilds": @[ @{ @"id": @1 } ]
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.camelizedChilds.count).to.equal(1);

    SLEntity5Child5 *child1 = [SLEntity5Child5 objectWithRemoteIdentifier:@1 inManagedObjectContext:self.context];

    expect(child1).toNot.beNil();
    expect(entity.camelizedChilds).to.contain(child1);
}

- (void)testThatToManyRelationGetsUpdatedWhenJSONObjectContainsAnArrayAndChildEntityHasDifferentUniqueIdentifier
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"differentChilds": @[ @{ @"foo_id": @1 } ]
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.differentChilds.count).to.equal(1);

    SLEntity5Child6 *child1 = [SLEntity5Child6 objectWithRemoteIdentifier:@1 inManagedObjectContext:self.context];

    expect(child1).toNot.beNil();
    expect(entity.differentChilds).to.contain(child1);
}

- (void)testThatUpdatedObjectHasSTICorrectSubclass
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"float_number": @13371338,
                                 @"string": @"maFooBar"
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.class).to.equal([SLEntity5Subclass class]);
}

- (void)testThatRestPrefixGetsAppliedForNewCloudObjects
{
    PrefixedEntitiy *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([PrefixedEntitiy class])
                                                            inManagedObjectContext:self.context];
    entity.identifier = @1;
    entity.name = @"foo";

    NSDictionary *cloudObject = [self.transformer cloudObjectFromPersistentObject:entity];
    NSDictionary *expectedResult = @{ @"prefix": @{
                                              @"id": @1,
                                              @"name": @"foo",
                                              }};
    expect(cloudObject).to.equal(expectedResult);
}

- (void)testThatManagedObjectGetsUpdatedWithPrefix
{
    NSDictionary *cloudObject = @{ @"prefix": @{
                                           @"id": @1,
                                           @"name": @"foo",
                                           }};

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[PrefixedEntitiy class]];
    PrefixedEntitiy *managedObject = [self.transformer persistentObjectFromCloudObject:cloudObject forEntity:entityDescription];

    expect(managedObject.identifier).to.equal(1);
    expect(managedObject.name).to.equal(@"foo");
}

- (void)testThatRelationshipGetsIncluded
{
    NSDictionary *dictionary = @{
                                 @"id": @1,
                                 @"camelizedChilds": @[ @{ @"id": @1 } ]
                                 };

    CBREntityDescription *entityDescription = [self.adapter entityDescriptionForClass:[SLEntity5 class]];
    SLEntity5 *entity = [self.transformer persistentObjectFromCloudObject:dictionary forEntity:entityDescription];

    expect(entity.camelizedChilds.count).to.equal(1);

    NSDictionary *result = [self.transformer cloudObjectFromPersistentObject:entity];
    expect(result[@"camelizedChilds"]).to.equal(dictionary[@"camelizedChilds"]);
}

@end
