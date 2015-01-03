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

#pragma mark - CBRPersistentObjectQueryInterface

+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    [[self cloudBridge] fetchManagedObjectsOfType:NSStringFromClass(class)
                                    withPredicate:predicate
                                completionHandler:completionHandler];
}

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge createManagedObject:self withCompletionHandler:completionHandler];
}

- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge reloadManagedObject:self withCompletionHandler:completionHandler];
}

- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge saveManagedObject:self withCompletionHandler:completionHandler];
}

- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.cloudBridge deleteManagedObject:self withCompletionHandler:completionHandler];
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
    return [self.cloudBridge.cloudConnection.objectTransformer cloudObjectFromManagedObject:self];
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
    [self.cloudBridge fetchManagedObjectsOfType:relationshipDescription.inverseRelationship.entity.name
                                  withPredicate:predicate
                              completionHandler:completionHandler];
}

+ (instancetype)managedObjectFromCloudObject:(id<CBRCloudObject>)cloudObject inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:managedObjectContext];
    NSParameterAssert(entity);

    return [[self cloudBridge].cloudConnection.objectTransformer managedObjectFromCloudObject:cloudObject forEntity:entity inManagedObjectContext:managedObjectContext];
}

@end



@interface CBRCoreDataDatabaseAdapter ()

@property (nonatomic, readonly) NSMutableDictionary *entitesByName;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

@end

@implementation CBRCoreDataDatabaseAdapter

- (instancetype)initWithMainThreadContext:(NSManagedObjectContext *)mainContext backgroundThreadContext:(NSManagedObjectContext *)backgroundContext
{
    if (self = [super init]) {
        _mainThreadContext = mainContext;
        _backgroundThreadContext = backgroundContext;
        _entitesByName = [NSMutableDictionary dictionary];
        _managedObjectModel = _mainThreadContext.persistentStoreCoordinator.managedObjectModel;
    }
    return self;
}

- (instancetype)initWithCoreDataStack:(SLCoreDataStack *)coreDataStack
{
    return [self initWithMainThreadContext:coreDataStack.mainThreadManagedObjectContext backgroundThreadContext:coreDataStack.backgroundThreadManagedObjectContext];
}

#pragma mark - CBRDatabaseAdapter

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

- (void)prepareForMutationWithPersistentObject:(NSManagedObject *)persistentObject
{
    if (persistentObject.hasChanges || persistentObject.isInserted) {
        NSError *saveError = nil;
        [persistentObject.managedObjectContext save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);
    }
}

- (void)mutatePersistentObject:(NSManagedObject *)persitentObject
                     withBlock:(void(^)(id<CBRPersistentObject> persistentObject))mutation
                    completion:(void(^)(id<CBRPersistentObject> persistentObject))completion
{
    NSParameterAssert(mutation);
    NSParameterAssert(completion);

    [self.backgroundThreadContext performBlock:^(NSManagedObject *object) {
        mutation(object);

        NSError *saveError = nil;
        [self.backgroundThreadContext save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);

        [self.mainThreadContext performBlock:completion withObject:object];
    } withObject:persitentObject];
}

- (void)deletePersistentObjects:(NSArray *)persistentObjects withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSManagedObjectContext *context = self.backgroundThreadContext;
    [context performBlock:^(NSArray *objects) {
        for (NSManagedObject *managedObject in objects) {
            [context deleteObject:managedObject];
        }

        NSError *saveError = nil;
        [context save:&saveError];
        NSCAssert(saveError == nil, @"error saving managed object context: %@", saveError);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(saveError);
            }
        });
    } withObject:persistentObjects];
}

@end
