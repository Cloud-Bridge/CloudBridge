![Header](https://github.com/OliverLetterer/CloudBridge/blob/master/header.png?raw=true)

[![CI Status](http://img.shields.io/travis/Cloud-Bridge/CloudBridge.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CloudBridge)
[![Version](https://img.shields.io/cocoapods/v/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)
[![License](https://img.shields.io/cocoapods/l/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)
[![Platform](https://img.shields.io/cocoapods/p/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)

CloudBridge helps synchronizing Your CoreData managed objects with various Cloud backends and ships with native support for RESTful JSON backends and CloudKit.

## Public API

CloudBridge exposes the following convenience methods on `NSManagedObject`:

```
+ (void)fetchObjectsMatchingPredicate:(NSPredicate *)predicate
                withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler;

- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;

- (void)createWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)reloadWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)saveWithCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler;
- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler;
```

which can be called from any `NSManagedObjectContext` thread and are routed through the managed objects `CBRCloudBridge`. The callbacks are always guaranteed to be delivered on the main thread.

## Quick start

To start using the convenience methods on `NSManagedObject`, You need to configure a `CBRCloudBridge` instance. A `CBRCloudBridge` instance is responsible for bridging between a [CoreDataStack](https://github.com/OliverLetterer/CBRCoreDataStack) and your backend.

### 1. Implement Your CoreDataStack

Because setting up a correct and responsible CoreData stack can be challaging, `CloudBridge` relies on [CBRCoreDataStack](https://github.com/OliverLetterer/CBRCoreDataStack), which takes care of all the heavy lifting and edge cases for you. Implement your application specific CoreData stack as a subclass of `CBRCoreDataStack`:

```
@interface MyCoreDataStack : CBRCoreDataStack
@end

@implementation MyCoreDataStack

- (NSString *)managedObjectModelName
{
    return @"MyManagedObjectModel";
}

@end
```

### 2. Choose Your Cloud backend

The actual communication with each Cloud backend is encapsulated in an object conforming to the `CBRCloudConnection` protocol
and is shipped in it's own CocoaPod dependency.

If you want to connect to a CloudKit backend, add `pod 'CBRCloudKitConnection'` to Your Podfile.
If you want to connect to a RESTful JSON backend, add `pod 'CBRRESTConnection'` to Your Podfile.

More information can be found in the [CBRRESTConnection](https://github.com/Cloud-Bridge/CBRRESTConnection) or [CBRCloudKitConnection](https://github.com/Cloud-Bridge/CBRCloudKitConnection) documentation.

### 3. Setup Your CloudBridge

As a last step, setup your CloudBridge stack as follows:

#### CloudKit backend
```
CKDatabase *database = [CKContainer defaultContainer].privateCloudDatabase;
MyCoreDataStack *stack = [MyCoreDataStack sharedInstance];
CBRCloudKitConnection *connection = [[CBRCloudKitConnection alloc] initWithDatabase:database];

CBRCloudBridge *cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:connection coreDataStack:stack];
[NSManagedObject setCloudBridge:cloudBridge];

```

#### RESTful backend

```
NSURL *serverURL = ...;
MyCoreDataStack *stack = [MyCoreDataStack sharedInstance];

id<CBRPropertyMapping> propertyMapping = [[CBRUnderscoredPropertyMapping alloc] init];
CBRRESTConnection *connection = [[CBRRESTConnection alloc] initWithBaseURL:serverURL propertyMapping:propertyMapping];

CBRCloudBridge *cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:connection coreDataStack:stack];
[NSManagedObject setCloudBridge:cloudBridge];
```

### 4. Enjoy

## Installation

CloudBridge is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "CloudBridge"

## Components status

| Component | State | Version | License | Platform |
|-----------|-------|---------|---------|----------|
| [CloudBridge](https://github.com/Cloud-Bridge/CloudBridge) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CloudBridge.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CloudBridge) | [![Version](https://img.shields.io/cocoapods/v/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge) | [![License](https://img.shields.io/cocoapods/l/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge) | [![Platform](https://img.shields.io/cocoapods/p/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge) |
| [CBRRESTConnection](https://github.com/Cloud-Bridge/CBRRESTConnection) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CBRRESTConnection.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CBRRESTConnection) | [![Version](https://img.shields.io/cocoapods/v/CBRRESTConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRRESTConnection) | [![License](https://img.shields.io/cocoapods/l/CBRRESTConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRRESTConnection) | [![Platform](https://img.shields.io/cocoapods/p/CBRRESTConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRRESTConnection) |
| [CBRCloudKitConnection](https://github.com/Cloud-Bridge/CBRCloudKitConnection) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CBRCloudKitConnection.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CBRCloudKitConnection) | [![Version](https://img.shields.io/cocoapods/v/CBRCloudKitConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRCloudKitConnection) | [![License](https://img.shields.io/cocoapods/l/CBRCloudKitConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRCloudKitConnection) | [![Platform](https://img.shields.io/cocoapods/p/CBRCloudKitConnection.svg?style=flat)](http://cocoadocs.org/docsets/CBRCloudKitConnection) |
| [CBRManagedObjectCache](https://github.com/Cloud-Bridge/CBRManagedObjectCache) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CBRManagedObjectCache.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CBRManagedObjectCache) | [![Version](https://img.shields.io/cocoapods/v/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache) | [![License](https://img.shields.io/cocoapods/l/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache) | [![Platform](https://img.shields.io/cocoapods/p/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache) |
| [CBRManagedObjectFormViewController](https://github.com/Cloud-Bridge/CBRManagedObjectFormViewController) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CBRManagedObjectFormViewController.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CBRManagedObjectFormViewController) | [![Version](https://img.shields.io/cocoapods/v/CBRManagedObjectFormViewController.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectFormViewController) | [![License](https://img.shields.io/cocoapods/l/CBRManagedObjectFormViewController.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectFormViewController) | [![Platform](https://img.shields.io/cocoapods/p/CBRManagedObjectFormViewController.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectFormViewController) |
| [CBRRelationshipResolver](https://github.com/Cloud-Bridge/CBRRelationshipResolver) | [![CI Status](http://img.shields.io/travis/Cloud-Bridge/CBRRelationshipResolver.svg?style=flat)](https://travis-ci.org/Cloud-Bridge/CBRRelationshipResolver) | [![Version](https://img.shields.io/cocoapods/v/CBRRelationshipResolver.svg?style=flat)](http://cocoadocs.org/docsets/CBRRelationshipResolver) | [![License](https://img.shields.io/cocoapods/l/CBRRelationshipResolver.svg?style=flat)](http://cocoadocs.org/docsets/CBRRelationshipResolver) | [![Platform](https://img.shields.io/cocoapods/p/CBRRelationshipResolver.svg?style=flat)](http://cocoadocs.org/docsets/CBRRelationshipResolver) |

## Author

Oliver Letterer, oliver.letterer@gmail.com

## License

CloudBridge is available under the MIT license. See the LICENSE file for more info.
