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

#import "CBROfflineCapableCloudBridge.h"
#import "CBRPersistentObject.h"
#import "CBRCoreDataDatabaseAdapter.h"

@implementation CBRDeletedObjectIdentifier

- (instancetype)initWithCloudIdentifier:(id)cloudIdentifier entitiyName:(NSString *)entitiyName
{
    NSParameterAssert(cloudIdentifier);
    NSParameterAssert(entitiyName);

    if (self = [super init]) {
        _cloudIdentifier = cloudIdentifier;
        _entitiyName = entitiyName;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[CBRDeletedObjectIdentifier alloc] initWithCloudIdentifier:self.cloudIdentifier entitiyName:self.entitiyName];
}

- (NSUInteger)hash
{
    return [self.cloudIdentifier hash] ^ self.entitiyName.hash;
}

- (BOOL)isEqual:(CBRDeletedObjectIdentifier *)object
{
    if ([object isKindOfClass:[CBRDeletedObjectIdentifier class]]) {
        return [self.cloudIdentifier isEqual:object.cloudIdentifier] && [self.entitiyName isEqualToString:object.entitiyName];
    }

    return [super isEqual:object];
}

@end



@interface CBROfflineCapableCloudBridge ()

@property (nonatomic, assign) BOOL isRunningInOfflineMode;
@property (nonatomic, assign) BOOL isReenablingOnlineMode;

@end



@implementation CBROfflineCapableCloudBridge

#pragma mark - setters and getters

- (BOOL)isRunningInOfflineMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"CBROfflineCapableCloudBridge.isRunningInOfflineMode"];
}

- (void)setIsRunningInOfflineMode:(BOOL)isRunningInOfflineMode
{
    [[NSUserDefaults standardUserDefaults] setBool:isRunningInOfflineMode forKey:@"CBROfflineCapableCloudBridge.isRunningInOfflineMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Offline mode

- (void)enableOfflineMode
{
    if (!self.isRunningInOfflineMode) {
        self.isRunningInOfflineMode = YES;
    }
}

- (void)reenableOnlineModeWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    void(^invokeCompletionHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(error);
        }

        self.isReenablingOnlineMode = NO;
    };

    if (!self.isRunningInOfflineMode) {
        return invokeCompletionHandler(nil);
    }

    self.isReenablingOnlineMode = YES;
    [self _synchronizePendingObjectCreationsWithCompletionHandler:^(NSError *error) {
        if (error) {
            return invokeCompletionHandler(error);
        }

        [self _synchronizePendingObjectUpdatesWithCompletionHandler:^(NSError *error) {
            if (error) {
                return invokeCompletionHandler(error);
            }

            [self _synchronizePendingObjectDeletionsWithCompletionHandler:^(NSError *error) {
                if (error) {
                    return invokeCompletionHandler(error);
                }

                self.isRunningInOfflineMode = NO;
                invokeCompletionHandler(nil);
            }];
        }];
    }];
}

#pragma mark - Initialization

- (instancetype)initWithCloudConnection:(id<CBROfflineCapableCloudConnection>)cloudConnection
                        databaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter
{
    return [super initWithCloudConnection:cloudConnection databaseAdapter:databaseAdapter];
}

- (instancetype)initWithCloudConnection:(id<CBROfflineCapableCloudConnection>)cloudConnection coreDataStack:(SLCoreDataStack *)coreDataStack
{
    return [self initWithCloudConnection:cloudConnection databaseAdapter:[[CBRCoreDataDatabaseAdapter alloc] initWithCoreDataStack:coreDataStack]];
}

#pragma mark - CBRCloudBridge

- (void)createManagedObject:(NSManagedObject<CBROfflineCapableManagedObject> *)managedObject
               withUserInfo:(NSDictionary *)userInfo
          completionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (![managedObject conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
        return [super createManagedObject:managedObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        managedObject.hasPendingCloudBridgeChanges = @YES;

        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

        if (completionHandler) {
            completionHandler(managedObject, nil);
        }
        return;
    }

    [super createManagedObject:managedObject withUserInfo:userInfo completionHandler:^(id _, NSError *error) {
        if (error) {
            [self.backgroundThreadManagedObjectContext performBlock:^(NSManagedObject<CBROfflineCapableManagedObject> *backgroundManagedObject) {
                backgroundManagedObject.hasPendingCloudBridgeChanges = @YES;

                NSError *saveError = nil;
                [backgroundManagedObject.managedObjectContext save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(nil, error);
                    }
                });
            } withObject:managedObject];
        } else {
            if (completionHandler) {
                completionHandler(managedObject, nil);
            }
        }
    }];
}

- (void)saveManagedObject:(NSManagedObject<CBROfflineCapableManagedObject> *)managedObject
             withUserInfo:(NSDictionary *)userInfo
        completionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (![managedObject conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
        return [super saveManagedObject:managedObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        managedObject.hasPendingCloudBridgeChanges = @YES;

        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

        if (completionHandler) {
            completionHandler(managedObject, nil);
        }
        return;
    }

    [super saveManagedObject:managedObject withUserInfo:userInfo completionHandler:^(id _, NSError *error) {
        if (error) {
            [self.backgroundThreadManagedObjectContext performBlock:^(NSManagedObject<CBROfflineCapableManagedObject> *backgroundManagedObject) {
                backgroundManagedObject.hasPendingCloudBridgeChanges = @YES;

                NSError *saveError = nil;
                [backgroundManagedObject.managedObjectContext save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(nil, error);
                    }
                });
            } withObject:managedObject];
        } else {
            if (completionHandler) {
                completionHandler(managedObject, nil);
            }
        }
    }];
}

- (void)deleteManagedObject:(NSManagedObject<CBROfflineCapableManagedObject> *)managedObject
               withUserInfo:(NSDictionary *)userInfo
          completionHandler:(void(^)(NSError *error))completionHandler
{
    if (![managedObject conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
        return [super deleteManagedObject:managedObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        NSString *cloudIdentifier = [self.cloudConnection.objectTransformer keyPathForCloudIdentifierOfEntitiyDescription:managedObject.entity];
        id identifier = [managedObject valueForKey:cloudIdentifier];

        BOOL identifierIsNil = identifier == nil || ([identifier isKindOfClass:[NSNumber class]] && [identifier integerValue] == 0) || ([identifier isKindOfClass:[NSString class]] && [identifier length] == 0);
        if (managedObject.hasPendingCloudBridgeChanges.boolValue && identifierIsNil) {
            [managedObject.managedObjectContext deleteObject:managedObject];
        } else {
            managedObject.hasPendingCloudBridgeChanges = @NO;
            managedObject.hasPendingCloudBridgeDeletion = @YES;
        }

        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

        if (completionHandler) {
            completionHandler(nil);
        }
        return;
    }

    [super deleteManagedObject:managedObject withUserInfo:userInfo completionHandler:^(NSError *error) {
        if (error) {
            [self.backgroundThreadManagedObjectContext performBlock:^(NSManagedObject<CBROfflineCapableManagedObject> *backgroundManagedObject) {
                backgroundManagedObject.hasPendingCloudBridgeChanges = @NO;
                backgroundManagedObject.hasPendingCloudBridgeDeletion = @YES;

                NSError *saveError = nil;
                [backgroundManagedObject.managedObjectContext save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                [self.mainThreadManagedObjectContext performBlock:^(id managedObject) {
                    if (completionHandler) {
                        completionHandler(error);
                    }
                } withObject:backgroundManagedObject];
            } withObject:managedObject];
        } else {
            if (completionHandler) {
                completionHandler(nil);
            }
        }
    }];
}

#pragma mark - Private category implementation ()

- (void)_synchronizePendingObjectCreationsWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [context performBlock:^{
        NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;

        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *managedObjects = [NSMutableArray array];

        for (NSEntityDescription *entity in model.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
                continue;
            }

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer keyPathForCloudIdentifierOfEntitiyDescription:entity];

            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity.name];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == NULL AND hasPendingCloudBridgeChanges == YES", cloudIdentifier];

            NSError *error = nil;
            NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            NSAssert(error == nil, @"error fetching data: %@", error);

            for (NSManagedObject *object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [managedObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return;
        }

        [self.cloudConnection bulkCreateCloudObjects:cloudObjects forManagedObjects:managedObjects completionHandler:^(NSArray *cloudObjects, NSError *error) {
            [context performBlock:^(NSArray *managedObjects) {
                NSParameterAssert(cloudObjects.count <= managedObjects.count);
                [cloudObjects enumerateObjectsUsingBlock:^(id<CBRCloudObject> cloudObject, NSUInteger idx, BOOL *stop) {
                    if (idx >= managedObjects.count) {
                        return;
                    }

                    NSManagedObject<CBROfflineCapableManagedObject> *managedObject = managedObjects[idx];
                    [self.cloudConnection.objectTransformer updateManagedObject:managedObject withPropertiesFromCloudObject:cloudObject];

                    managedObject.hasPendingCloudBridgeChanges = @NO;
                }];

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });
            } withObject:managedObjects];
        }];
    }];
}

- (void)_synchronizePendingObjectUpdatesWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [context performBlock:^{
        NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;

        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *managedObjects = [NSMutableArray array];

        for (NSEntityDescription *entity in model.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
                continue;
            }

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer keyPathForCloudIdentifierOfEntitiyDescription:entity];

            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity.name];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K != NULL AND hasPendingCloudBridgeChanges == YES", cloudIdentifier];

            NSError *error = nil;
            NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            NSAssert(error == nil, @"error fetching data: %@", error);

            for (NSManagedObject *object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [managedObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return;
        }

        [self.cloudConnection bulkSaveCloudObjects:cloudObjects forManagedObjects:managedObjects completionHandler:^(NSArray *cloudObjects, NSError *error) {
            [context performBlock:^(NSArray *managedObjects) {
                NSParameterAssert(cloudObjects.count <= managedObjects.count);
                [cloudObjects enumerateObjectsUsingBlock:^(id<CBRCloudObject> cloudObject, NSUInteger idx, BOOL *stop) {
                    if (idx >= managedObjects.count) {
                        return;
                    }

                    NSManagedObject<CBROfflineCapableManagedObject> *managedObject = managedObjects[idx];
                    [self.cloudConnection.objectTransformer updateManagedObject:managedObject withPropertiesFromCloudObject:cloudObject];

                    managedObject.hasPendingCloudBridgeChanges = @NO;
                }];

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });
            } withObject:managedObjects];
        }];
    }];
}

- (void)_synchronizePendingObjectDeletionsWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSDictionary *(^indexManagedObjects)(NSArray *managedObjects) = ^(NSArray *managedObjects) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];

        for (NSManagedObject *object in managedObjects) {
            NSString *cloudIdentifierKey = [self.cloudConnection.objectTransformer keyPathForCloudIdentifierOfEntitiyDescription:object.entity];

            CBRDeletedObjectIdentifier *identifier = [[CBRDeletedObjectIdentifier alloc] initWithCloudIdentifier:[object valueForKey:cloudIdentifierKey]
                                                                                                     entitiyName:object.entity.name];
            result[identifier] = object;
        }

        return result;
    };

    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [context performBlock:^{
        NSManagedObjectModel *model = context.persistentStoreCoordinator.managedObjectModel;

        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *managedObjects = [NSMutableArray array];

        for (NSEntityDescription *entity in model.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapableManagedObject)]) {
                continue;
            }

            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity.name];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"hasPendingCloudBridgeDeletion == YES"];

            NSError *error = nil;
            NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            NSAssert(error == nil, @"error fetching data: %@", error);

            for (NSManagedObject *object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [managedObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return;
        }

        [self.cloudConnection bulkDeleteCloudObjects:cloudObjects forManagedObjects:managedObjects completionHandler:^(NSArray *deletedObjectIdentifiers, NSError *error) {
            [context performBlock:^(NSArray *managedObjects) {
                NSParameterAssert(cloudObjects.count <= managedObjects.count);

                NSDictionary *indexedManagedObjects = indexManagedObjects(managedObjects);

                for (CBRDeletedObjectIdentifier *identifier in deletedObjectIdentifiers) {
                    NSManagedObject<CBROfflineCapableManagedObject> *managedObject = indexedManagedObjects[identifier];
                    [context deleteObject:managedObject];
                }

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });
            } withObject:managedObjects];
        }];
    }];
}

@end
