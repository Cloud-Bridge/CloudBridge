//
//  The MIT License (MIT)
//  Copyright (c) 2013-2015 Oliver Letterer, Sparrow-Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CBRCoreDataStack.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <libkern/OSAtomic.h>

NSString *const CBRCoreDataStackErrorDomain = @"CBRCoreDataStackErrorDomain";

@interface CBRCoreDataStack ()

@property (nonatomic, readonly) NSLock *migrationLock;

@end


@implementation CBRCoreDataStack
@synthesize mainThreadManagedObjectContext = _mainThreadManagedObjectContext, backgroundThreadManagedObjectContext = _backgroundThreadManagedObjectContext, managedObjectModel = _managedObjectModel, persistentStoreCoordinator = _persistentStoreCoordinator, persistentManagedObjectContext = _persistentManagedObjectContext;

#pragma mark - setters and getters

#pragma mark - Initialization

+ (instancetype)newConvenientSQLiteStackWithModel:(NSString *)model inBundle:(NSBundle *)bundle
{
    return [self buildConvenientSQLiteStackWithModel:model inBundle:bundle];
}

+ (instancetype)buildConvenientSQLiteStackWithModel:(NSString *)model inBundle:(NSBundle *)bundle
{
    NSURL *momURL = [bundle URLForResource:model withExtension:@"mom"];
    NSURL *momdURL = [bundle URLForResource:model withExtension:@"momd"];

    if (momURL && momdURL) {
        NSDate *momCreationDate = [[NSFileManager defaultManager] attributesOfItemAtPath:momURL.path error:NULL].fileCreationDate;
        NSDate *momdCreationDate = [[NSFileManager defaultManager] attributesOfItemAtPath:momdURL.path error:NULL].fileCreationDate;

        if (momCreationDate.timeIntervalSince1970 > momdCreationDate.timeIntervalSince1970) {
            NSLog(@"Found mom and momd model, will be using mom because fileCreationDate is newer");
            momdURL = nil;
        } else {
            NSLog(@"Found mom and momd model, will be using momd because fileCreationDate is newer");
            momURL = nil;
        }
    }

    NSAssert(momURL != nil || momdURL != nil, @"Neither %@.mom nor %@.momd could be found in bundle %@", model, model, bundle);
    NSURL *libraryDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                                     inDomains:NSUserDomainMask].lastObject;

    NSURL *location = [libraryDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", model]];
    return [[self alloc] initWithType:NSSQLiteStoreType location:location model:momURL ?: momdURL inBundle:bundle type:CBRCoreDataStackTypeParallel];
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithType:(NSString *)storeType location:(NSURL *)storeLocation model:(NSURL *)modelURL inBundle:(NSBundle *)bundle type:(CBRCoreDataStackType)type
{
    if (self = [super init]) {
        _storeLocation = storeLocation;
        _storeType = storeType;
        _managedObjectModelURL = modelURL;
        _bundle = bundle;
        _type = type;
        _migrationLock = [[NSLock alloc] init];

        NSString *parentDirectory = storeLocation.URLByDeletingLastPathComponent.path;
        if (![[NSFileManager defaultManager] fileExistsAtPath:parentDirectory isDirectory:NULL]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:parentDirectory
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];

            NSAssert(error == nil, @"error while creating parentDirectory '%@':\n\nerror: \"%@\"", parentDirectory, error);
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - CoreData

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.managedObjectModelURL];
        NSParameterAssert(_managedObjectModel);
    }

    return _managedObjectModel;
}

- (NSManagedObjectContext *)persistentManagedObjectContext
{
    if (self.type == CBRCoreDataStackTypeParallel) {
        return nil;
    }

    if (!_persistentManagedObjectContext) {
        _persistentManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _persistentManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        _persistentManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        _persistentManagedObjectContext.name = @"persistent context";

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_managedObjectContextDidSaveNotificationCallback:) name:NSManagedObjectContextDidSaveNotification object:_persistentManagedObjectContext];
    }

    return _persistentManagedObjectContext;
}

- (NSManagedObjectContext *)mainThreadManagedObjectContext
{
    if (!_mainThreadManagedObjectContext) {
        _mainThreadManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainThreadManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        _mainThreadManagedObjectContext.name = @"main context";

        if (self.type == CBRCoreDataStackTypeParallel) {
            _mainThreadManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        } else {
            _mainThreadManagedObjectContext.parentContext = self.persistentManagedObjectContext;

            if (@available(iOS 10.0, *)) {
                _mainThreadManagedObjectContext.automaticallyMergesChangesFromParent = YES;
            }
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_managedObjectContextDidSaveNotificationCallback:) name:NSManagedObjectContextDidSaveNotification object:_mainThreadManagedObjectContext];
    }

    return _mainThreadManagedObjectContext;
}

- (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    if (!_backgroundThreadManagedObjectContext) {
        _backgroundThreadManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backgroundThreadManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        _backgroundThreadManagedObjectContext.name = @"background context";

        if (self.type == CBRCoreDataStackTypeParallel) {
            _backgroundThreadManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        } else {
            _backgroundThreadManagedObjectContext.parentContext = self.mainThreadManagedObjectContext;

            if (@available(iOS 10.0, *)) {
                _backgroundThreadManagedObjectContext.automaticallyMergesChangesFromParent = YES;
            }
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_managedObjectContextDidSaveNotificationCallback:) name:NSManagedObjectContextDidSaveNotification object:_backgroundThreadManagedObjectContext];
    }

    return _backgroundThreadManagedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = self.storeLocation;
        NSManagedObjectModel *managedObjectModel = self.managedObjectModel;

        if (self.requiresMigration) {
            NSError *error = nil;
            if (![self migrateDataStore:&error]) {
                NSLog(@"[CBRCoreDataStack] migrating data store failed: %@", error);
            }
        }

        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES
                                  };

        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];

        if (![_persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:storeURL options:options error:&error]) {
            NSLog(@"[CBRCoreDataStack] could not add persistent store: %@", error);
            NSLog(@"[CBRCoreDataStack] deleting old data store");

            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
            error = nil;

            if (![_persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:storeURL options:options error:&error]) {
                NSLog(@"[CBRCoreDataStack] could not add persistent store: %@", error);
                abort();
            }
        }
    }

#ifdef DEBUG
    [self _enableCoreDataThreadDebugging];
#endif

    return _persistentStoreCoordinator;
}

#pragma mark - private implementation ()

- (void)_managedObjectContextDidSaveNotificationCallback:(NSNotification *)notification
{
    NSManagedObjectContext *changedContext = notification.object;

    switch (self.type) {
        case CBRCoreDataStackTypeParallel:
            if (changedContext == self.backgroundThreadManagedObjectContext) {
                [self.mainThreadManagedObjectContext performBlockAndWait:^{
                    [self.mainThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                }];
            } else if (changedContext == self.mainThreadManagedObjectContext) {
                [self.backgroundThreadManagedObjectContext performBlock:^{
                    [self.backgroundThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                }];
            }
            break;

        case CBRCoreDataStackTypeVertical:
            if (changedContext == self.mainThreadManagedObjectContext) {
                [self.persistentManagedObjectContext performBlock:^{
                    [self.persistentManagedObjectContext save:NULL];
                }];

                if (@available(iOS 10.0, *)) {} else {
                    [self.backgroundThreadManagedObjectContext performBlock:^{
                        [self.backgroundThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    }];
                }
            } else if (changedContext == self.backgroundThreadManagedObjectContext) {
                [self.mainThreadManagedObjectContext performBlock:^{
                    [self.mainThreadManagedObjectContext save:NULL];
                }];
            } else if (changedContext == self.persistentManagedObjectContext) {
                if (@available(iOS 10.0, *)) {} else {
                    [self.mainThreadManagedObjectContext performBlock:^{
                        [self.mainThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    }];

                    [self.backgroundThreadManagedObjectContext performBlock:^{
                        [self.backgroundThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
                    }];
                }
            }
            break;
    }
}

- (void)_enableCoreDataThreadDebugging
{
    @synchronized(self) {
        NSManagedObjectModel *model = _persistentStoreCoordinator.managedObjectModel;

        for (NSEntityDescription *entity in model.entities) {
            Class class = NSClassFromString(entity.managedObjectClassName);

            if (!class || objc_getAssociatedObject(class, _cmd)) {
                continue;
            }

            IMP implementation = imp_implementationWithBlock(^(id _self, NSString *key) {
                struct objc_super super = {
                    .receiver = _self,
                    .super_class = [class superclass]
                };
                ((void(*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&super, @selector(willAccessValueForKey:), key);
            });
            class_addMethod(class, @selector(willAccessValueForKey:), implementation, "v@:@");

            implementation = imp_implementationWithBlock(^(id _self, NSString *key) {
                struct objc_super super = {
                    .receiver = _self,
                    .super_class = [class superclass]
                };
                ((void(*)(struct objc_super *, SEL, id))objc_msgSendSuper)(&super, @selector(willChangeValueForKey:), key);
            });
            class_addMethod(class, @selector(willChangeValueForKey:), implementation, "v@:@");

            objc_setAssociatedObject(class, _cmd, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

@end



@implementation CBRCoreDataStack (Migration)

- (BOOL)requiresMigration
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES
                              };

    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:self.storeType URL:self.storeLocation options:options error:NULL];
#else
    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:self.storeType URL:self.storeLocation error:NULL];
#endif

    if (!sourceStoreMetadata) {
        return NO;
    }

    return ![self.managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceStoreMetadata];
}

- (BOOL)migrateDataStore:(NSError **)error
{
    [self.migrationLock lock];

    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES
                              };

    NSError *addStoreError = nil;
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

    if ([persistentStoreCoordinator addPersistentStoreWithType:self.storeType configuration:nil URL:self.storeLocation options:options error:&addStoreError]) {
        NSLog(@"[CBRCoreDataStack] automatic persistent store migration completed %@", options);
        [self.migrationLock unlock];
        return YES;
    } else {
        NSLog(@"[CBRCoreDataStack] could not automatic migrate persistent store with %@", options);
        NSLog(@"[CBRCoreDataStack] addStoreError = %@", addStoreError);
    }

    BOOL success = [self _performMigrationFromDataStoreAtURL:self.storeLocation toDestinationModel:self.managedObjectModel error:error];
    [self.migrationLock unlock];

    return success;
}

- (BOOL)_performMigrationFromDataStoreAtURL:(NSURL *)dataStoreURL
                         toDestinationModel:(NSManagedObjectModel *)destinationModel
                                      error:(NSError * __autoreleasing *)error
{
    BOOL(^updateError)(NSInteger errorCode, NSString *description) = ^BOOL(NSInteger errorCode, NSString *description) {
        if (!error) {
            return NO;
        }

        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };
        *error = [NSError errorWithDomain:CBRCoreDataStackErrorDomain code:errorCode userInfo:userInfo];

        return NO;
    };

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000
    NSDictionary *options = @{
                              NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption: @YES
                              };

    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:self.storeType URL:dataStoreURL options:options error:error];
#else
    NSDictionary *sourceStoreMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:self.storeType URL:dataStoreURL error:error];
#endif

    if (!sourceStoreMetadata) {
        return NO;
    }

    if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceStoreMetadata]) {
        return YES;
    }

    NSArray *bundles = @[ self.bundle ];
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundles
                                                                    forStoreMetadata:sourceStoreMetadata];

    if (!sourceModel) {
        return updateError(CBRCoreDataStackManagedObjectModelNotFound, [NSString stringWithFormat:@"Unable to find NSManagedObjectModel for store metadata %@", sourceStoreMetadata]);
    }

    NSMutableArray *objectModelPaths = [NSMutableArray array];
    NSArray *allManagedObjectModels = [self.bundle pathsForResourcesOfType:@"momd"
                                                               inDirectory:nil];

    for (NSString *managedObjectModelPath in allManagedObjectModels) {
        NSArray *array = [self.bundle pathsForResourcesOfType:@"mom"
                                                  inDirectory:managedObjectModelPath.lastPathComponent];

        [objectModelPaths addObjectsFromArray:array];
    }

    NSArray *otherModels = [self.bundle pathsForResourcesOfType:@"mom" inDirectory:nil];
    [objectModelPaths addObjectsFromArray:otherModels];

    if (objectModelPaths.count == 0) {
        return updateError(CBRCoreDataStackManagedObjectModelNotFound, [NSString stringWithFormat:@"No NSManagedObjectModel found in bundle %@", self.bundle]);
    }

    NSMappingModel *mappingModel = nil;
    NSManagedObjectModel *targetModel = nil;
    NSString *modelPath = nil;

    for (modelPath in objectModelPaths.reverseObjectEnumerator) {
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
        targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        mappingModel = [NSMappingModel mappingModelFromBundles:bundles
                                                forSourceModel:sourceModel
                                              destinationModel:targetModel];

        if (mappingModel) {
            break;
        }
    }

    if (!mappingModel) {
        return updateError(CBRCoreDataStackMappingModelNotFound, [NSString stringWithFormat:@"Unable to find NSMappingModel for store at URL %@", dataStoreURL]);
    }

    NSMigrationManager *migrationManager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                                                          destinationModel:targetModel];

    NSString *modelName = modelPath.lastPathComponent.stringByDeletingPathExtension;
    NSString *storeExtension = dataStoreURL.path.pathExtension;

    NSString *storePath = dataStoreURL.path.stringByDeletingPathExtension;

    NSString *destinationPath = [NSString stringWithFormat:@"%@.%@.%@", storePath, modelName, storeExtension];
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];

    if (![migrationManager migrateStoreFromURL:dataStoreURL type:self.storeType options:nil withMappingModel:mappingModel toDestinationURL:destinationURL destinationType:self.storeType destinationOptions:nil error:error]) {
        return NO;
    }

    if (![[NSFileManager defaultManager] removeItemAtURL:dataStoreURL error:error]) {
        return NO;
    }

    if (![[NSFileManager defaultManager] moveItemAtURL:destinationURL toURL:dataStoreURL error:error]) {
        return NO;
    }

    return [self _performMigrationFromDataStoreAtURL:dataStoreURL
                                  toDestinationModel:destinationModel
                                               error:error];
}

@end



#ifdef DEBUG

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

@implementation NSManagedObject (CBRCoreDataStackCoreDataThreadDebugging)

+ (void)load
{
    class_swizzleSelector(self, @selector(willChangeValueForKey:), @selector(__CBRCoreDataStackCoreDataThreadDebuggingWillChangeValueForKey:));
    class_swizzleSelector(self, @selector(willAccessValueForKey:), @selector(__CBRCoreDataStackCoreDataThreadDebuggingWillAccessValueForKey:));
}

- (void)__CBRCoreDataStackCoreDataThreadDebuggingWillAccessValueForKey:(NSString *)key
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSManagedObjectContext *context = self.managedObjectContext;

    if (context && context.concurrencyType != NSConfinementConcurrencyType) {
        __block dispatch_queue_t queue = NULL;
        [context performBlockAndWait:^{
            queue = dispatch_get_current_queue();
        }];

        NSAssert(queue == dispatch_get_current_queue(), @"wrong queue buddy");
    }

#pragma clang diagnostic pop

    [self __CBRCoreDataStackCoreDataThreadDebuggingWillAccessValueForKey:key];
}

- (void)__CBRCoreDataStackCoreDataThreadDebuggingWillChangeValueForKey:(NSString *)key
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSManagedObjectContext *context = self.managedObjectContext;

    if (context) {
        __block dispatch_queue_t queue = NULL;
        [context performBlockAndWait:^{
            queue = dispatch_get_current_queue();
        }];

        NSAssert(queue == dispatch_get_current_queue(), @"wrong queue buddy");
    }

#pragma clang diagnostic pop

    [self __CBRCoreDataStackCoreDataThreadDebuggingWillChangeValueForKey:key];
}

@end
#endif

