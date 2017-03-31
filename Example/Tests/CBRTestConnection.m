//
//  CBRTestConnection.m
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestConnection.h"

@interface NSDictionary () <CBRCloudObject> @end
@interface NSMutableDictionary () <CBRMutableCloudObject> @end

@implementation CBRTestDictionaryTransformer

- (NSString *)primaryKeyOfEntitiyDescription:(CBREntityDescription *)entityDescription
{
    return @"identifier";
}

- (id<CBRCloudObject>)cloudObjectFromPersistentObject:(id<CBRPersistentObject>)persistentObject
{
    NSMutableDictionary *cloudObject = [NSMutableDictionary dictionary];
    [self updateCloudObject:cloudObject withPropertiesFromPersistentObject:persistentObject];
    return cloudObject.copy;
}

- (void)updateCloudObject:(NSMutableDictionary *)cloudObject withPropertiesFromPersistentObject:(id<CBRPersistentObject>)persistentObject
{
    if (![cloudObject isKindOfClass:[NSDictionary class]]) {
        return;
    }

    CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:[persistentObject class]];
    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        [cloudObject setValue:[persistentObject valueForKey:attributeDescription.name] forKey:attributeDescription.name];
    }
}

- (id<CBRPersistentObject>)persistentObjectFromCloudObject:(id<CBRCloudObject>)cloudObject forEntity:(CBREntityDescription *)entity
{
    NSParameterAssert(entity);

    id identifier = cloudObject[@"identifier"];
    NSParameterAssert(identifier);

    id<CBRPersistentObject> managedObject = [entity.databaseAdapter persistentObjectOfType:entity withPrimaryKey:identifier];
    if (!managedObject) {
        managedObject = [entity.databaseAdapter newMutablePersistentObjectOfType:entity save:NULL];
    }

    [self updatePersistentObject:managedObject withPropertiesFromCloudObject:cloudObject];
    return managedObject;
}

- (void)updatePersistentObject:(id<CBRPersistentObject>)persistentObject withPropertiesFromCloudObject:(id<CBRCloudObject>)cloudObject
{
    CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:[persistentObject class]];
    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        [persistentObject setValue:cloudObject[attributeDescription.name] forKey:attributeDescription.name];
    }
}

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

- (void)fetchCloudObjectsForEntity:(CBREntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                          userInfo:(NSDictionary *)userInfo
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn ?: @[], nil);
}

#pragma mark - CBRCloudConnection

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)latestCloudObjectForPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn.firstObject, self.errorToReturn);
}

- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler
{
    completionHandler(self.errorToReturn);
}

#pragma mark - CBROfflineCapableCloudConnection

- (void)bulkCreateCloudObjects:(NSArray *)cloudObjects forPersistentObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

- (void)bulkSaveCloudObjects:(NSArray *)cloudObjects forPersistentObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *cloudObjects, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

- (void)bulkDeleteCloudObjects:(NSArray *)cloudObjects forPersistentObjects:(NSArray *)managedObjects completionHandler:(void (^)(NSArray *deletedObjectIdentifiers, NSError *error))completionHandler
{
    completionHandler(self.objectsToReturn, self.errorToReturn);
}

#pragma mark - Private category implementation ()

@end
