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

#import <CoreData/CoreData.h>
#import <CloudBridge/CBRCloudConnection.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>

@class CBRThreadingEnvironment;



NS_ASSUME_NONNULL_BEGIN

/**
 Bridges between a persistent database layer and a cloud backend.
 */
@interface CBRCloudBridge : NSObject

@property (nonatomic, readonly) id<CBRCloudConnection> cloudConnection;
@property (nonatomic, readonly) CBRDatabaseAdapter *databaseAdapter;
@property (nonatomic, readonly) CBRThreadingEnvironment *threadingEnvironment;

@property (nonatomic, assign) BOOL transformsPersistentObjectsOnMainThread;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection
                              interface:(id<CBRPersistentStoreInterface>)interface
                   threadingEnvironment:(CBRThreadingEnvironment *)threadingEnvironment NS_DESIGNATED_INITIALIZER;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                    completionHandler:(void(^_Nullable)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(nullable NSPredicate *)predicate
                    completionHandler:(void(^_Nullable)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(nullable NSPredicate *)predicate
                             userInfo:(nullable NSDictionary *)userInfo
                    completionHandler:(void(^_Nullable)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler;

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(nullable NSDictionary *)userInfo completionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(nullable NSDictionary *)userInfo completionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(nullable NSDictionary *)userInfo completionHandler:(void(^_Nullable)(id _Nullable persistentObject, NSError * _Nullable error))completionHandler;
- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(nullable NSDictionary *)userInfo completionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
