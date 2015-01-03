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
#import "CBREntityDescription.h"

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
    CBRCoreDataDatabaseAdapter *adapter = [[CBRCoreDataDatabaseAdapter alloc] initWithCoreDataStack:coreDataStack];
    return [self initWithCloudConnection:cloudConnection databaseAdapter:adapter];
}

#pragma mark - CBRCloudBridge

- (void)createPersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                  withUserInfo:(NSDictionary *)userInfo
             completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    if (![persistentObject conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
        return [super createPersistentObject:persistentObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        persistentObject.hasPendingCloudBridgeChanges = @YES;

        if ([self.databaseAdapter respondsToSelector:@selector(saveChangesForPersistentObject:)]) {
            [self.databaseAdapter saveChangesForPersistentObject:persistentObject];
        }

        if (completionHandler) {
            completionHandler(persistentObject, nil);
        }
        return;
    }

    [super createPersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(id _, NSError *error) {
        if (error) {
            [self.databaseAdapter mutatePersistentObject:persistentObject withBlock:^(id<CBROfflineCapablePersistentObject> persistentObject) {
                persistentObject.hasPendingCloudBridgeChanges = @YES;
            } completion:^(id<CBRPersistentObject> persistentObject) {
                if (completionHandler) {
                    completionHandler(nil, error);
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(persistentObject, nil);
            }
        }
    }];
}

- (void)savePersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                withUserInfo:(NSDictionary *)userInfo
           completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    if (![persistentObject conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
        return [super savePersistentObject:persistentObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        persistentObject.hasPendingCloudBridgeChanges = @YES;

        [self.databaseAdapter saveChangesForPersistentObject:persistentObject];

        if (completionHandler) {
            completionHandler(persistentObject, nil);
        }
        return;
    }

    [super savePersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(id _, NSError *error) {
        if (error) {
            [self.databaseAdapter mutatePersistentObject:persistentObject withBlock:^(id<CBROfflineCapablePersistentObject> persistentObject) {
                persistentObject.hasPendingCloudBridgeChanges = @YES;
            } completion:^(id<CBRPersistentObject> persistentObject) {
                if (completionHandler) {
                    completionHandler(nil, error);
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(persistentObject, nil);
            }
        }
    }];
}

- (void)deletePersistentObject:(id<CBROfflineCapablePersistentObject>)persistentObject
                  withUserInfo:(NSDictionary *)userInfo
             completionHandler:(void(^)(NSError *error))completionHandler
{
    if (![persistentObject conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
        return [super deletePersistentObject:persistentObject withUserInfo:userInfo completionHandler:completionHandler];
    }

    if (self.isRunningInOfflineMode) {
        NSString *cloudIdentifier = [self.cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:[self.databaseAdapter entityDescriptionForClass:persistentObject.class]];
        id identifier = [persistentObject valueForKey:cloudIdentifier];

        BOOL identifierIsNil = identifier == nil || ([identifier isKindOfClass:[NSNumber class]] && [identifier integerValue] == 0) || ([identifier isKindOfClass:[NSString class]] && [identifier length] == 0);
        if (persistentObject.hasPendingCloudBridgeChanges.boolValue && identifierIsNil) {
            [self.databaseAdapter deletePersistentObjects:@[ persistentObject ]];
        } else {
            persistentObject.hasPendingCloudBridgeChanges = @NO;
            persistentObject.hasPendingCloudBridgeDeletion = @YES;

            [self.databaseAdapter saveChangesForPersistentObject:persistentObject];
        }

        if (completionHandler) {
            completionHandler(nil);
        }
        return;
    }

    [super deletePersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(NSError *error) {
        if (error) {
            [self.databaseAdapter mutatePersistentObject:persistentObject withBlock:^(id<CBROfflineCapablePersistentObject> persistentObject) {
                persistentObject.hasPendingCloudBridgeChanges = @NO;
                persistentObject.hasPendingCloudBridgeDeletion = @YES;
            } completion:^(id<CBRPersistentObject> persistentObject) {
                if (completionHandler) {
                    completionHandler(error);
                }
            }];
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
    [self.databaseAdapter mutatePersistentObjects:@[] withBlock:^NSArray *(NSArray *_) {
        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *persistentObjects = [NSMutableArray array];

        for (CBREntityDescription *entity in self.databaseAdapter.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
                continue;
            }

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entity];

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NULL AND hasPendingCloudBridgeChanges == YES", cloudIdentifier];
            NSArray *fetchedObjects = [self.databaseAdapter fetchObjectsOfType:entity withPredicate:predicate];

            for (id<CBROfflineCapablePersistentObject> object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [persistentObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return @[];
        }

        [self.cloudConnection bulkCreateCloudObjects:cloudObjects forPersistentObjects:persistentObjects completionHandler:^(NSArray *cloudObjects, NSError *error) {
            [self.databaseAdapter mutatePersistentObjects:persistentObjects withBlock:^NSArray *(NSArray *persistentObjects) {
                NSParameterAssert(cloudObjects.count <= persistentObjects.count);
                [cloudObjects enumerateObjectsUsingBlock:^(id<CBRCloudObject> cloudObject, NSUInteger idx, BOOL *stop) {
                    if (idx >= persistentObjects.count) {
                        return;
                    }

                    id<CBROfflineCapablePersistentObject> persistentObject = persistentObjects[idx];
                    [self.cloudConnection.objectTransformer updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];

                    persistentObject.hasPendingCloudBridgeChanges = @NO;
                }];

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });
                return @[];
            } completion:NULL];
        }];

        return @[];
    } completion:NULL];
}

- (void)_synchronizePendingObjectUpdatesWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.databaseAdapter mutatePersistentObjects:@[] withBlock:^NSArray *(NSArray *_) {
        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *persistentObjects = [NSMutableArray array];

        for (CBREntityDescription *entity in self.databaseAdapter.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
                continue;
            }

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entity];

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K != NULL AND hasPendingCloudBridgeChanges == YES", cloudIdentifier];
            NSArray *fetchedObjects = [self.databaseAdapter fetchObjectsOfType:entity withPredicate:predicate];

            for (id<CBROfflineCapablePersistentObject>object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [persistentObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return @[];
        }

        [self.cloudConnection bulkSaveCloudObjects:cloudObjects forPersistentObjects:persistentObjects completionHandler:^(NSArray *cloudObjects, NSError *error) {
            [self.databaseAdapter mutatePersistentObjects:persistentObjects withBlock:^NSArray *(NSArray *persistentObjects) {
                NSParameterAssert(cloudObjects.count <= persistentObjects.count);
                [cloudObjects enumerateObjectsUsingBlock:^(id<CBRCloudObject> cloudObject, NSUInteger idx, BOOL *stop) {
                    if (idx >= persistentObjects.count) {
                        return;
                    }

                    id<CBROfflineCapablePersistentObject> persistentObject = persistentObjects[idx];
                    [self.cloudConnection.objectTransformer updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];

                    persistentObject.hasPendingCloudBridgeChanges = @NO;
                }];

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });

                return @[];
            } completion:NULL];
        }];

        return @[];
    } completion:NULL];
}

- (void)_synchronizePendingObjectDeletionsWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSDictionary *(^indexPersistentObjects)(NSArray *persistentObjects) = ^(NSArray *persistentObjects) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];

        for (id<CBROfflineCapablePersistentObject> object in persistentObjects) {
            CBREntityDescription *entityDescription = [self.databaseAdapter entityDescriptionForClass:object.class];
            NSString *cloudIdentifierKey = [self.cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];

            CBRDeletedObjectIdentifier *identifier = [[CBRDeletedObjectIdentifier alloc] initWithCloudIdentifier:[object valueForKey:cloudIdentifierKey]
                                                                                                     entitiyName:entityDescription.name];
            result[identifier] = object;
        }

        return result;
    };

    [self.databaseAdapter mutatePersistentObjects:@[] withBlock:^NSArray *(NSArray *_) {
        NSMutableArray *cloudObjects = [NSMutableArray array];
        NSMutableArray *persistentObjects = [NSMutableArray array];

        for (CBREntityDescription *entity in self.databaseAdapter.entities) {
            if (![NSClassFromString(entity.name) conformsToProtocol:@protocol(CBROfflineCapablePersistentObject)]) {
                continue;
            }

            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hasPendingCloudBridgeDeletion == YES"];
            NSArray *fetchedObjects = [self.databaseAdapter fetchObjectsOfType:entity withPredicate:predicate];

            for (id<CBROfflineCapablePersistentObject> object in fetchedObjects) {
                id<CBRCloudObject> cloudObject = object.cloudObjectRepresentation;

                [cloudObjects addObject:cloudObject];
                [persistentObjects addObject:object];
            }
        }

        if (cloudObjects.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil);
            });
            return @[];
        }

        [self.cloudConnection bulkDeleteCloudObjects:cloudObjects forPersistentObjects:persistentObjects completionHandler:^(NSArray *deletedObjectIdentifiers, NSError *error) {
            [self.databaseAdapter mutatePersistentObjects:persistentObjects withBlock:^NSArray *(NSArray *persistentObjects) {
                NSParameterAssert(cloudObjects.count <= persistentObjects.count);

                NSDictionary *indexedPersistentObjects = indexPersistentObjects(persistentObjects);
                NSMutableArray *objectsToDelete = [NSMutableArray array];

                for (CBRDeletedObjectIdentifier *identifier in deletedObjectIdentifiers) {
                    id<CBROfflineCapablePersistentObject> persistentObject = indexedPersistentObjects[identifier];
                    [objectsToDelete addObject:persistentObject];
                }

                [self.databaseAdapter deletePersistentObjects:objectsToDelete];

                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(error);
                });

                return @[];
            } completion:NULL];
        }];

        return @[];
    } completion:NULL];
}

@end
