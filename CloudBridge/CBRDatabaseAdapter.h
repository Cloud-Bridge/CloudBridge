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

@class CBREntityDescription, CBRRelationshipDescription;
@protocol CBRPersistentObject;



/**
 @abstract  <#abstract comment#>
 */
@protocol CBRDatabaseAdapter <NSObject>

@property (nonatomic, readonly) NSArray<CBREntityDescription *> *entities;

- (CBREntityDescription *)entityDescriptionForClass:(Class)persistentClass;
- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship;

- (BOOL)hasPersistentObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects;
- (id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription;

- (id<CBRPersistentObject>)persistentObjectOfType:(CBREntityDescription *)entityDescription withPrimaryKey:(id)primaryKey;

- (NSDictionary *)indexedObjectsOfType:(CBREntityDescription *)entityDescription withValues:(NSSet *)values forAttribute:(NSString *)attribute;

- (NSArray *)fetchObjectsOfType:(CBREntityDescription *)entityDescription withPredicate:(NSPredicate *)predicate;

- (void)mutatePersistentObject:(id<CBRPersistentObject>)persistentObject
                     withBlock:(void(^)(id<CBRPersistentObject> persistentObject))mutation
                    completion:(void(^)(id<CBRPersistentObject> persistentObject, NSError *error))completion;

- (void)mutatePersistentObjects:(NSArray<id<CBRPersistentObject>> *)persistentObject
                     withBlock:(NSArray *(^)(NSArray<id<CBRPersistentObject>> *persistentObjects))mutation
                    completion:(void(^)(NSArray<id<CBRPersistentObject>> *persistentObjects, NSError *error))completion;

- (void)deletePersistentObjects:(NSArray<id<CBRPersistentObject>> *)persistentObjects;

@optional
- (void)saveChangesForPersistentObject:(id<CBRPersistentObject>)persistentObject;

@end
