/**
 CloudBridge
 Copyright (c) 2018 Layered Pieces gUG

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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>

@class CBREntityDescription, CBRRelationshipDescription, CBRPersistentObjectCache, CBRThreadingEnvironment;
@protocol CBRPersistentObject;



NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface CBRDatabaseAdapter : NSObject

@property (nonatomic, readonly) id<CBRPersistentStoreInterface> interface;
@property (nonatomic, readonly) CBRThreadingEnvironment *threadingEnvironment;

@property (nonatomic, readonly) NSArray<CBREntityDescription *> *entities;
@property (nonatomic, readonly) NSDictionary<NSString *, CBREntityDescription *> *entitiesByName;

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface threadingEnvironment:(CBRThreadingEnvironment *)threadingEnvironment;

@end



@interface CBRDatabaseAdapter (Transactions)

- (void)inlineTransaction:(NS_NOESCAPE dispatch_block_t)transaction;

- (void)transactionWithBlock:(dispatch_block_t)transaction;
- (void)transactionWithBlock:(dispatch_block_t)transaction completion:(void(^_Nullable)(NSError *error))completion;
- (void)transactionWithObject:(nullable id)object
                  transaction:(id _Nullable(^)(id _Nullable object))transaction
                   completion:(void(^_Nullable)(id _Nullable object, NSError * _Nullable error))completion;

- (void)unsafeTransactionWithObject:(nullable id)object transaction:(void(^)(id _Nullable object))transaction;
- (void)unsafeTransactionWithObject:(nullable id)object transaction:(id _Nullable(^)(id _Nullable object))transaction completion:(void(^_Nullable)(id _Nullable object))completion;

@end



@interface CBRDatabaseAdapter (CBRPersistentStoreInterface)

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription;

- (__kindof id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey;

- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute;

@property (nonatomic, readonly) NSArray<CBREntityDescription *> *entities;
- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship;

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error;
- (void)deletePersistentObjects:(id)persistentObjects;

@end

NS_ASSUME_NONNULL_END
