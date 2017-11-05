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

#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"

@implementation NSNumber (CBRPersistentIdentifier) @end
@implementation NSString (CBRPersistentIdentifier) @end

@interface _CBRCloudBridgePredicateDescription : NSObject

@property (nonatomic, readonly) BOOL deleteEveryOtherObject;

@property (nonatomic, readonly) NSString *relationshipToUpdate;
@property (nonatomic, readonly) id primaryKey;

- (instancetype)initWithPredicate:(NSPredicate *)predicate forEntity:(CBREntityDescription *)entityDescription cloudBridge:(CBRCloudBridge *)cloudBridge parent:(id<CBRPersistentObject> *)parent;

@end

@implementation _CBRCloudBridgePredicateDescription

- (instancetype)initWithPredicate:(NSPredicate *)predicate forEntity:(CBREntityDescription *)entityDescription cloudBridge:(CBRCloudBridge *)cloudBridge parent:(id<CBRPersistentObject> __autoreleasing *)parent
{
    if (self = [super init]) {
        [self _enumerateComparisionPredicatesInPredicate:predicate withBlock:^(NSComparisonPredicate *comparisionPredicate) {
            CBRRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[comparisionPredicate.leftExpression.keyPath];
            id<CBRPersistentObject> persistentObject = comparisionPredicate.rightExpression.constantValue;

            if (relationshipDescription && [persistentObject conformsToProtocol:@protocol(CBRPersistentObject)]) {
                NSString *primaryKey = [[cloudBridge.cloudConnection objectTransformer] primaryKeyOfEntitiyDescription:[persistentObject cloudBridgeEntityDescription]];

                if (parent != NULL) {
                    *parent = persistentObject;
                }

                _relationshipToUpdate = relationshipDescription.name;
                _primaryKey = [persistentObject valueForKey:primaryKey];
                _deleteEveryOtherObject = relationshipDescription.cascades;
            }
        }];
    }
    return self;
}

- (void)_enumerateComparisionPredicatesInPredicate:(NSPredicate *)predicate withBlock:(void(^)(NSComparisonPredicate *comparisionPredicate))block
{
    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparisionPredicate = (NSComparisonPredicate *)predicate;
        block(comparisionPredicate);
    } else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate *)predicate;

        for (NSPredicate *predicate in compoundPredicate.subpredicates) {
            [self _enumerateComparisionPredicatesInPredicate:predicate withBlock:block];
        }
    }
}

@end



@implementation CBRCloudBridge

#pragma mark - Initialization

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection
                              interface:(id<CBRPersistentStoreInterface>)interface
                   threadingEnvironment:(CBRThreadingEnvironment *)threadingEnvironment
{
    NSParameterAssert(cloudConnection);

    if (self = [super init]) {
        _cloudConnection = cloudConnection;
        _databaseAdapter = [[CBRDatabaseAdapter alloc] initWithInterface:interface threadingEnvironment:threadingEnvironment];
        _threadingEnvironment = threadingEnvironment;
    }
    return self;
}

#pragma mark - Instance methods

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    return [self fetchPersistentObjectsOfClass:persistentClass withPredicate:nil userInfo:nil completionHandler:completionHandler];
}

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(NSPredicate *)predicate
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    return [self fetchPersistentObjectsOfClass:persistentClass withPredicate:predicate userInfo:nil completionHandler:completionHandler];
}

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(NSPredicate *)predicate
                             userInfo:(NSDictionary *)userInfo
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    CBREntityDescription *entityDescription = [persistentClass cloudBridgeEntityDescription];
    NSParameterAssert(entityDescription);

    id<CBRPersistentObject> parent = nil;
    _CBRCloudBridgePredicateDescription *description = [[_CBRCloudBridgePredicateDescription alloc] initWithPredicate:predicate forEntity:entityDescription cloudBridge:self parent:&parent];

    if (parent && [self.databaseAdapter.interface conformsToProtocol:@protocol(_CBRPersistentStoreInterfaceInternal)]) {
        id<_CBRPersistentStoreInterfaceInternal> interface = (id<_CBRPersistentStoreInterfaceInternal>)self.databaseAdapter.interface;
        assert([interface hasPersistedObjects:@[ parent ]]);
    }

    __block NSString *inverseParentRelationship = nil;
    [self.cloudConnection fetchCloudObjectsForEntity:entityDescription withPredicate:predicate userInfo:userInfo completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        [self.databaseAdapter transactionWithObject:nil transaction:^id _Nullable(id  _Nullable object) {
            NSMutableArray *parsedPersistentObjects = [NSMutableArray array];
            NSMutableArray *persistentObjectsIdentifiers = [NSMutableArray array];

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
            id parentObject = nil;
            if (description.relationshipToUpdate && description.primaryKey) {
                CBRRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[description.relationshipToUpdate];
                parentObject = [self.databaseAdapter persistentObjectOfType:relationshipDescription.destinationEntity withPrimaryKey:description.primaryKey];
            }

            for (id<CBRCloudObject> cloudObject in fetchedObjects) {
                id<CBRPersistentObject>persistentObject = [self.cloudConnection.objectTransformer persistentObjectFromCloudObject:cloudObject
                                                                                                                        forEntity:entityDescription];

                if (persistentObject) {
                    [parsedPersistentObjects addObject:persistentObject];
                    [persistentObjectsIdentifiers addObject:[persistentObject valueForKey:cloudIdentifier]];

                    if (description.relationshipToUpdate) {
                        [persistentObject setValue:parentObject forKey:description.relationshipToUpdate];
                    }
                }
            }

            if (description.deleteEveryOtherObject) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT %K IN %@", cloudIdentifier, persistentObjectsIdentifiers];

                if (description.relationshipToUpdate) {
                    CBRRelationshipDescription *relationship = entityDescription.relationshipsByName[description.relationshipToUpdate];
                    inverseParentRelationship = relationship.inverseRelationship.name;

                    if (!relationship.toMany) {
                        NSPredicate *newPredicate = [NSPredicate predicateWithFormat:@"%K == %@", relationship.name, parentObject];
                        predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:@[ predicate, newPredicate ]];
                    }
                }

                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDescription.name];
                fetchRequest.predicate = predicate;

                NSError *error = nil;
                NSArray *objectsToBeDeleted = [self.databaseAdapter executeFetchRequest:fetchRequest error:&error];
                NSAssert(error == nil, @"error executing fetch request: %@", error);

                [self.databaseAdapter deletePersistentObjects:objectsToBeDeleted];
            }

            return parsedPersistentObjects;
        } completion:^(id  _Nullable object, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(object, error);
            }
        }];
    }];
}

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    [self createPersistentObject:persistentObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    [self reloadPersistentObject:persistentObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    [self savePersistentObject:persistentObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self deletePersistentObject:persistentObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    if ([self.databaseAdapter.interface conformsToProtocol:@protocol(_CBRPersistentStoreInterfaceInternal)]) {
        id<_CBRPersistentStoreInterfaceInternal> interface = (id<_CBRPersistentStoreInterfaceInternal>)self.databaseAdapter.interface;
        [interface saveChangedForPersistentObject:persistentObject error:NULL];
    }

    id<CBRCloudObject> cloudObject = [self.cloudConnection.objectTransformer cloudObjectFromPersistentObject:persistentObject];
    [self.cloudConnection createCloudObject:cloudObject forPersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        [self.databaseAdapter transactionWithObject:persistentObject transaction:^id _Nullable(id  _Nullable persistentObject) {
            [self.cloudConnection.objectTransformer updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];
            return persistentObject;
        } completion:^(id  _Nullable persistentObject, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(persistentObject, error);
            }
        }];
    }];
}

- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    if ([self.databaseAdapter.interface conformsToProtocol:@protocol(_CBRPersistentStoreInterfaceInternal)]) {
        id<_CBRPersistentStoreInterfaceInternal> interface = (id<_CBRPersistentStoreInterfaceInternal>)self.databaseAdapter.interface;
        [interface saveChangedForPersistentObject:persistentObject error:NULL];
    }

    [self.cloudConnection latestCloudObjectForPersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        [self.databaseAdapter transactionWithObject:persistentObject transaction:^id _Nullable(id  _Nullable persistentObject) {
            [self.cloudConnection.objectTransformer updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];
            return persistentObject;
        } completion:^(id  _Nullable persistentObject, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(persistentObject, error);
            }
        }];
    }];
}

- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler
{
    if ([self.databaseAdapter.interface conformsToProtocol:@protocol(_CBRPersistentStoreInterfaceInternal)]) {
        id<_CBRPersistentStoreInterfaceInternal> interface = (id<_CBRPersistentStoreInterfaceInternal>)self.databaseAdapter.interface;
        [interface saveChangedForPersistentObject:persistentObject error:NULL];
    }

    id<CBRCloudObject> cloudObject = [self.cloudConnection.objectTransformer cloudObjectFromPersistentObject:persistentObject];
    [self.cloudConnection saveCloudObject:cloudObject forPersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        [self.databaseAdapter transactionWithObject:persistentObject transaction:^id _Nullable(id  _Nullable persistentObject) {
            [self.cloudConnection.objectTransformer updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];
            return persistentObject;
        } completion:^(id  _Nullable persistentObject, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(persistentObject, error);
            }
        }];
    }];
}

- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler
{
    if ([self.databaseAdapter.interface conformsToProtocol:@protocol(_CBRPersistentStoreInterfaceInternal)]) {
        id<_CBRPersistentStoreInterfaceInternal> interface = (id<_CBRPersistentStoreInterfaceInternal>)self.databaseAdapter.interface;
        [interface saveChangedForPersistentObject:persistentObject error:NULL];
    }

    id<CBRCloudObject> cloudObject = [self.cloudConnection.objectTransformer cloudObjectFromPersistentObject:persistentObject];
    [self.cloudConnection deleteCloudObject:cloudObject forPersistentObject:persistentObject withUserInfo:userInfo completionHandler:^(NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(error);
            }
            return;
        }

        [self.databaseAdapter transactionWithObject:persistentObject transaction:^id _Nullable(id  _Nullable persistentObject) {
            [self.databaseAdapter deletePersistentObjects:@[ persistentObject ]];
            return nil;
        } completion:^(id  _Nullable object, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }];
}

#pragma mark - Private category implementation ()

@end
