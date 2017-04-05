//
//  CBRSharedDatabaseInterface.m
//  Pods
//
//  Created by Oliver Letterer on 05.04.17.
//
//

#import "CBRSharedDatabaseInterface.h"
#import "CBREntityDescription.h"

#if CBRRealmAvailable && CBRCoreDataAvailable

@interface CBRSharedDatabaseInterface () <_CBRPersistentStoreInterfaceInternal>

@end



@implementation CBRSharedDatabaseInterface
@synthesize entities = _entities, entitiesByName = _entitiesByName;

- (instancetype)initWithCoreDataInterface:(CBRCoreDataInterface *)coreDataInterface realmInterface:(CBRRealmInterface *)realmInterface
{
    if (self = [super init]) {
        _coreDataInterface = coreDataInterface;
        _realmInterface = realmInterface;

        _entities = [self.coreDataInterface.entities arrayByAddingObjectsFromArray:self.realmInterface.entities];

        NSMutableDictionary *entitiesByName = [NSMutableDictionary dictionary];
        for (CBREntityDescription *entity in _entities) {
            entitiesByName[entity.name] = entity;
        }
        _entitiesByName = entitiesByName;
    }
    return self;
}

#pragma mark - CBRPersistentStoreInterface

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    if ([self.coreDataInterface.entities containsObject:entity]) {
        return [self.coreDataInterface inverseRelationshipForEntity:entity relationship:relationship];
    } else {
        return [self.realmInterface inverseRelationshipForEntity:entity relationship:relationship];
    }
}

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    if ([self.coreDataInterface.entities containsObject:entityDescription]) {
        return [self.coreDataInterface newMutablePersistentObjectOfType:entityDescription];
    } else {
        return [self.realmInterface newMutablePersistentObjectOfType:entityDescription];
    }
}

- (void)beginWriteTransaction
{
    [self.coreDataInterface beginWriteTransaction];
    [self.realmInterface beginWriteTransaction];
}

- (BOOL)commitWriteTransaction:(NSError **)error
{
    BOOL coreDataSuccess = [self.coreDataInterface commitWriteTransaction:error];
    BOOL realmSuccess = [self.realmInterface commitWriteTransaction:error];

    return coreDataSuccess && realmSuccess;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    if (self.coreDataInterface.entitiesByName[fetchRequest.entityName] != nil) {
        return [self.coreDataInterface executeFetchRequest:fetchRequest error:error];
    } else {
        return [self.realmInterface executeFetchRequest:fetchRequest error:error];
    }
}

- (void)deletePersistentObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects
{
    NSMutableArray<NSManagedObject *> *managedObjects = [NSMutableArray array];
    NSMutableArray<CBRRealmObject *> *realmObjects = [NSMutableArray array];

    for (id<CBRPersistentObject> object in persistentObjects) {
        if ([object isKindOfClass:[NSManagedObject class]]) {
            [managedObjects addObject:(NSManagedObject *)object];
        } else if ([object isKindOfClass:[CBRRealmObject class]]) {
            [realmObjects addObject:(CBRRealmObject *)object];
        }
    }

    if (managedObjects.count > 0) {
        [self.coreDataInterface deletePersistentObjects:managedObjects];
    }

    if (realmObjects.count > 0) {
        [self.realmInterface deletePersistentObjects:realmObjects];
    }
}

- (id<CBRNotificationToken>)changesWithFetchRequest:(NSFetchRequest *)fetchRequest block:(void(^)(NSArray *objects, CBRPersistentObjectChange *change))block
{
    if (self.coreDataInterface.entitiesByName[fetchRequest.entityName] != nil) {
        return [self.coreDataInterface changesWithFetchRequest:fetchRequest block:block];
    } else {
        return [self.realmInterface changesWithFetchRequest:fetchRequest block:block];
    }
}

- (CBRPersistentObjectCache *)persistentObjectCacheOnCurrentThreadForEntity:(CBREntityDescription *)entityDescription
{
    if ([self.coreDataInterface.entities containsObject:entityDescription]) {
        return [self.coreDataInterface persistentObjectCacheOnCurrentThreadForEntity:entityDescription];
    } else {
        return [self.realmInterface persistentObjectCacheOnCurrentThreadForEntity:entityDescription];
    }
}

#pragma mark - _CBRPersistentStoreInterfaceInternal

- (BOOL)hasPersistedObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects
{
    NSMutableArray<NSManagedObject *> *managedObjects = [NSMutableArray array];
    NSMutableArray<CBRRealmObject *> *realmObjects = [NSMutableArray array];

    for (id<CBRPersistentObject> object in persistentObjects) {
        if ([object isKindOfClass:[NSManagedObject class]]) {
            [managedObjects addObject:(NSManagedObject *)object];
        } else if ([object isKindOfClass:[CBRRealmObject class]]) {
            [realmObjects addObject:(CBRRealmObject *)object];
        }
    }

    id<_CBRPersistentStoreInterfaceInternal> coreDataInterface = (id<_CBRPersistentStoreInterfaceInternal>)self.coreDataInterface;
    id<_CBRPersistentStoreInterfaceInternal> realmInterface = (id<_CBRPersistentStoreInterfaceInternal>)self.realmInterface;

    return [coreDataInterface hasPersistedObjects:managedObjects] && [realmInterface hasPersistedObjects:realmObjects];
}

- (BOOL)saveChangedForPersistentObject:(id<CBRPersistentObject>)persistentObject error:(NSError **)error
{
    id<_CBRPersistentStoreInterfaceInternal> coreDataInterface = (id<_CBRPersistentStoreInterfaceInternal>)self.coreDataInterface;
    id<_CBRPersistentStoreInterfaceInternal> realmInterface = (id<_CBRPersistentStoreInterfaceInternal>)self.realmInterface;

    if ([persistentObject isKindOfClass:[NSManagedObject class]]) {
        return [coreDataInterface saveChangedForPersistentObject:persistentObject error:error];
    } else if ([persistentObject isKindOfClass:[CBRRealmObject class]]) {
        return [realmInterface saveChangedForPersistentObject:persistentObject error:error];
    } else {
        return YES;
    }
}

@end

#endif
