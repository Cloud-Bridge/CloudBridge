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

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRCoreDataStack.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
#import <CloudBridge/CBRPersistentObject.h>



@interface NSManagedObject (CBRPersistentObject) <CBRPersistentObject>

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
@interface CBRCoreDataDatabaseAdapter : NSObject <CBRDatabaseAdapter>

@property (nonatomic, readonly) CBRCoreDataStack *coreDataStack;
@property (nonatomic, readonly) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, readonly) NSManagedObjectContext *backgroundThreadContext;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCoreDataStack:(CBRCoreDataStack *)coreDataStack NS_DESIGNATED_INITIALIZER;

@end
