/**
 CBRPersistentObjectCache
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

#import <objc/runtime.h>

#import "CBRPersistentObjectCache.h"
#import "CBREnumaratableCache.h"



@interface CBRPersistentObjectCache ()
@property (nonatomic, strong) CBREnumaratableCache *internalCache;
@end



@implementation CBRPersistentObjectCache

#pragma mark - Initialization

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface
{
    if (self = [super init]) {
        _interface = interface;
        _internalCache = [[CBREnumaratableCache alloc] init];
    }
    return self;
}

#pragma mark - Instance methods

- (id)objectOfType:(NSString *)type withValue:(id)value forAttribute:(NSString *)attribute
{
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
    NSArray *fetchedObjects = [self.interface executeFetchRequest:fetchRequest error:&error];
    NSAssert(error == nil, @"error fetching data: %@", error);

    if (fetchedObjects.count > 0) {
        NSManagedObject *managedObject = fetchedObjects.firstObject;
        [self.internalCache setObject:managedObject forKey:cacheKey];
        return managedObject;
    }

    return nil;
}

- (NSDictionary *)indexedObjectsOfType:(NSString *)type withValues:(NSSet *)values forAttribute:(NSString *)attribute
{
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
    NSArray *fetchedObjects = [self.interface executeFetchRequest:request error:&error];
    NSAssert(error == nil, @"error while fetching: %@", error);

    for (id managedObject in fetchedObjects) {
        id value = [managedObject valueForKey:attribute];
        NSString *cacheKey = [NSString stringWithFormat:@"%@#%@", type, value];

        [self.internalCache setObject:managedObject forKey:cacheKey];
        indexedObjects[value] = managedObject;
    }

    return [indexedObjects copy];
}

- (void)removePersistentObject:(id<CBRPersistentObject>)managedObject
{
    NSMutableSet *keysToRemove = [NSMutableSet set];

    for (id key in self.internalCache) {
        if ([self.internalCache objectForKey:key] == managedObject) {
            [keysToRemove addObject:key];
        }
    }

    for (id key in keysToRemove) {
        [self.internalCache removeObjectForKey:key];
    }
}

#pragma mark - Private category implementation ()

@end
