//
//  CBRJSONModel.h
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRThreadingEnvironment.h>

@class CBRRESTConnection;

NS_ASSUME_NONNULL_BEGIN

@protocol CBRJSONObject <NSObject>
@end



@interface CBRJSONObject : NSObject <NSSecureCoding, NSCopying, CBRThreadTransferable>

@property (nonatomic, class, nullable) CBRRESTConnection *restConnection;
@property (nonatomic, readonly) CBRRESTConnection *restConnection;

+ (NSDictionary<NSString *, Class> *)propertyClassMapping;
+ (NSArray<NSString *> *)serializableProperties;
+ (NSDictionary<NSString *, Class> *)relationMapping;

@property (nonatomic, readonly) NSDictionary<NSString *, id> *jsonRepresentation;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (id)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (BOOL)patchWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end



@interface CBRJSONObject (CBRPersistentObjectQueryInterface)

+ (void)fetchObject:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler;
+ (void)fetchObjects:(NSString *)path withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchRelation:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(id object, NSError *error))completionHandler;
- (void)fetchRelations:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;

- (void)create:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reload:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)save:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)delete:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler;

@end



@interface CBRJSONObjectValueTransformer : NSValueTransformer

+ (Class)destinationClass;

@end

NS_ASSUME_NONNULL_END
