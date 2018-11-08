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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CBRCloudBridge, CBREntityDescription, CBRDatabaseAdapter;
@protocol CBRCloudObject;



void class_implementProtocolExtension(Class klass, Protocol *protocol, Class prototype);



@protocol CBRPersistentIdentifier <NSObject> @end

@interface NSNumber (CBRPersistentIdentifier) <CBRPersistentIdentifier> @end
@interface NSString (CBRPersistentIdentifier) <CBRPersistentIdentifier> @end



@protocol CBRPersistentObjectSubclassHooks

/**
 Called when inserted after a cloud fetch.
 */
- (void)awakeFromCloudFetch;

/**
 Called right before the framework tries to map the cloud object to a managed object.
 */
+ (__kindof id<CBRCloudObject>)prepareForUpdateWithCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

/**
 Called right before an update is started.
 */
- (void)prepareForUpdateWithCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

/**
 Called after the framework updated the managed object with the cloud object.
 */
- (void)finalizeUpdateWithCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

/**
 Gives an instance the change to prepare a cloud object right before its being sent over the wire.
 */
- (__kindof id<CBRCloudObject>)finalizeCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

/**
 Sets a value for a key for a specific cloud object.
 */
- (void)setCloudValue:(nullable id)value forKey:(NSString *)key fromCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

/**
 Returns a cloud value for a given key.
 */
- (nullable id)cloudValueForKey:(NSString *)key;

@end



@protocol CBRPersistentObjectQueryInterface

+ (nullable instancetype)objectWithRemoteIdentifier:(nullable id<CBRPersistentIdentifier>)identifier;
+ (NSDictionary *)objectsWithRemoteIdentifiers:(nullable NSArray<id<CBRPersistentIdentifier>> *)identifiers;

+ (instancetype)newCloudBrideObject;

+ (void)fetchObjectsMatchingPredicate:(nullable NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler;

/**
 Fetching object for a relationship queries the backend with `relationshipDescription.inverseRelationship == self`

 @warning: Only supported if `relationshipDescription.inverseRelationship.isToMany` is `NO`.
 */
- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^_Nullable)(id _Nullable object, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^_Nullable)(NSArray * _Nullable objects, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;

- (void)createWithCompletionHandler:(void(^_Nullable)(id _Nullable managedObject, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)reloadWithCompletionHandler:(void(^_Nullable)(id _Nullable managedObject, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)saveWithCompletionHandler:(void(^_Nullable)(id _Nullable managedObject, NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;
- (void)deleteWithCompletionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler NS_REFINED_FOR_SWIFT;

@end



/**
 @abstract  <#abstract comment#>
 */
@protocol CBRPersistentObject <CBRPersistentObjectSubclassHooks, CBRPersistentObjectQueryInterface, NSObject>

@property (nonatomic, class, nullable) CBRCloudBridge *cloudBridge;
@property (nonatomic, nullable, readonly) CBRCloudBridge *cloudBridge;

@property (nonatomic, class, nullable, readonly) CBRDatabaseAdapter *databaseAdapter;
@property (nonatomic, nullable, readonly) CBRDatabaseAdapter *databaseAdapter;

@property (nonatomic, class, nullable, readonly) CBREntityDescription *cloudBridgeEntityDescription;
@property (nonatomic, nullable, readonly) CBREntityDescription *cloudBridgeEntityDescription;

/**
 Convenience property to return the cloud representation for this object.

 @warning Overriding this property is not recommended because all internal implementations go directly through the corresponding object transformer.
 @note To change the resulting `cloudObjectRepresentation`, override `-[CBRPersistentObjectQueryInterface prepareCloudObject:]`.
 */
@property (nonatomic, readonly) id<CBRCloudObject> cloudObjectRepresentation;

/**
 Convenience method to transform a cloud object into a managed object.

 @warning Overriding this impelmentation is not recommended because all internal implementations go directly through the corresponding object transformer.
 */
+ (instancetype)persistentObjectFromCloudObject:(__kindof id<CBRCloudObject>)cloudObject;

- (nullable id)valueForKey:(NSString *)key;
- (nullable id)valueForKeyPath:(NSString *)keyPath;
- (void)setValue:(nullable id)value forKey:(NSString *)key;

@end



__attribute__((objc_subclassing_restricted))
@interface CBRPersistentObjectPrototype : NSObject <CBRPersistentObject>

+ (BOOL)resolveRelationshipForSelector:(SEL)selector inClass:(Class)klass;

@end

NS_ASSUME_NONNULL_END
