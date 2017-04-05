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

#import "CBRDatabaseAdapter.h"

#import "CBRCloudBridge.h"
#import "CBRCloudConnection.h"
#import "CBREntityDescription.h"
#import "CBRThreadingEnvironment.h"
#import "CBRPersistentObjectCache.h"

@interface CBRDatabaseAdapter ()

@end



@implementation CBRDatabaseAdapter
@synthesize entities = _entities;

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface threadingEnvironment:(nonnull CBRThreadingEnvironment *)threadingEnvironment
{
    if (self = [super init]) {
        _interface = interface;
        _threadingEnvironment = threadingEnvironment;

        _entities = interface.entities;
        _entitiesByName = interface.entitiesByName;
    }
    return self;
}

@end



@implementation CBRDatabaseAdapter (Transactions)

- (void)inlineTransaction:(NS_NOESCAPE dispatch_block_t)transaction
{
    [self.interface beginWriteTransaction];
    transaction();
    [self.interface commitWriteTransaction:NULL];
}

- (void)transactionWithBlock:(dispatch_block_t)transaction
{
    NSArray<NSString *> *callStack = [NSThread callStackSymbols];

    [self transactionWithBlock:transaction completion:^(NSError * _Nonnull error) {
        if (error != nil) {
            [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@, call stack: %@", error, callStack];
        }
    }];
}

- (void)transactionWithBlock:(dispatch_block_t)transaction completion:(void (^ _Nullable)(NSError * _Nonnull))completion
{
    [self transactionWithObject:nil transaction:^id _Nullable(id  _Nullable object) {
        transaction();
        return nil;
    } completion:^(id  _Nullable object, NSError * _Nullable error) {
        if (completion != nil) {
            completion(error);
        } else {
            if (error != nil) {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to main thread %@", error];
            }
        }
    }];
}

- (void)transactionWithObject:(id)object transaction:(id  _Nullable (^)(id _Nullable))transaction completion:(void (^)(id _Nullable, NSError * _Nullable))completion
{
    [self.threadingEnvironment moveObject:object toThread:CBRThreadBackground completion:^(id _Nullable object, NSError * _Nullable error) {
        if (error != nil) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, error);
                });
            } else {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to background thread %@", error];
            }
            return;
        }

        [self.interface beginWriteTransaction];
        id result = transaction(object);

        NSError *saveError = nil;
        [self.interface commitWriteTransaction:&error];

        if (saveError != nil) {
            if (completion != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil, saveError);
                });
            } else {
                [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@", error];
            }
            return;
        }

        [self.threadingEnvironment moveObject:result toThread:CBRThreadMain completion:^(id  _Nullable object, NSError * _Nullable error) {
            if (completion != nil) {
                completion(object, error);
            } else {
                if (error != nil) {
                    [NSException raise:NSInternalInconsistencyException format:@"uncaught error moving to main thread %@", error];
                }
            }
        }];
    }];
}

- (void)unsafeTransactionWithObject:(id)object transaction:(void(^)(id _Nullable))transaction
{
    [self unsafeTransactionWithObject:object transaction:^id _Nullable(id  _Nullable object) {
        transaction(object);
        return nil;
    } completion:nil];
}

- (void)unsafeTransactionWithObject:(id)object transaction:(id  _Nullable (^)(id _Nullable))transaction completion:(void (^)(id _Nullable))completion
{
    NSArray<NSString *> *callStack = [NSThread callStackSymbols];

    [self transactionWithObject:object transaction:transaction completion:^(id  _Nullable object, NSError * _Nullable error) {
        if (error != nil) {
            [NSException raise:NSInternalInconsistencyException format:@"uncaught error after transaction %@, call stack: %@", error, callStack];
        }

        if (completion != nil) {
            completion(object);
        }
    }];
}

@end



@implementation CBRDatabaseAdapter (CBRPersistentStoreInterface)

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    return [self.interface newMutablePersistentObjectOfType:entityDescription];
}

- (__kindof id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey
{
    if (primaryKey == nil) {
        return nil;
    }

    NSString *attribute = [[NSClassFromString(entityDescription.name) cloudBridge].cloudConnection.objectTransformer primaryKeyOfEntitiyDescription:entityDescription];
    NSParameterAssert(attribute);

    return [[self.interface persistentObjectCacheOnCurrentThreadForEntity:entityDescription] objectOfType:entityDescription.name withValue:primaryKey forAttribute:attribute];
}

- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
    return [[self.interface persistentObjectCacheOnCurrentThreadForEntity:entityDescription] indexedObjectsOfType:entityDescription.name withValues:values forAttribute:attribute];
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    return [self.interface inverseRelationshipForEntity:entity relationship:relationship];
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    return [self.interface executeFetchRequest:fetchRequest error:error];
}

- (void)deletePersistentObjects:(id)persistentObjects
{
    if ([persistentObjects isKindOfClass:[NSArray class]]) {
        [self.interface deletePersistentObjects:persistentObjects];
    } else {
        [self.interface deletePersistentObjects:@[ persistentObjects ]];
    }
}

@end
