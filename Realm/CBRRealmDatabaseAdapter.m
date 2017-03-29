/**
 CloudBridge
 Copyright (c) 2015 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import <Realm/Realm.h>
#import <objc/runtime.h>
#import "CBRRealmDatabaseAdapter.h"

#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"

#import "CBREntityDescription+Realm.h"

@implementation CBRRelationshipDescription (CBRRealmDatabaseAdapter)

- (void)_realmUpdateUserInfo
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:self.userInfo];
    NSDictionary *inverseUserInfo = self.inverseRelationship.userInfo;

    if (!userInfo[@"restBaseURL"] && inverseUserInfo[@"restBaseURL"]) {
        userInfo[@"restBaseURL"] = inverseUserInfo[@"restBaseURL"];
    }

    if (!userInfo[@"cloudBridgeCascades"] && inverseUserInfo[@"cloudBridgeCascades"]) {
        userInfo[@"cloudBridgeCascades"] = inverseUserInfo[@"cloudBridgeCascades"];
    }

    self.userInfo = userInfo;
    self.cascades = self.userInfo[@"cloudBridgeCascades"] != nil;
}

@end

@implementation CBRRealmObject (CBRPersistentObject)

#pragma mark - CBRPersistentObject

+ (CBRCloudBridge *)cloudBridge
{
    CBRCloudBridge *cloudBridge = objc_getAssociatedObject(self, @selector(cloudBridge));
    if (cloudBridge) {
        return cloudBridge;
    }

    if (self == [CBRRealmObject class]) {
        return nil;
    }

    return [[self superclass] cloudBridge];
}

+ (void)setCloudBridge:(CBRCloudBridge *)cloudBridge
{
    objc_setAssociatedObject(self, @selector(cloudBridge), cloudBridge, OBJC_ASSOCIATION_RETAIN);
}

- (CBRCloudBridge *)cloudBridge
{
    return [self.class cloudBridge];
}

+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [[self cloudBridge].databaseAdapter entityDescriptionForClass:self];
}

- (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self.class cloudBridgeEntityDescription];
}

#pragma mark - CBRPersistentObjectQueryInterface

+ (nullable instancetype)objectWithRemoteIdentifier:(id<CBRPersistentIdentifier>)identifier
{
    if (identifier == nil) {
        return nil;
    }

    CBREntityDescription *entityDescription = [[self cloudBridge].databaseAdapter entityDescriptionForClass:self];
    return (id)[[self cloudBridge].databaseAdapter persistentObjectOfType:entityDescription withPrimaryKey:identifier];
}

+ (NSDictionary<id<CBRPersistentIdentifier>, id> *)objectsWithRemoteIdentifiers:(NSArray<id<CBRPersistentIdentifier>> *)identifiers
{
    CBREntityDescription *entityDescription = [[self cloudBridge].databaseAdapter entityDescriptionForClass:self];
    NSString *attribute = [[self cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [[self cloudBridge].databaseAdapter indexedObjectsOfType:entityDescription withValues:[NSSet setWithArray:identifiers] forAttribute:attribute];
}

+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    [self.cloudBridge fetchPersistentObjectsOfClass:class withPredicate:predicate completionHandler:completionHandler];
}

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge createPersistentObject:self withCompletionHandler:completionHandler];
}

- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge reloadPersistentObject:self withCompletionHandler:completionHandler];
}

- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge savePersistentObject:self withCompletionHandler:completionHandler];
}

- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.cloudBridge deletePersistentObject:self withCompletionHandler:completionHandler];
}

#pragma mark - CBRPersistentObjectSubclassHooks

- (void)awakeFromCloudFetch
{

}

+ (id<CBRCloudObject>)prepareForUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{
    return cloudObject;
}

- (void)prepareForUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{

}

- (void)finalizeUpdateWithCloudObject:(id<CBRCloudObject>)cloudObject
{

}

- (id<CBRCloudObject>)finalizeCloudObject:(id<CBRCloudObject>)cloudObject
{
    return cloudObject;
}

- (void)setCloudValue:(id)value forKey:(NSString *)key fromCloudObject:(id<CBRCloudObject>)cloudObject
{
    [self setValue:value forKey:key];
}

- (id)cloudValueForKey:(NSString *)key
{
    return [self valueForKey:key];
}

#pragma mark - Convenience API

- (id<CBRCloudObject>)cloudObjectRepresentation
{
    return [self.cloudBridge.cloudConnection.objectTransformer cloudObjectFromPersistentObject:self];
}

- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    __assert_unused CBRRelationshipDescription *relationshipDescription = [self.cloudBridge.databaseAdapter entityDescriptionForClass:self.class].relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(!relationshipDescription.toMany);

    [self fetchObjectsForRelationship:relationship withCompletionHandler:^(NSArray *objects, NSError *error) {
        if (completionHandler) {
            completionHandler(objects.lastObject, error);
        }
    }];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler
{
    RLMProperty *relationshipDescription = self.realm.schema[[self.class className]][relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(relationshipDescription.objectClassName);
    NSParameterAssert(relationshipDescription.linkOriginPropertyName);

    RLMProperty *inverseRelationship = self.realm.schema[relationshipDescription.objectClassName][relationshipDescription.linkOriginPropertyName];
    NSParameterAssert(inverseRelationship.type == RLMPropertyTypeObject);

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", inverseRelationship.name, self];
    [self.cloudBridge fetchPersistentObjectsOfClass:NSClassFromString(inverseRelationship.objectClassName)
                                      withPredicate:predicate
                                  completionHandler:completionHandler];
}

+ (instancetype)persistentObjectFromCloudObject:(id<CBRCloudObject>)cloudObject
{
    CBREntityDescription *entity = [[self cloudBridge].databaseAdapter entityDescriptionForClass:self.class];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end



@interface CBRRealmDatabaseAdapter ()

@property (nonatomic, readonly) NSMutableDictionary<NSString *, CBREntityDescription *> *entitesByName;

@end

@implementation CBRRealmDatabaseAdapter

- (RLMRealm *)realm
{
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:self.configuration error:&error];
    NSAssert(realm != nil, @"error: %@", error);

    return realm;
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration
{
    if (self = [super init]) {
        _configuration = configuration;
        _entitesByName = [NSMutableDictionary dictionary];
        _queue = dispatch_queue_create("de.sparrow-labs.CloudBridge.realm", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (NSArray<CBREntityDescription *> *)entities
{
    NSMutableArray<CBREntityDescription *> *result = [NSMutableArray array];

    for (Class klass in self.configuration.objectClasses) {
        [result addObject:[self entityDescriptionForClass:klass]];
    }

    return result;
}

- (CBREntityDescription *)entityDescriptionForClass:(Class)persistentClass
{
    @synchronized(self) {
        NSString *name = [persistentClass className];
        if (self.entitesByName[name]) {
            return self.entitesByName[name];
        }

        RLMObjectSchema *schema = self.realm.schema[name];
        CBREntityDescription *result = [[CBREntityDescription alloc] initWithDatabaseAdapter:self realmObjectSchema:schema];
        self.entitesByName[name] = result;

        for (CBRRelationshipDescription *relationship in result.relationships) {
            [relationship _realmUpdateUserInfo];
        }

        return result;
    }
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    RLMProperty *realmProperty = self.realm.schema[entity.name][relationship.name];

    if (realmProperty.type == RLMPropertyTypeLinkingObjects) {
        RLMPropertyDescriptor *inverseDescriptor = [NSClassFromString(entity.name) linkingObjectsProperties][relationship.name];
        NSParameterAssert(inverseDescriptor);

        CBREntityDescription *destinationEntity = [self entityDescriptionForClass:inverseDescriptor.objectClass];
        CBRRelationshipDescription *inverseRelation = destinationEntity.relationshipsByName[inverseDescriptor.propertyName];

        NSParameterAssert(destinationEntity);
        NSParameterAssert(inverseRelation);

        return inverseRelation;
    }

    CBREntityDescription *destinationEntity = relationship.destinationEntity;
    NSDictionary<NSString *, RLMPropertyDescriptor *> *linkingObjectsProperties = [NSClassFromString(destinationEntity.name) linkingObjectsProperties];

    for (NSString *result in linkingObjectsProperties) {
        RLMPropertyDescriptor *inverseDescriptor = linkingObjectsProperties[result];

        if ([inverseDescriptor.propertyName isEqualToString:relationship.name]) {
            CBRRelationshipDescription *inverseRelation = destinationEntity.relationshipsByName[result];
            NSParameterAssert(inverseRelation);

            return inverseRelation;
        }
    }

    return nil;
}

- (BOOL)hasPersistentObjects:(NSArray<CBRRealmObject *> *)persistentObjects
{
    for (CBRRealmObject *object in persistentObjects) {
        if (object.realm == nil) {
            return NO;
        }
    }

    return YES;
}

- (CBRRealmObject *)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    RLMRealm *realm = self.realm;

    __block CBRRealmObject *result = nil;
    [self _transactionInRealm:realm block:^{
        [realm addObject:(result = [[NSClassFromString(entityDescription.name) alloc] init])];
    }];

    return result;
}

#warning cache
- (id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey
{
    if (primaryKey == nil) {
        return nil;
    }

    NSString *attribute = [[NSClassFromString(entityDescription.name) cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    RLMRealm *realm = self.realm;
    return [NSClassFromString(entityDescription.name) objectsInRealm:realm where:@"%K == %@", attribute, primaryKey].firstObject;
}

#warning cache
- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
    RLMRealm *realm = self.realm;
    RLMResults *results = [NSClassFromString(entityDescription.name) objectsInRealm:realm where:@"%K IN %@", attribute, values];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (CBRRealmObject *object in results) {
        if ([object valueForKey:attribute]) {
            result[[object valueForKey:attribute]] = object;
        }
    }

    return result;
}

- (NSArray *)fetchObjectsOfType:(CBREntityDescription *)entityDescription withPredicate:(NSPredicate *)predicate
{
    RLMRealm *realm = self.realm;
    RLMResults *results = [NSClassFromString(entityDescription.name) objectsInRealm:realm withPredicate:predicate];

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:results.count];
    for (CBRRealmObject *object in results) {
        [result addObject:object];
    }

    return result;
}

- (void)mutatePersistentObject:(CBRRealmObject *)persistentObject
                     withBlock:(void(^)(id<CBRPersistentObject> persistentObject))mutation
                    completion:(void(^)(id<CBRPersistentObject> persistentObject, NSError *error))completion
{
    RLMRealm *realm = self.realm;

    if (persistentObject.realm == nil) {
        [self _transactionInRealm:realm block:^{
            [realm addObject:persistentObject];
        }];
    }

    if (persistentObject.invalidated) {
        return completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:nil]);
    }

    RLMThreadSafeReference *ref1 = [RLMThreadSafeReference referenceWithThreadConfined:persistentObject];

    dispatch_async(self.queue, ^{
        RLMRealm *realm = self.realm;
        CBRRealmObject *object = [realm resolveThreadSafeReference:ref1];

        NSError *error = nil;
        [realm transactionWithBlock:^{
            mutation(object);
        } error:&error];

        RLMThreadSafeReference *ref2 = [RLMThreadSafeReference referenceWithThreadConfined:object];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion != nil) {
                completion([self.realm resolveThreadSafeReference:ref2], error);
            }
        });
    });
}

- (void)mutatePersistentObjects:(NSArray<CBRRealmObject *> *)persistentObject
                      withBlock:(NSArray *(^)(NSArray<id<CBRPersistentObject>> *persistentObjects))mutation
                     completion:(void(^)(NSArray<id<CBRPersistentObject>> *persistentObjects, NSError *error))completion
{
    if ([persistentObject indexOfObjectPassingTest:^BOOL(CBRRealmObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return obj.realm == nil;
    }] != NSNotFound) {
        RLMRealm *realm = self.realm;

        [self _transactionInRealm:realm block:^{
            for (CBRRealmObject *object in persistentObject) {
                if (object.realm == nil) {
                    [realm addObject:object];
                }
            }
        }];
    }

    NSMutableArray<RLMThreadSafeReference *> *refs1 = [NSMutableArray array];
    for (CBRRealmObject *object in persistentObject) {
        if (object.invalidated) {
            return completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:nil]);
        }

        [refs1 addObject:[RLMThreadSafeReference referenceWithThreadConfined:object]];
    }

    dispatch_async(self.queue, ^{
        RLMRealm *realm = self.realm;

        NSMutableArray<CBRRealmObject *> *objects = [NSMutableArray array];
        for (RLMThreadSafeReference *ref in refs1) {
            CBRRealmObject *object = [realm resolveThreadSafeReference:ref];

            if (object == nil) {
                return dispatch_async(dispatch_get_main_queue(), ^{
                    return completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:nil]);
                });
            }

            [objects addObject:object];
        }

        NSError *error = nil;
        __block NSArray<CBRRealmObject *> *nextObjects = [NSMutableArray array];
        [realm transactionWithBlock:^{
            nextObjects = mutation(objects);

            for (RLMObject *object in nextObjects) {
                if (object.realm == nil) {
                    [realm addObject:object];
                }
            }
        } error:&error];

        NSMutableArray<RLMThreadSafeReference *> *refs2 = [NSMutableArray array];
        for (CBRRealmObject *object in nextObjects) {
            if (object.invalidated) {
                return dispatch_async(dispatch_get_main_queue(), ^{
                    return completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:nil]);
                });
            }

            [refs2 addObject:[RLMThreadSafeReference referenceWithThreadConfined:object]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            RLMRealm *realm = self.realm;

            NSMutableArray<CBRRealmObject *> *objects = [NSMutableArray array];
            for (RLMThreadSafeReference *ref in refs2) {
                CBRRealmObject *object = [realm resolveThreadSafeReference:ref];

                if (object == nil) {
                    return dispatch_async(dispatch_get_main_queue(), ^{
                        return completion(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:nil]);
                    });
                }
                
                [objects addObject:object];
            }

            if (completion != nil) {
                completion(objects, error);
            }
        });
    });
}

- (void)deletePersistentObjects:(NSArray<CBRRealmObject *> *)persistentObjects
{
    RLMRealm *realm = self.realm;

    [self _transactionInRealm:realm block:^{
        for (CBRRealmObject *object in persistentObjects) {
            [realm deleteObject:object];
        }
    }];
}

- (void)_transactionInRealm:(RLMRealm *)realm block:(dispatch_block_t)block
{
    BOOL transactionOwner = NO;
    if (!realm.inWriteTransaction) {
        [realm beginWriteTransaction];
        transactionOwner = YES;
    }

    block();

    if (transactionOwner) {
        [realm commitWriteTransaction];
    }
}

@end
