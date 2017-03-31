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
#import "CBRCoreDataDatabaseAdapter.h"
#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"
#import "CBREntityDescription+CBRCoreDataDatabaseAdapter.h"
#import "CBRManagedObjectCache.h"



@implementation NSManagedObject (CBRPersistentObject)

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

+ (id<CBRDatabaseAdapter>)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
}

- (id<CBRDatabaseAdapter>)databaseAdapter
{
    return [self cloudBridge].databaseAdapter;
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

+ (instancetype)objectWithRemoteIdentifier:(id)identifier
{
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

+ (instancetype)newWithBlock:(dispatch_block_t *)saveBlock
{
    CBREntityDescription *entityDescription = [self cloudBridgeEntityDescription];
    return [[self cloudBridge].databaseAdapter newMutablePersistentObjectOfType:entityDescription save:saveBlock];
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
    CBREntityDescription *entity = [[self cloudBridge].databaseAdapter entityDescriptionForClass:self.class];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end



@interface CBRCoreDataDatabaseAdapter ()

@property (nonatomic, readonly) NSMutableDictionary<NSString *, CBREntityDescription *> *entitesByName;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) CBRThreadingEnvironment *(^threadingEnvironmentBlock)(void);

@end

@implementation CBRCoreDataDatabaseAdapter

- (CBRThreadingEnvironment *)threadingEnvironment
{
    CBRThreadingEnvironment *threadingEnvironment = self.threadingEnvironmentBlock();
    assert(threadingEnvironment.coreDataAdapter != nil);

    return threadingEnvironment;
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithStack:(CBRCoreDataStack *)stack threadingEnvironment:(CBRThreadingEnvironment *(^)(void))threadingEnvironment
{
    if (self = [super init]) {
        _stack = stack;
        _entitesByName = [NSMutableDictionary dictionary];
        _managedObjectModel = stack.persistentStoreCoordinator.managedObjectModel;
        _threadingEnvironmentBlock = threadingEnvironment;
    }
    return self;
}

#pragma mark - CBRDatabaseAdapter

- (NSArray<CBREntityDescription *> *)entities
{
    NSMutableArray<CBREntityDescription *> *result = [NSMutableArray array];

    for (NSEntityDescription *entity in self.managedObjectModel.entities) {
        [result addObject:[self entityDescriptionForClass:NSClassFromString(entity.managedObjectClassName)]];
    }

    return result;
}

- (CBREntityDescription *)entityDescriptionForClass:(Class)persistentClass
{
    @synchronized(self) {
        NSString *name = NSStringFromClass(persistentClass);
        if (self.entitesByName[name]) {
            return self.entitesByName[name];
        }

        NSEntityDescription *entity = self.managedObjectModel.entitiesByName[name];
        CBREntityDescription *result = [[CBREntityDescription alloc] initWithDatabaseAdapter:self coreDataEntityDescription:entity];
        self.entitesByName[name] = result;
        return result;
    }
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    NSRelationshipDescription *relationshipDescription = self.managedObjectModel.entitiesByName[entity.name].relationshipsByName[relationship.name];
    NSParameterAssert(relationshipDescription);

    NSRelationshipDescription *inverseRelationship = relationshipDescription.inverseRelationship;
    NSParameterAssert(inverseRelationship);

    return [self entityDescriptionForClass:NSClassFromString(relationship.destinationEntityName)].relationshipsByName[inverseRelationship.name];
}

- (void)saveChangesForPersistentObject:(NSManagedObject *)persistentObject
{
    if (persistentObject.hasChanges || persistentObject.isInserted) {
        NSError *saveError = nil;
        [persistentObject.managedObjectContext save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
    }
}

- (BOOL)hasPersistedObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    for (NSManagedObject *object in persistentObjects) {
        if (object.isInserted) {
            return NO;
        }
    }

    return YES;
}

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription save:(dispatch_block_t *)saveBlock
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;

    NSManagedObject *result = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name inManagedObjectContext:context];

    if (saveBlock != NULL) {
        *saveBlock = ^{
            NSError *error = nil;
            [context save:&error];
            NSAssert(error == nil, @"error saving changes: %@", error);
        };
    }

    return result;
}

- (id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    NSString *attribute = [[NSClassFromString(entityDescription.name) cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [context.cloudBridgeCache objectOfType:entityDescription.name withValue:primaryKey forAttribute:attribute];
}

- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context.cloudBridgeCache indexedObjectsOfType:entityDescription.name withValues:values forAttribute:attribute];
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    assert([self entityDescriptionForClass:NSClassFromString(fetchRequest.entityName)] != nil);
    
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context executeFetchRequest:fetchRequest error:error];
}

- (void)transactionWithBlock:(dispatch_block_t)transaction
{
    NSArray<NSString *> *callStack = [NSThread callStackSymbols];

    [self transactionWithBlock:transaction completion:^(NSError * _Nonnull error) {
        if (error != nil) {
            [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@, call stack: %@", error, callStack];
        }
    }];
}

- (void)transactionWithBlock:(dispatch_block_t)transaction completion:(void (^ _Nullable)(NSError * _Nonnull))completion
{
    [self transactionWithObject:nil transaction:^id _Nullable(id  _Nullable object) {
        transaction();
        return nil;
    } completion:^(id  _Nullable object, NSError * _Nullable error) {
        if (completion != nil) {
            completion(error);
        } else {
            if (error != nil) {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to main thread %@", error];
            }
        }
    }];
}

- (void)transactionWithObject:(id)object transaction:(id  _Nullable (^)(id _Nullable))transaction completion:(void (^)(id _Nullable, NSError * _Nullable))completion
{
    [self.threadingEnvironment moveObject:object toThread:CBRThreadBackground completion:^(id  _Nullable object, NSError * _Nullable error) {
        if (error != nil) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            } else {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to background thread %@", error];
            }
            return;
        }

        __block NSError *saveError = nil;
        dispatch_block_t save = ^{
            [self.stack.backgroundThreadManagedObjectContext save:&saveError];
        };

        id result = transaction(object);
        save();

        if (saveError != nil) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, saveError);
                });
            } else {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@", error];
            }
            return;
        }

        [self.threadingEnvironment moveObject:result toThread:CBRThreadMain completion:^(id  _Nullable object, NSError * _Nullable error) {
            if (completion != nil) {
                completion(object, error);
            } else {
                if (error != nil) {
                    [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to main thread %@", error];
                }
            }
        }];
    }];
}

- (void)unsafeTransactionWithObject:(id)object transaction:(void(^)(id _Nullable))transaction
{
    [self unsafeTransactionWithObject:object transaction:^id _Nullable(id  _Nullable object) {
        transaction(object);
        return nil;
    } completion:nil];
}

- (void)unsafeTransactionWithObject:(id)object transaction:(id  _Nullable (^)(id _Nullable))transaction completion:(void (^)(id _Nullable))completion
{
    NSArray<NSString *> *callStack = [NSThread callStackSymbols];

    [self transactionWithObject:object transaction:transaction completion:^(id  _Nullable object, NSError * _Nullable error) {
        if (error != nil) {
            [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@, call stack: %@", error, callStack];
        }

        if (completion != nil) {
            completion(object);
        }
    }];
}

- (void)deletePersistentObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;

    for (NSManagedObject *managedObject in persistentObjects) {
        [context deleteObject:managedObject];
    }

    NSError *saveError = nil;
    [context save:&saveError];
    NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
}

@end
