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

#import <objc/runtime.h>

#import "CBRThreadingEnvironment.h"
#import "CBRCoreDataInterface.h"
#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"
#import "CBREntityDescription+CBRCoreDataInterface.h"
#import "CBRPersistentObjectCache.h"

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



@implementation NSManagedObject (CBRPersistentObject)

+ (void)load
{
    class_swizzleSelector(self, @selector(prepareForDeletion), @selector(__SLRESTfulCoreDataObjectCachePrepareForDeletion));
}

- (void)__SLRESTfulCoreDataObjectCachePrepareForDeletion
{
    [self __SLRESTfulCoreDataObjectCachePrepareForDeletion];

    CBRCoreDataInterface *adapter = (CBRCoreDataInterface *)self.databaseAdapter.interface;
    assert([adapter isKindOfClass:[CBRCoreDataInterface class]] || !adapter);
    [[adapter cacheForManagedObjectContext:self.managedObjectContext] removePersistentObject:self];
}

#pragma mark - CBRPersistentObject

+ (CBRCloudBridge *)cloudBridge
{
    CBRCloudBridge *cloudBridge = objc_getAssociatedObject(self, @selector(cloudBridge));
    if (cloudBridge) {
        return cloudBridge;
    }

    if (self == [NSManagedObject class]) {
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

+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self cloudBridge].databaseAdapter.entitiesByName[NSStringFromClass(self)];
}

- (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self.class cloudBridgeEntityDescription];
}

#pragma mark - CBRPersistentObjectQueryInterface

+ (instancetype)objectWithRemoteIdentifier:(id)identifier
{
    assert(identifier == nil || [identifier conformsToProtocol:@protocol(CBRPersistentIdentifier)]);
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
    __assert_unused NSRelationshipDescription *relationshipDescription = self.entity.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(!relationshipDescription.isToMany);

    [self fetchObjectsForRelationship:relationship withCompletionHandler:^(NSArray *objects, NSError *error) {
        if (completionHandler) {
            completionHandler(objects.lastObject, error);
        }
    }];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler
{
    NSRelationshipDescription *relationshipDescription = self.entity.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(relationshipDescription.inverseRelationship);
    NSParameterAssert(!relationshipDescription.inverseRelationship.isToMany);

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", relationshipDescription.inverseRelationship.name, self];
    [self.cloudBridge fetchPersistentObjectsOfClass:NSClassFromString(relationshipDescription.inverseRelationship.entity.name)
                                      withPredicate:predicate
                                  completionHandler:completionHandler];
}

+ (instancetype)persistentObjectFromCloudObject:(id<CBRCloudObject>)cloudObject
{
    CBREntityDescription *entity = [self cloudBridgeEntityDescription];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end



@interface CBRCoreDataInterface () <_CBRPersistentStoreInterfaceInternal>

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

@end

@implementation CBRCoreDataInterface
@synthesize entities = _entities, entitiesByName = _entitiesByName;

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithStack:(CBRCoreDataStack *)stack
{
    if (self = [super init]) {
        _stack = stack;
        _managedObjectModel = stack.persistentStoreCoordinator.managedObjectModel;

        NSMutableArray<CBREntityDescription *> *result = [NSMutableArray array];

        for (NSEntityDescription *entity in self.managedObjectModel.entities) {
            [result addObject:[[CBREntityDescription alloc] initWithInterface:self coreDataEntityDescription:entity]];
        }

        _entities = result.copy;

        NSMutableDictionary<NSString *, CBREntityDescription *> *entitiesByName = [NSMutableDictionary dictionary];
        for (CBREntityDescription *description in _entities) {
            entitiesByName[description.name] = description;
        }

        _entitiesByName = entitiesByName.copy;
    }
    return self;
}

- (CBRPersistentObjectCache *)cacheForManagedObjectContext:(NSManagedObjectContext *)context
{
    @synchronized (context) {
        if (objc_getAssociatedObject(context, _cmd)) {
            return objc_getAssociatedObject(context, _cmd);
        }

        CBRPersistentObjectCache *cache = [[CBRPersistentObjectCache alloc] initWithInterface:self];
        objc_setAssociatedObject(context, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return cache;
    }
}

#pragma mark - _CBRPersistentStoreInterfaceInternal

- (BOOL)hasPersistedObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    for (NSManagedObject *object in persistentObjects) {
        if (object.isInserted) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)saveChangedForPersistentObject:(NSManagedObject *)persistentObject error:(NSError **)error
{
    if (persistentObject.isInserted || persistentObject.hasChanges) {
        return [persistentObject.managedObjectContext save:error];
    }

    return YES;
}

#pragma mark - CBRPersistentStoreInterface

- (CBRPersistentObjectCache *)persistentObjectCacheForCurrentThread
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [self cacheForManagedObjectContext:context];
}

- (void)beginWriteTransaction
{

}

- (BOOL)commitWriteTransaction:(NSError * _Nullable __autoreleasing *)error
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context save:error];
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    NSRelationshipDescription *relationshipDescription = self.managedObjectModel.entitiesByName[entity.name].relationshipsByName[relationship.name];
    NSParameterAssert(relationshipDescription);

    NSRelationshipDescription *inverseRelationship = relationshipDescription.inverseRelationship;
    NSParameterAssert(inverseRelationship);

    return self.entitiesByName[relationship.destinationEntityName].relationshipsByName[inverseRelationship.name];
}

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    NSManagedObject *result = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name inManagedObjectContext:context];

    return result;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    assert(self.entitiesByName[fetchRequest.entityName] != nil);
    
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context executeFetchRequest:fetchRequest error:error];
}

- (void)deletePersistentObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;

    for (NSManagedObject *managedObject in persistentObjects) {
        [context deleteObject:managedObject];
    }
}

@end
