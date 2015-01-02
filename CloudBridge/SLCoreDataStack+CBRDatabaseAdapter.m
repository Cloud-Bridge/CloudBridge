//
//  SLCoreDataStack+CBRDatabaseAdapter.m
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "SLCoreDataStack+CBRDatabaseAdapter.h"
#import <objc/runtime.h>
#import "CBRCloudBridge.h"

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

@implementation SLCoreDataStack (CBRDatabaseAdapter)

- (void)deletePersistentObjects:(NSArray *)persistentObjects withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
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
