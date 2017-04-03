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

#import <objc/runtime.h>

#import "CBRThreadingEnvironment.h"
#import "CBRCoreDataInterface.h"
#import "CBRCloudBridge.h"
#import "CBREntityDescription.h"
#import "CBREntityDescription+CBRCoreDataInterface.h"
#import "CBRPersistentObjectCache.h"

static void class_swizzleSelector(Class class, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(class, originalSelector);
    Method newMethod = class_getInstanceMethod(class, newSelector);
    if(class_addMethod(class, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, newSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}



@implementation NSManagedObject (_CBRPersistentObject)

+ (void)load
{
    class_swizzleSelector(self, @selector(prepareForDeletion), @selector(__SLRESTfulCoreDataObjectCachePrepareForDeletion));
    class_implementProtocolExtension(self, @protocol(CBRPersistentObject), [CBRPersistentObjectPrototype class]);
}

- (void)__SLRESTfulCoreDataObjectCachePrepareForDeletion
{
    [self __SLRESTfulCoreDataObjectCachePrepareForDeletion];

    CBRCoreDataInterface *adapter = (CBRCoreDataInterface *)self.databaseAdapter.interface;
    assert([adapter isKindOfClass:[CBRCoreDataInterface class]] || !adapter);
    [[adapter cacheForManagedObjectContext:self.managedObjectContext] removePersistentObject:self];
}

@end



@interface CBRCoreDataInterface () <_CBRPersistentStoreInterfaceInternal>

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;

@end

@implementation CBRCoreDataInterface
@synthesize entities = _entities, entitiesByName = _entitiesByName;

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithStack:(CBRCoreDataStack *)stack
{
    if (self = [super init]) {
        _stack = stack;
        _managedObjectModel = stack.persistentStoreCoordinator.managedObjectModel;

        NSMutableArray<CBREntityDescription *> *result = [NSMutableArray array];

        for (NSEntityDescription *entity in self.managedObjectModel.entities) {
            [result addObject:[[CBREntityDescription alloc] initWithInterface:self coreDataEntityDescription:entity]];
        }

        _entities = result.copy;

        NSMutableDictionary<NSString *, CBREntityDescription *> *entitiesByName = [NSMutableDictionary dictionary];
        for (CBREntityDescription *description in _entities) {
            entitiesByName[description.name] = description;
        }

        _entitiesByName = entitiesByName.copy;
    }
    return self;
}

- (CBRPersistentObjectCache *)cacheForManagedObjectContext:(NSManagedObjectContext *)context
{
    @synchronized (context) {
        if (objc_getAssociatedObject(context, _cmd)) {
            return objc_getAssociatedObject(context, _cmd);
        }

        CBRPersistentObjectCache *cache = [[CBRPersistentObjectCache alloc] initWithInterface:self];
        objc_setAssociatedObject(context, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return cache;
    }
}

#pragma mark - _CBRPersistentStoreInterfaceInternal

- (BOOL)hasPersistedObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    for (NSManagedObject *object in persistentObjects) {
        if (object.isInserted) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)saveChangedForPersistentObject:(NSManagedObject *)persistentObject error:(NSError **)error
{
    if (persistentObject.isInserted || persistentObject.hasChanges) {
        return [persistentObject.managedObjectContext save:error];
    }

    return YES;
}

#pragma mark - CBRPersistentStoreInterface

- (CBRPersistentObjectCache *)persistentObjectCacheForCurrentThread
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [self cacheForManagedObjectContext:context];
}

- (void)beginWriteTransaction
{

}

- (BOOL)commitWriteTransaction:(NSError * _Nullable __autoreleasing *)error
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context save:error];
}

- (CBRRelationshipDescription *)inverseRelationshipForEntity:(CBREntityDescription *)entity relationship:(CBRRelationshipDescription *)relationship
{
    NSRelationshipDescription *relationshipDescription = self.managedObjectModel.entitiesByName[entity.name].relationshipsByName[relationship.name];
    NSParameterAssert(relationshipDescription);

    NSRelationshipDescription *inverseRelationship = relationshipDescription.inverseRelationship;
    NSParameterAssert(inverseRelationship);

    return self.entitiesByName[relationship.destinationEntityName].relationshipsByName[inverseRelationship.name];
}

- (__kindof id<CBRPersistentObject>)newMutablePersistentObjectOfType:(CBREntityDescription *)entityDescription
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    NSManagedObject *result = [NSEntityDescription insertNewObjectForEntityForName:entityDescription.name inManagedObjectContext:context];

    return result;
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error
{
    assert(self.entitiesByName[fetchRequest.entityName] != nil);
    
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;
    return [context executeFetchRequest:fetchRequest error:error];
}

- (void)deletePersistentObjects:(NSArray<NSManagedObject *> *)persistentObjects
{
    NSManagedObjectContext *context = [NSThread currentThread].isMainThread ? self.stack.mainThreadManagedObjectContext : self.stack.backgroundThreadManagedObjectContext;

    for (NSManagedObject *managedObject in persistentObjects) {
        [context deleteObject:managedObject];
    }
}

@end
