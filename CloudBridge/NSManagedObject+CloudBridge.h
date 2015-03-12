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

#import <CoreData/CoreData.h>
#import <CloudBridge/CBRCloudBridge.h>



@interface NSManagedObject (CloudBridge)

+ (CBRCloudBridge *)cloudBridge;
+ (void)setCloudBridge:(CBRCloudBridge *)cloudBridge;

@property (nonatomic, readonly) CBRCloudBridge *cloudBridge;

+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

/**
 Fetching object for a relationship queries the backend with `relationshipDescription.inverseRelationship == self`

 @warning: Only supported if `relationshipDescription.inverseRelationship.isToMany` is `NO`.
 */
- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler;

/**
 Convenience property to return the cloud representation for this object.
 
 @warning Overriding this property is not recommended because all internal implementations go directly through the corresponding object transformer.
 @note To change the resulting `cloudObjectRepresentation`, override `-[NSManagedObject prepareCloudObject:]`.
 */
@property (nonatomic, readonly) id /*<CBRCloudObject>*/ cloudObjectRepresentation;

/**
 Convenience method to transform a cloud object into a managed object.
 
 @warning Overriding this impelmentation is not recommended because all internal implementations go directly through the corresponding object transformer.
 */
+ (instancetype)managedObjectFromCloudObject:(id<CBRCloudObject>)cloudObject inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
