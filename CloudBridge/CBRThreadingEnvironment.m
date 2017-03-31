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

#import "CBRThreadingEnvironment.h"
#import <CoreData/CoreData.h>

#if CBRRealmAvailable
#import <CloudBridge/CBRRealmObject.h>
#endif



@implementation CBRThreadingEnvironment

#if CBRCoreDataAvailable
- (instancetype)initWithCoreDataAdapter:(CBRCoreDataDatabaseAdapter *)coreDataAdapter
{
    if (self = [super init]) {
        _coreDataAdapter = coreDataAdapter;
    }
    return self;
}
#endif

#if CBRRealmAvailable
- (instancetype)initWithRealmAdapter:(CBRRealmDatabaseAdapter *)realmAdapter
{
    if (self = [super init]) {
        _realmAdapter = realmAdapter;
        _queue = dispatch_queue_create("de.sparrow-labs.CloudBridge.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}
#endif

#if CBRRealmAvailable && CBRCoreDataAvailable
- (instancetype)initWithCoreDataAdapter:(CBRCoreDataDatabaseAdapter *)coreDataAdapter realmAdapter:(CBRRealmDatabaseAdapter *)realmAdapter
{
    if (self = [super init]) {
        _coreDataAdapter = coreDataAdapter;
        _realmAdapter = realmAdapter;
    }
    return self;
}
#endif

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithQueue:(dispatch_queue_t)queue
{
    if (self = [super init]) {
        _queue = queue;
    }
    return self;
}

- (void)moveObject:(nullable id)object toThread:(CBRThread)thread completion:(void(^)(id _Nullable object, NSError * _Nullable error))completion
{
    id reference = [self _threadSafeReferenceForObject:object];

    dispatch_block_t block = ^{
        NSError *error = nil;
        id result = [self _resolveThreadSafeReference:reference onThread:thread error:&error];
        completion(result, error);
    };

#if CBRCoreDataAvailable
    if (self.coreDataAdapter != nil) {
        switch (thread) {
            case CBRThreadMain:
                return [self.coreDataAdapter.stack.mainThreadManagedObjectContext performBlock:block];
            case CBRThreadBackground:
                return [self.coreDataAdapter.stack.backgroundThreadManagedObjectContext performBlock:block];
        }
    }
#endif

    assert(self.queue != nil);
    switch (thread) {
        case CBRThreadMain:
            return dispatch_async(dispatch_get_main_queue(), block);
        case CBRThreadBackground:
            return dispatch_async(self.queue, block);
    }
}

- (void)_assertCoreData
{
#if CBRCoreDataAvailable
    if (self.coreDataAdapter == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"A CoreData adapter is required"];
    }
#else
    [NSException raise:NSInternalInconsistencyException format:@"A CoreData adapter is required"];
#endif
}

- (void)_assertRealm
{
#if CBRRealmAvailable
    if (self.realmAdapter == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"A Realm adapter is required"];
    }
#else
    [NSException raise:NSInternalInconsistencyException format:@"A Realm adapter is required"];
#endif
}

- (nullable id)_threadSafeReferenceForObject:(nullable id)object
{
    if (object == nil) {
        return nil;
    }

    if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];

        for (id object in array) {
            [newArray addObject:[self _threadSafeReferenceForObject:object]];
        }

        return newArray;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = object;
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

        for (id key in dictionary) {
            newDictionary[key] = [self _threadSafeReferenceForObject:dictionary[key]];
        }

        return newDictionary;
    } else if ([object isKindOfClass:[NSSet class]]) {
        NSSet *set = object;
        NSMutableSet *newSet = [NSMutableSet set];

        for (id object in set) {
            [newSet addObject:[self _threadSafeReferenceForObject:object]];
        }

        return newSet;
    } else if ([object isKindOfClass:[NSManagedObject class]]) {
        [self _assertCoreData];
        assert([object objectID]);
        return [object objectID];
    } else if ([object isKindOfClass:[NSManagedObjectID class]]) {
        return object;
#if CBRRealmAvailable
    } else if ([object isKindOfClass:[CBRRealmObject class]]) {
        [self _assertRealm];

        CBRRealmObject *realmObject = object;
        if (realmObject.realm == nil) {
            assert(!self.realmAdapter.realm.inWriteTransaction);
            [self.realmAdapter.realm beginWriteTransaction];
            [self.realmAdapter.realm addObject:realmObject];
            [self.realmAdapter.realm commitWriteTransaction];
        }

        return [RLMThreadSafeReference referenceWithThreadConfined:object];
    } else if ([object isKindOfClass:[RLMThreadSafeReference class]]) {
        [self _assertRealm];
        return object;
#endif
    }

    [NSException raise:NSInternalInconsistencyException format:@"Cannot move %@ between threads, type unknown", object];
    return nil;
}

- (nullable id)_resolveThreadSafeReference:(nullable id)reference onThread:(CBRThread)thread error:(NSError **)error
{
    if (reference == nil) {
        return nil;
    }

    if ([reference isKindOfClass:[NSArray class]]) {
        NSArray *array = reference;
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];

        for (id object in array) {
            NSError *localError = nil;
            id result = [self _resolveThreadSafeReference:object onThread:thread error:&localError];

            if (localError) {
                *error = localError;
                return nil;
            }

            [newArray addObject:result];
        }

        return newArray;
    } else if ([reference isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = reference;
        NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

        for (id key in dictionary) {
            NSError *localError = nil;
            id result = [self _resolveThreadSafeReference:dictionary[key] onThread:thread error:&localError];

            if (localError) {
                *error = localError;
                return nil;
            }

            newDictionary[key] = result;
        }

        return newDictionary;
    } else if ([reference isKindOfClass:[NSSet class]]) {
        NSSet *set = reference;
        NSMutableSet *newSet = [NSMutableSet setWithCapacity:set.count];

        for (id object in set) {
            NSError *localError = nil;
            id result = [self _resolveThreadSafeReference:object onThread:thread error:&localError];

            if (localError) {
                *error = localError;
                return nil;
            }

            [newSet addObject:result];
        }

        return newSet;
#if CBRCoreDataAvailable
    } else if ([reference isKindOfClass:[NSManagedObjectID class]]) {
        [self _assertCoreData];

        NSManagedObjectContext *context = nil;
        switch (thread) {
            case CBRThreadMain:
                context = self.coreDataAdapter.stack.mainThreadManagedObjectContext;
                break;
            case CBRThreadBackground:
                context = self.coreDataAdapter.stack.backgroundThreadManagedObjectContext;
                break;
        }

        NSError *localError = nil;
        NSManagedObject *managedObject = [context existingObjectWithID:reference error:&localError];

        if (localError) {
            *error = localError;
            return nil;
        }

        return managedObject;
#endif
#if CBRRealmAvailable
    } else if ([reference isKindOfClass:[RLMThreadSafeReference class]]) {
        [self _assertRealm];
        id object = [self.realmAdapter.realm resolveThreadSafeReference:reference];

        if (object == nil) {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Could not resolve Realm reference", @""),
                                       };
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSCoreDataError userInfo:userInfo];
            return nil;
        }

        return object;
#endif
    }

    [NSException raise:NSInternalInconsistencyException format:@"Cannot resolve %@ for any thread", reference];
    return nil;
}

@end
