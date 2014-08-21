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
                          userInfo:(NSDictionary *)userInfo
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn ?: @[], nil);
}

#pragma mark - CBRCloudConnection

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)latestCloudObjectForManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler
{
    completionHandler(self.errorToReturn);
}

#pragma mark - CBROfflineCapableCloudConnection

- (void)bulkCreateCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

- (void)bulkSaveCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

- (void)bulkDeleteCloudObjects:(NSArray *)cloudObjects forManagedObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *deletedObjectIdentifiers, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

#pragma mark - Private category implementation ()

@end
