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

#import <Realm/Realm.h>
#import <Foundation/Foundation.h>
#import <CloudBridge/CBRRealmObject.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
#import <CloudBridge/CBRPersistentObject.h>

@class CBRThreadingEnvironment;



@interface CBRRealmObject (CBRPersistentObject) <CBRPersistentObject>

/**
 Fetching object for a relationship queries the backend with `relationshipDescription.inverseRelationship == self`

 @warning: Only supported if `relationshipDescription.inverseRelationship.isToMany` is `NO`.
 */
- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;

/**
 Convenience method to transform a cloud object into a managed object.

 @warning Overriding this impelmentation is not recommended because all internal implementations go directly through the corresponding object transformer.
 */
+ (instancetype)persistentObjectFromCloudObject:(id<CBRCloudObject>)cloudObject;

@property (nonatomic, readonly) id<CBRCloudObject> cloudObjectRepresentation;

@end



/**
 @abstract  <#abstract comment#>
 */
@interface CBRRealmDatabaseAdapter : NSObject <CBRDatabaseAdapter>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) RLMRealmConfiguration *configuration;
@property (nonatomic, readonly) CBRThreadingEnvironment *threadingEnvironment;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration threadingEnvironment:(CBRThreadingEnvironment *(^)(void))threadingEnvironment NS_DESIGNATED_INITIALIZER;

@end
