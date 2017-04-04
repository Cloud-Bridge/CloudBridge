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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CBREntityDescription, CBRRelationshipDescription, CBRPersistentObjectCache, CBRPersistentObjectChange;
@protocol CBRPersistentObject;



NS_ASSUME_NONNULL_BEGIN

@protocol CBRNotificationToken <NSObject>
- (void)invalidate;

@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSArray *allObjects;

- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end



@protocol CBRPersistentStoreInterface <NSObject>

@property (nonatomic, readonly) NSArray<CBREntityDescription *> *entities;
@property (nonatomic, readonly) NSDictionary<NSString *, CBREntityDescription *> *entitiesByName;

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship;

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription;

- (void)beginWriteTransaction;
- (BOOL)commitWriteTransaction:(NSError **)error;

- (CBRPersistentObjectCache *)persistentObjectCacheForCurrentThread;

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error;
- (void)deletePersistentObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects;

- (id<CBRNotificationToken>)changesWithFetchRequest:(NSFetchRequest *)fetchRequest block:(void(^)(NSArray *objects, CBRPersistentObjectChange *change))block;

@end



@protocol _CBRPersistentStoreInterfaceInternal <NSObject>

- (BOOL)hasPersistedObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects;
- (BOOL)saveChangedForPersistentObject:(id<CBRPersistentObject>)persistentObject error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
