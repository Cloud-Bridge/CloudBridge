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

#import "CBRRealmInterface.h"
#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"
#import "CBRThreadingEnvironment.h"
#import "CBREntityDescription+Realm.h"

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}



@implementation RLMRealm (CBRRealmInterfaceHooks)

+ (void)load
{
    class_swizzleSelector(self, @selector(deleteObject:), @selector(__CBRRealmInterfaceHooksDeleteObject:));
    class_swizzleSelector(self, @selector(deleteObjects:), @selector(__CBRRealmInterfaceHooksDeleteObjects:));
}

- (void)__CBRRealmInterfaceHooksDeleteObject:(CBRRealmObject *)object
{
    if ([object isKindOfClass:[CBRRealmObject class]]) {
        CBRRealmInterface *adapter = object.databaseAdapter.interface;
        assert([adapter isKindOfClass:[CBRRealmInterface class]]);

        [[adapter cacheForRealm:object.realm] removePersistentObject:object];
    }
    [self __CBRRealmInterfaceHooksDeleteObject:object];
}

- (void)__CBRRealmInterfaceHooksDeleteObjects:(id)array
{
    for (CBRRealmObject *object in array) {
        if ([object isKindOfClass:[CBRRealmObject class]]) {
            CBRRealmInterface *adapter = object.databaseAdapter.interface;
            assert([adapter isKindOfClass:[CBRRealmInterface class]]);
            
            [[adapter cacheForRealm:object.realm] removePersistentObject:object];
        }
    }

    [self __CBRRealmInterfaceHooksDeleteObjects:array];
}

@end

@implementation CBRRelationshipDescription (CBRRealmInterface)

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

+ (CBRDatabaseAdapter *)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
}

- (CBRDatabaseAdapter *)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
}

#warning must be overwritten
+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self cloudBridge].databaseAdapter.entitiesByName[[self className]];
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

    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    return (id)[[self cloudBridge].databaseAdapter persistentObjectOfType:entityDescription withPrimaryKey:identifier];
}

+ (NSDictionary<id<CBRPersistentIdentifier>, id> *)objectsWithRemoteIdentifiers:(NSArray<id<CBRPersistentIdentifier>> *)identifiers
{
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    NSString *attribute = [[self cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [[self cloudBridge].databaseAdapter indexedObjectsOfType:entityDescription withValues:[NSSet setWithArray:identifiers] forAttribute:attribute];
}

+ (instancetype)newCloudBrideObject
{
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    return [[self cloudBridge].databaseAdapter newMutablePersistentObjectOfType:entityDescription];
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
    __assert_unused CBRRelationshipDescription *relationshipDescription = self.cloudBridgeEntityDescription.relationshipsByName[relationship];
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
    CBREntityDescription *entity = [self cloudBridgeEntityDescription];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end



@interface CBRRealmInterface () <_CBRPersistentStoreInterfaceInternal>

@end



@implementation CBRRealmInterface
@synthesize entities = _entities, entitiesByName = _entitiesByName;

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

        NSMutableArray<CBREntityDescription *> *entities = [NSMutableArray array];

        for (Class klass in self.configuration.objectClasses) {
            NSString *name = [klass className];

            RLMObjectSchema *schema = self.realm.schema[name];
            CBREntityDescription *result = [[CBREntityDescription alloc] initWithInterface:self realmObjectSchema:schema];

            [entities addObject:result];
        }
        
        _entities = entities.copy;

        NSMutableDictionary *entitiesByName = [NSMutableDictionary dictionary];
        for (CBREntityDescription *description in entities) {
            entitiesByName[description.name] = description;
        }
        _entitiesByName = entitiesByName.copy;

        for (CBREntityDescription *description in _entities) {
            for (CBRRelationshipDescription *relationship in description.relationships) {
                [relationship _realmUpdateUserInfo];
            }
        }
    }
    return self;
}

- (CBRPersistentObjectCache *)cacheForRealm:(RLMRealm *)realm
{
    @synchronized (realm) {
        if (objc_getAssociatedObject(realm, _cmd)) {
            return objc_getAssociatedObject(realm, _cmd);
        }

        CBRPersistentObjectCache *cache = [[CBRPersistentObjectCache alloc] initWithInterface:self];
        objc_setAssociatedObject(realm, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return cache;
    }
}

#pragma mark - _CBRPersistentStoreInterfaceInternal

- (BOOL)hasPersistedObjects:(NSArray<CBRRealmObject *> *)persistentObjects
{
    for (CBRRealmObject *object in persistentObjects) {
        if (object.realm == nil) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)saveChangedForPersistentObject:(CBRRealmObject *)persistentObject error:(NSError **)error
{
    if (persistentObject.realm == nil) {
        [self _transactionInRealm:self.realm block:^{
            [self.realm addObject:persistentObject];
        }];
    }

    return YES;
}

#pragma mark - CBRPersistentStoreInterface

- (CBRPersistentObjectCache *)persistentObjectCacheForCurrentThread
{
    return [self cacheForRealm:self.realm];
}

- (void)beginWriteTransaction
{
    [self.realm beginWriteTransaction];
}

- (BOOL)commitWriteTransaction:(NSError * _Nullable __autoreleasing *)error
{
    return [self.realm commitWriteTransaction:error];
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    RLMProperty *realmProperty = self.realm.schema[entity.name][relationship.name];

    if (realmProperty.type == RLMPropertyTypeLinkingObjects) {
        RLMPropertyDescriptor *inverseDescriptor = [NSClassFromString(entity.name) linkingObjectsProperties][relationship.name];
        NSParameterAssert(inverseDescriptor);

        CBREntityDescription *destinationEntity = self.entitiesByName[NSStringFromClass(inverseDescriptor.objectClass)];
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

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    RLMRealm *realm = self.realm;

    CBRRealmObject *result = [[NSClassFromString(entityDescription.name) alloc] init];

    [self _transactionInRealm:realm block:^{
        [realm addObject:result];
    }];

    return result;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    assert(self.entitiesByName[fetchRequest.entityName] != nil);

    RLMRealm *realm = self.realm;
    RLMResults *results = [NSClassFromString(fetchRequest.entityName) objectsInRealm:realm withPredicate:fetchRequest.predicate];

    if (fetchRequest.sortDescriptors.count > 0) {
        NSMutableArray<RLMSortDescriptor *> *sortDescriptors = [NSMutableArray array];
        for (NSSortDescriptor *descriptor in fetchRequest.sortDescriptors) {
            [sortDescriptors addObject:[RLMSortDescriptor sortDescriptorWithKeyPath:descriptor.key ascending:descriptor.ascending]];
        }

        results = [results sortedResultsUsingDescriptors:sortDescriptors];
    }

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:results.count];
    for (CBRRealmObject *object in results) {
        [result addObject:object];
    }

    return result;
}

- (void)deletePersistentObjects:(NSArray<CBRRealmObject *> *)persistentObjects
{
    RLMRealm *realm = self.realm;

    [self _transactionInRealm:realm block:^{
        [realm deleteObjects:persistentObjects];
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



@implementation CBRRealmInterface (Convenience)

- (BOOL)assertClasses:(NSArray<Class> *)classes
{
    for (Class klass in classes) {
        if (![self.configuration.objectClasses containsObject:klass]) {
            NSLog(@"Realm did not manage %@", klass);
            return NO;
        }
    }

    return YES;
}

- (BOOL)assertClassesExcept:(NSArray<Class> *)exceptClasses
{
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    NSMutableArray<Class> *result = [NSMutableArray array];

    for (unsigned int i = 0; i < count; i++) {
        if (class_getSuperclass(classes[i]) != [CBRRealmObject class]) {
            continue;
        }

        if ([exceptClasses containsObject:classes[i]]) {
            continue;
        }

        [result addObject:classes[i]];
    }

    free(classes);

    return [self assertClasses:result];
}

@end
