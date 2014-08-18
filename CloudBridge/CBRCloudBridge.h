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

@import CoreData;

#import <CBRCloudConnection.h>
#import <SLCoreDataStack.h>



/**
 Bridges between the CoreData stack and the cloud backend.
 */
@interface CBRCloudBridge : NSObject

@property (nonatomic, readonly) id<CBRCloudConnection> cloudConnection;
@property (nonatomic, readonly) SLCoreDataStack *coreDataStack;

@property (nonatomic, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundThreadManagedObjectContext;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCloudConnection:(id<CBRCloudConnection>)cloudConnection
                          coreDataStack:(SLCoreDataStack *)coreDataStack NS_DESIGNATED_INITIALIZER;

- (void)fetchManagedObjectsOfType:(NSString *)entity
                    withPredicate:(NSPredicate *)predicate
                completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchManagedObjectsOfType:(NSString *)entity
                    withPredicate:(NSPredicate *)predicate
                         userInfo:(NSDictionary *)userInfo
                completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)createManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reloadManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteManagedObject:(NSManagedObject *)managedObject withCompletionHandler:(void(^)(NSError *error))completionHandler;

- (void)createManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reloadManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler;

@end
