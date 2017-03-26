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

+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [[self cloudBridge].databaseAdapter entityDescriptionForClass:self];
}

- (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [self.class cloudBridgeEntityDescription];
}

#pragma mark - CBRPersistentObjectQueryInterface

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

+ (instancetype)managedObjectFromCloudObject:(id<CBRCloudObject>)cloudObject inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    CBREntityDescription *entity = [[self cloudBridge].databaseAdapter entityDescriptionForClass:self.class];
    return (id)[[self cloudBridge].cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject forEntity:entity];
}

@end



@interface CBRCoreDataDatabaseAdapter ()

@property (nonatomic, readonly) NSMutableDictionary *entitesByName;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

@end

@implementation CBRCoreDataDatabaseAdapter

- (NSManagedObjectContext *)mainThreadContext
{
    return self.coreDataStack.mainThreadManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundThreadContext
{
    return self.coreDataStack.backgroundThreadManagedObjectContext;
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithCoreDataStack:(CBRCoreDataStack *)coreDataStack
{
    if (self = [super init]) {
        _coreDataStack = coreDataStack;
        _entitesByName = [NSMutableDictionary dictionary];
        _managedObjectModel = _coreDataStack.persistentStoreCoordinator.managedObjectModel;
    }
    return self;
}

#pragma mark - CBRDatabaseAdapter

- (NSArray *)entities
{
    NSMutableArray *result = [NSMutableArray array];

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

- (void)saveChangesForPersistentObject:(NSManagedObject *)persistentObject
{
    if (persistentObject.hasChanges || persistentObject.isInserted) {
        NSError *saveError = nil;
        [persistentObject.managedObjectContext save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
    }
}

- (id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.mainThreadContext : self.backgroundThreadContext;
    return [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name inManagedObjectContext:context];
}

- (id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.mainThreadContext : self.backgroundThreadContext;
    NSString *attribute = [[NSClassFromString(entityDescription.name) cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [context.cbr_cache objectOfType:entityDescription.name withValue:primaryKey forAttribute:attribute];
}

- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.mainThreadContext : self.backgroundThreadContext;
    return [context.cbr_cache indexedObjectsOfType:entityDescription.name withValues:values forAttribute:attribute];
}

- (NSArray *)fetchObjectsOfType:(CBREntityDescription *)entityDescription withPredicate:(NSPredicate *)predicate
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.mainThreadContext : self.backgroundThreadContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityDescription.name];
    fetchRequest.predicate = predicate;

    return [context executeFetchRequest:fetchRequest error:NULL];
}

- (void)mutatePersistentObject:(NSManagedObject *)persistentObject
                     withBlock:(void(^)(id<CBRPersistentObject> persistentObject))mutation
                    completion:(void(^)(id<CBRPersistentObject> persistentObject, NSError *error))completion
{
    NSParameterAssert(mutation);

    NSManagedObjectContext *context = self.backgroundThreadContext;
    [context performBlock:^(NSManagedObject *object, NSError *error) {
        if (error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
            return;
        }

        mutation(object);

        NSError *saveError = nil;
        [context save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
        [self.mainThreadContext performBlock:^(id object, NSError *error) {
            if (completion) {
                completion(object, error);
            }
        } withObject:object];
    } withObject:persistentObject];
}

- (void)mutatePersistentObjects:(NSArray *)persistentObjects
                      withBlock:(NSArray *(^)(NSArray *persistentObjects))mutation
                     completion:(void(^)(NSArray *persistentObjects, NSError *error))completion
{
    NSParameterAssert(mutation);

    NSManagedObjectContext *context = self.backgroundThreadContext;
    [context performBlock:^(id object, NSError *error) {
        if (error) {
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            }
            return;
        }

        NSArray *objects = mutation(object);

        NSError *saveError = nil;
        [context save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);

        [self.mainThreadContext performBlock:^(id object, NSError *error) {
            if (completion) {
                completion(object, error);
            }
        } withObject:objects];
    } withObject:persistentObjects];
}

- (void)deletePersistentObjects:(NSArray *)persistentObjects
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.mainThreadContext : self.backgroundThreadContext;

    for (NSManagedObject *managedObject in persistentObjects) {
        [context deleteObject:managedObject];
    }

    NSError *saveError = nil;
    [context save:&saveError];
    NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
}

@end
