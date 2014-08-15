//
//  CBRTestConnection.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestConnection.h"

@implementation CBRTestDictionaryTransformer

- (NSString *)keyPathForCloudIdentifierOfEntitiyDescription:(NSEntityDescription *)entityDescription
{
    return @"identifier";
}

- (NSDictionary *)cloudObjectFromManagedObject:(NSManagedObject *)managedObject
{
    NSMutableDictionary *cloudObject = [NSMutableDictionary dictionary];
    [self updateCloudObject:cloudObject withPropertiesFromManagedObject:managedObject];
    return cloudObject.copy;
}

- (void)updateCloudObject:(NSMutableDictionary *)cloudObject withPropertiesFromManagedObject:(NSManagedObject *)managedObject
{
    if (![cloudObject isKindOfClass:[NSDictionary class]]) {
        return;
    }

    for (NSAttributeDescription *attributeDescription in managedObject.entity.attributesByName.allValues) {
        [cloudObject setValue:[managedObject valueForKey:attributeDescription.name] forKey:attributeDescription.name];
    }
}

- (id)managedObjectFromCloudObject:(NSDictionary *)cloudObject forEntity:(NSEntityDescription *)entity inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(entity);

    id identifier = cloudObject[@"identifier"];
    NSParameterAssert(identifier);

    NSManagedObject *managedObject = [managedObjectContext.cbr_cache objectOfType:entity.name withValue:identifier forAttribute:@"identifier"];
    if (!managedObject) {
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entity.name
                                                      inManagedObjectContext:managedObjectContext];
    }

    [self updateManagedObject:managedObject withPropertiesFromCloudObject:cloudObject];
    return managedObject;
}

- (void)updateManagedObject:(NSManagedObject *)managedObject withPropertiesFromCloudObject:(NSDictionary *)cloudObject
{
    for (NSAttributeDescription *attributeDescription in managedObject.entity.attributesByName.allValues) {
        [managedObject setValue:cloudObject[attributeDescription.name] forKey:attributeDescription.name];
    }
}

@end



@interface CBRTestConnection ()

@end



@implementation CBRTestConnection

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        _objectTransformer = [[CBRTestDictionaryTransformer alloc] init];
    }
    return self;
}

- (void)fetchCloudObjectsForEntity:(NSEntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn ?: @[], nil);
}

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject ?: cloudObject, nil);
}

- (void)latestCloudObjectForManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject ?: [self.objectTransformer cloudObjectFromManagedObject:managedObject], nil);
}

- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject ?: cloudObject, nil);
}

- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler
{
    completionHandler(nil);
}

#pragma mark - Private category implementation ()

@end
