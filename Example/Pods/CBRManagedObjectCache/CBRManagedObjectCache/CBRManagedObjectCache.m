/**
 CBRManagedObjectCache
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

#import "CBRManagedObjectCache.h"
#import <CBREnumaratableCache.h>

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

@implementation NSManagedObject (CBRManagedObjectCache)

+ (void)load
{
    class_swizzleSelector(self, @selector(prepareForDeletion), @selector(__SLRESTfulCoreDataObjectCachePrepareForDeletion));
}

- (void)__SLRESTfulCoreDataObjectCachePrepareForDeletion
{
    [self __SLRESTfulCoreDataObjectCachePrepareForDeletion];
    [self.managedObjectContext.cbr_cache removeManagedObject:self];
}

@end



@interface CBRManagedObjectCache ()
@property (nonatomic, strong) CBREnumaratableCache *internalCache;
@end



@implementation CBRManagedObjectCache

#pragma mark - Initialization

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    if (self = [super init]) {
        _managedObjectContext = context;
        _internalCache = [[CBREnumaratableCache alloc] init];
    }
    return self;
}

#pragma mark - Instance methods

- (id)objectOfType:(NSString *)type withValue:(id)value forAttribute:(NSString *)attribute
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSParameterAssert(context.persistentStoreCoordinator.managedObjectModel.entitiesByName[type]);
    if (!value) {
        return nil;
    }

    NSString *cacheKey = [NSString stringWithFormat:@"%@#%@", type, value];
    if ([self.internalCache objectForKey:cacheKey]) {
        return [self.internalCache objectForKey:cacheKey];
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:type];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", attribute, value];
    fetchRequest.fetchLimit = 1;

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSAssert(error == nil, @"error fetching data: %@", error);

    if (fetchedObjects.count > 0) {
        NSManagedObject *managedObject = fetchedObjects.firstObject;
        [self.internalCache setObject:managedObject forKey:cacheKey];
        return managedObject;
    }

    return nil;
}

- (id)objectOfClass:(Class)class withValue:(id)value forAttribute:(SEL)attribute
{
    return [self objectOfType:NSStringFromClass(class) withValue:value forAttribute:NSStringFromSelector(attribute)];
}

- (NSDictionary *)indexedObjectsOfType:(NSString *)type withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSParameterAssert(context.persistentStoreCoordinator.managedObjectModel.entitiesByName[type]);
    if (values.count == 0) {
        return @{};
    }

    NSMutableDictionary *indexedObjects = [NSMutableDictionary dictionary];
    NSMutableSet *valuesToFetch = [NSMutableSet set];

    for (id value in values) {
        NSString *key = [NSString stringWithFormat:@"%@#%@", type, value];
        id cachedObject = [self.internalCache objectForKey:key];

        if (cachedObject) {
            indexedObjects[value] = cachedObject;
        } else {
            [valuesToFetch addObject:value];
        }
    }

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:type];
    request.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", attribute, valuesToFetch];

    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);

    for (NSManagedObject *managedObject in fetchedObjects) {
        id value = [managedObject valueForKey:attribute];
        NSString *cacheKey = [NSString stringWithFormat:@"%@#%@", type, value];

        [self.internalCache setObject:managedObject forKey:cacheKey];
        indexedObjects[value] = managedObject;
    }

    return [indexedObjects copy];
}

- (NSDictionary *)indexedObjectsOfClass:(Class)class withValues:(NSSet *)values forAttribute:(SEL)attribute
{
    return [self indexedObjectsOfType:NSStringFromClass(class) withValues:values forAttribute:NSStringFromSelector(attribute)];
}

- (void)removeManagedObject:(NSManagedObject *)managedObject
{
    NSMutableSet *keysToRemove = [NSMutableSet set];

    for (id key in self.internalCache) {
        if ([self.internalCache objectForKey:key]) {
            [keysToRemove addObject:key];
        }
    }

    for (id key in keysToRemove) {
        [self.internalCache removeObjectForKey:key];
    }
}

#pragma mark - Private category implementation ()

@end



@implementation NSManagedObjectContext (CBRManagedObjectCache)

- (CBRManagedObjectCache *)cbr_cache
{
    CBRManagedObjectCache *cache = objc_getAssociatedObject(self, _cmd);

    if (!cache) {
        cache = [[CBRManagedObjectCache alloc] initWithManagedObjectContext:self];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return cache;
}

@end