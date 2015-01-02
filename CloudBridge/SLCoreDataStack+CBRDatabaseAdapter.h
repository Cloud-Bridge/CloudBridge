//
//  SLCoreDataStack+CBRDatabaseAdapter.h
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <SLCoreDataStack.h>
#import <CBRDatabaseAdapter.h>
#import <CBRPersistentObject.h>

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
+ (instancetype)managedObjectFromCloudObject:(id<CBRCloudObject>)cloudObject inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Convenience property to return the cloud representation for this object.

 @warning Overriding this property is not recommended because all internal implementations go directly through the corresponding object transformer.
 @note To change the resulting `cloudObjectRepresentation`, override `-[NSManagedObject prepareCloudObject:]`.
 */
@property (nonatomic, readonly) id /*<CBRCloudObject>*/ cloudObjectRepresentation;

@end


@interface SLCoreDataStack (CBRDatabaseAdapter) <CBRDatabaseAdapter>

@end
