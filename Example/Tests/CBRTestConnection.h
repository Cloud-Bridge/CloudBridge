//
//  CBRTestConnection.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <CloudBridge/CloudBridge.h>
#import <CloudBridge/CBRCoreDataDatabaseAdapter.h>

@interface NSDictionary () <CBRCloudObject>
@end

@interface CBRTestDictionaryTransformer : NSObject <CBRCloudObjectTransformer>

@end



/**
 @abstract  <#abstract comment#>
 */
@interface CBRTestConnection : NSObject <CBRCloudConnection, CBROfflineCapableCloudConnection>

@property (nonatomic, readonly) CBRTestDictionaryTransformer *objectTransformer;

@property (nonatomic, strong) NSArray *objectsToReturn;
@property (nonatomic, strong) NSError *errorToReturn;

- (void)fetchCloudObjectsForEntity:(NSEntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                          userInfo:(NSDictionary *)userInfo
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)latestCloudObjectForPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler;

@end
