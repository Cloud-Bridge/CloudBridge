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
@property (nonatomic, nullable, readonly) CBRRESTConnection *restConnection;

+ (void)fetchObject:(NSString *)path withCompletionHandler:(void(^)(id _Nullable fetchedObject, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
+ (void)fetchObjects:(NSString *)path withCompletionHandler:(void(^)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;

- (void)fetchRelation:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(id _Nullable object, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)fetchRelations:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(NSArray * _Nullable objects, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;

- (void)create:(NSString *)path withCompletionHandler:(void(^)(id _Nullable object, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)reload:(NSString *)path withCompletionHandler:(void(^)(id _Nullable object, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)save:(NSString *)path withCompletionHandler:(void(^)(id _Nullable object, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)delete:(NSString *)path withCompletionHandler:(void(^)(NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
