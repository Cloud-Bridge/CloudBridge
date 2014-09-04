/**
 CloudBridge
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

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

@interface _CBRCloudBridgePredicateDescription : NSObject

@property (nonatomic, readonly) BOOL deleteEveryOtherObject;

@property (nonatomic, readonly) NSString *relationshipToUpdate;
@property (nonatomic, readonly) NSManagedObjectID *parentObjectID;

- (instancetype)initWithPredicate:(NSPredicate *)predicate forEntity:(NSEntityDescription *)entityDescription;

@end

@implementation _CBRCloudBridgePredicateDescription

- (instancetype)initWithPredicate:(NSPredicate *)predicate forEntity:(NSEntityDescription *)entityDescription
{
    if (self = [super init]) {
        if (!predicate || [predicate isEqual:[NSPredicate predicateWithValue:YES]]) {
            _deleteEveryOtherObject = YES;
        }

        [self _enumerateComparisionPredicatesInPredicate:predicate withBlock:^(NSComparisonPredicate *comparisionPredicate) {
            NSRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[comparisionPredicate.leftExpression.keyPath];
            NSManagedObject *managedObject = comparisionPredicate.rightExpression.constantValue;

            if (relationshipDescription && [managedObject isKindOfClass:[NSManagedObject class]]) {
                if (managedObject.hasChanges || managedObject.isInserted) {
                    NSError *saveError = nil;
                    [managedObject.managedObjectContext save:&saveError];
                    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
                }

                _relationshipToUpdate = relationshipDescription.name;
                _parentObjectID = managedObject.objectID;
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

#pragma mark - Setters and getters

- (NSManagedObjectContext *)mainThreadManagedObjectContext
{
    return self.coreDataStack.mainThreadManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    return self.coreDataStack.backgroundThreadManagedObjectContext;
}

#pragma mark - Initialization

- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection coreDataStack:(SLCoreDataStack *)coreDataStack
{
    NSParameterAssert(cloudConnection);
    
    if (self = [super init]) {
        _cloudConnection = cloudConnection;
        _coreDataStack = coreDataStack;
    }
    return self;
}

#pragma mark - Instance methods

- (void)fetchManagedObjectsOfType:(NSString *)entity
                    withPredicate:(NSPredicate *)predicate
                completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    [self fetchManagedObjectsOfType:entity withPredicate:predicate userInfo:nil completionHandler:completionHandler];
}

- (void)fetchManagedObjectsOfType:(NSString *)entity
                    withPredicate:(NSPredicate *)predicate
                         userInfo:(NSDictionary *)userInfo
                completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    NSEntityDescription *entityDescription = self.mainThreadManagedObjectContext.persistentStoreCoordinator.managedObjectModel.entitiesByName[entity];
    NSParameterAssert(entityDescription);

    _CBRCloudBridgePredicateDescription *description = [[_CBRCloudBridgePredicateDescription alloc] initWithPredicate:predicate forEntity:entityDescription];
    [self.cloudConnection fetchCloudObjectsForEntity:entityDescription withPredicate:predicate userInfo:userInfo completionHandler:^(NSArray *fetchedObjects, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
        [context performBlock:^{
            NSMutableArray *parsedManagedObjects = [NSMutableArray array];
            NSMutableArray *managedObjectsIdentifiers = [NSMutableArray array];

            NSString *cloudIdentifier = [self.cloudConnection.objectTransformer keyPathForCloudIdentifierOfEntitiyDescription:entityDescription];

            for (id<CBRCloudObject> cloudObject in fetchedObjects) {
                NSManagedObject *managedObject = [self.cloudConnection.objectTransformer managedObjectFromCloudObject:cloudObject
                                                                                                            forEntity:entityDescription
                                                                                               inManagedObjectContext:context];

                if (managedObject) {
                    [parsedManagedObjects addObject:managedObject];
                    [managedObjectsIdentifiers addObject:[managedObject valueForKey:cloudIdentifier]];

                    if (description.relationshipToUpdate) {
                        [managedObject setValue:[context objectWithID:description.parentObjectID] forKey:description.relationshipToUpdate];
                    }
                }
            }

            if (description.deleteEveryOtherObject) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityDescription.name];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"NOT %K IN %@", cloudIdentifier, managedObjectsIdentifiers];

                NSError *error = nil;
                NSArray *objectsToBeDeleted = [context executeFetchRequest:fetchRequest error:&error];
                NSAssert(error == nil, @"error fetching data: %@", error);

                for (NSManagedObject *managedObject in objectsToBeDeleted) {
                    [context deleteObject:managedObject];
                }
            }

            NSError *saveError = nil;
            [context save:&saveError];
            NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

            [self.mainThreadManagedObjectContext performBlock:^(NSArray *result) {
                if (completionHandler) {
                    completionHandler(result, nil);
                }
            } withObject:parsedManagedObjects];
        }];
    }];
}

- (void)createManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self createManagedObject:managedObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)reloadManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self reloadManagedObject:managedObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)saveManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self saveManagedObject:managedObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)deleteManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self deleteManagedObject:managedObject withUserInfo:nil completionHandler:completionHandler];
}

- (void)createManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (managedObject.hasChanges || managedObject.isInserted) {
        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    }

    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [self _transformManagedObject:managedObject toCloudObjectWithCompletionHandler:^(id<CBRCloudObject> cloudObject) {
        [self.cloudConnection createCloudObject:cloudObject forManagedObject:managedObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
            if (error) {
                if (completionHandler) {
                    completionHandler(nil, error);
                }
                return;
            }

            [context performBlock:^(NSManagedObject *backgroundManagedObject) {
                [self.cloudConnection.objectTransformer updateManagedObject:backgroundManagedObject withPropertiesFromCloudObject:cloudObject];

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                [self.mainThreadManagedObjectContext performBlock:^(NSManagedObject *mainManagedObject) {
                    if (completionHandler) {
                        completionHandler(mainManagedObject, nil);
                    }
                } withObject:backgroundManagedObject];
            } withObject:managedObject];
        }];
    }];
}

- (void)reloadManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (managedObject.hasChanges || managedObject.isInserted) {
        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    }

    [self.cloudConnection latestCloudObjectForManagedObject:managedObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
        if (error) {
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }

        NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
        [context performBlock:^(NSManagedObject *backgroundManagedObject) {
            [self.cloudConnection.objectTransformer updateManagedObject:backgroundManagedObject withPropertiesFromCloudObject:cloudObject];

            NSError *saveError = nil;
            [context save:&saveError];
            NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

            [self.mainThreadManagedObjectContext performBlock:^(NSManagedObject *mainManagedObject) {
                if (completionHandler) {
                    completionHandler(mainManagedObject, nil);
                }
            } withObject:backgroundManagedObject];
        } withObject:managedObject];
    }];
}

- (void)saveManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    if (managedObject.hasChanges || managedObject.isInserted) {
        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    }

    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [self _transformManagedObject:managedObject toCloudObjectWithCompletionHandler:^(id<CBRCloudObject> cloudObject) {
        [self.cloudConnection saveCloudObject:cloudObject forManagedObject:managedObject withUserInfo:userInfo completionHandler:^(id<CBRCloudObject> cloudObject, NSError *error) {
            if (error) {
                if (completionHandler) {
                    completionHandler(nil, error);
                }
                return;
            }

            [context performBlock:^(NSManagedObject *backgroundManagedObject) {
                [self.cloudConnection.objectTransformer updateManagedObject:backgroundManagedObject withPropertiesFromCloudObject:cloudObject];

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                [self.mainThreadManagedObjectContext performBlock:^(NSManagedObject *mainManagedObject) {
                    if (completionHandler) {
                        completionHandler(mainManagedObject, nil);
                    }
                } withObject:backgroundManagedObject];
            } withObject:managedObject];
        }];
    }];

}

- (void)deleteManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler
{
    if (managedObject.hasChanges || managedObject.isInserted) {
        NSError *saveError = nil;
        [managedObject.managedObjectContext save:&saveError];
        NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
    }

    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [self _transformManagedObject:managedObject toCloudObjectWithCompletionHandler:^(id<CBRCloudObject> cloudObject) {
        [self.cloudConnection deleteCloudObject:cloudObject forManagedObject:managedObject withUserInfo:userInfo completionHandler:^(NSError *error) {
            if (error) {
                if (completionHandler) {
                    completionHandler(error);
                }
                return;
            }

            [context performBlock:^(NSManagedObject *backgroundManagedObject) {
                [context deleteObject:backgroundManagedObject];

                NSError *saveError = nil;
                [context save:&saveError];
                NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(nil);
                    }
                });
            } withObject:managedObject];
        }];
    }];
}

#pragma mark - Private category implementation ()

- (void)_transformManagedObject:(NSManagedObject *)managedObject toCloudObjectWithCompletionHandler:(void(^)(id<CBRCloudObject> cloudObject))completionHandler
{
    NSParameterAssert(completionHandler);

    if (self.transformsManagedObjectsSynchronous) {
        return completionHandler([self.cloudConnection.objectTransformer cloudObjectFromManagedObject:managedObject]);
    }

    NSManagedObjectContext *context = self.backgroundThreadManagedObjectContext;
    [context performBlock:^(NSManagedObject *backgroundManagedObject) {
        id<CBRCloudObject> cloudObject = [self.cloudConnection.objectTransformer cloudObjectFromManagedObject:backgroundManagedObject];

        [managedObject.managedObjectContext performBlock:^{
            completionHandler(cloudObject);
        }];
    } withObject:managedObject];
}

@end
