//
//  CBRTestConnection.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <CloudBridge.h>

@interface NSDictionary () <CBRCloudObject>
@end

@interface CBRTestDictionaryTransformer : NSObject <CBRManagedObjectToCloudObjectTransformer>

@end



/**
 @abstract  <#abstract comment#>
 */
@interface CBRTestConnection : NSObject <CBRCloudConnection>

@property (nonatomic, readonly) CBRTestDictionaryTransformer *objectTransformer;

@property (nonatomic, strong) NSArray *objectsToReturn;
- (void)fetchCloudObjectsForEntity:(NSEntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                 completionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)latestCloudObjectForManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(id<CBRCloudObject> cloudObject, NSError *error))completionHandler;
- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forManagedObject:(NSManagedObject *)managedObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void(^)(NSError *error))completionHandler;

@end
