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

#import <CoreData/CoreData.h>
#import <CBRCloudConnection.h>
#import <CBRDatabaseAdapter.h>
#import <SLCoreDataStack.h>



/**
 Bridges between a persistent database layer and a cloud backend.
 */
@interface CBRCloudBridge : NSObject

@property (nonatomic, readonly) id<CBRCloudConnection> cloudConnection;
@property (nonatomic, readonly) id<CBRDatabaseAdapter> databaseAdapter;

@property (nonatomic, assign) BOOL transformsPersistentObjectsOnMainThread;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection
                        databaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(NSPredicate *)predicate
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchPersistentObjectsOfClass:(Class)persistentClass
                        withPredicate:(NSPredicate *)predicate
                             userInfo:(NSDictionary *)userInfo
                    completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)createPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)reloadPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)savePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id persistentObject, NSError *error))completionHandler;
- (void)deletePersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler;

@end



@interface CBRCloudBridge (Deprecated)

@property (nonatomic, readonly) NSManagedObjectContext *mainThreadManagedObjectContext DEPRECATED_ATTRIBUTE;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundThreadManagedObjectContext DEPRECATED_ATTRIBUTE;

@property (nonatomic, readonly) SLCoreDataStack *coreDataStack UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection coreDataStack:(SLCoreDataStack *)coreDataStack DEPRECATED_ATTRIBUTE;

@end
