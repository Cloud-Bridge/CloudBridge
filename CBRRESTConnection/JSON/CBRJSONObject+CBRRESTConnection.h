//
//  CBRJSONObject+REST.h
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRJSONObject.h>

@class AFHTTPSessionManager;



NS_ASSUME_NONNULL_BEGIN

@interface CBRJSONObject (CBRPersistentObjectQueryInterface)

@property (nonatomic, class, nullable) CBRRESTConnection *restConnection;
@property (nonatomic, readonly) CBRRESTConnection *restConnection;

+ (void)fetchObject:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler;
+ (void)fetchObjects:(NSString *)path withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchRelation:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(id object, NSError *error))completionHandler;
- (void)fetchRelations:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;

- (void)create:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reload:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)save:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)delete:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
