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

@import ObjectiveC.runtime;
#import "NSManagedObject+CloudBridge.h"



@implementation NSManagedObject (CloudBridge)

- (id)cloudObjectRepresentation
{
    return [self.cloudBridge.cloudConnection.objectTransformer cloudObjectFromManagedObject:self];
}

+ (CBRCloudBridge *)cloudBridge
{
    CBRCloudBridge *cloudBridge = objc_getAssociatedObject(self, @selector(cloudBridge));
    if (cloudBridge) {
        return cloudBridge;
    }

    if (self == [NSManagedObject class]) {
        [NSException raise:NSInternalInconsistencyException format:@"No cloud bridge found"];
        return nil;
    }

    return [[self superclass] cloudBridge];
}

+ (void)setCloudBridge:(CBRCloudBridge *)cloudBridge
{
    objc_setAssociatedObject(self, @selector(cloudBridge), cloudBridge, OBJC_ASSOCIATION_RETAIN);
}

- (CBRCloudBridge *)cloudBridge
{
    return [self.class cloudBridge];
}

+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    Class class = self;
    while (class != [class class]) {
        class = [class class];
    }

    [[self cloudBridge] fetchManagedObjectsOfType:NSStringFromClass(class)
                                    withPredicate:predicate
                                completionHandler:completionHandler];
}

- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSRelationshipDescription *relationshipDescription = self.entity.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(!relationshipDescription.isToMany);

    [self fetchObjectsForRelationship:relationship withCompletionHandler:^(NSArray *objects, NSError *error) {
        if (completionHandler) {
            completionHandler(objects.lastObject, error);
        }
    }];
}

- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler
{
    NSRelationshipDescription *relationshipDescription = self.entity.relationshipsByName[relationship];
    NSParameterAssert(relationshipDescription);
    NSParameterAssert(relationshipDescription.inverseRelationship);
    NSParameterAssert(!relationshipDescription.inverseRelationship.isToMany);

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", relationshipDescription.inverseRelationship.name, self];
    [self.cloudBridge fetchManagedObjectsOfType:relationshipDescription.inverseRelationship.entity.name
                                  withPredicate:predicate
                              completionHandler:completionHandler];
}

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge createManagedObject:self withCompletionHandler:completionHandler];
}

- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge reloadManagedObject:self withCompletionHandler:completionHandler];
}

- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    [self.cloudBridge saveManagedObject:self withCompletionHandler:completionHandler];
}

- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler
{
    [self.cloudBridge deleteManagedObject:self withCompletionHandler:completionHandler];
}

+ (instancetype)managedObjectFromCloudObject:(id<CBRCloudObject>)cloudObject inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:managedObjectContext];
    NSParameterAssert(entity);

    return [[self cloudBridge].cloudConnection.objectTransformer managedObjectFromCloudObject:cloudObject forEntity:entity inManagedObjectContext:managedObjectContext];
}

@end
