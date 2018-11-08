![Header](https://github.com/layered-pieces/CloudBridge/blob/master/header.png?raw=true)

[![CI Status](http://img.shields.io/travis/layered-pieces/CloudBridge.svg?style=flat)](https://travis-ci.org/layered-pieces/CloudBridge)
[![Version](https://img.shields.io/cocoapods/v/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)
[![License](https://img.shields.io/cocoapods/l/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)
[![Platform](https://img.shields.io/cocoapods/p/CloudBridge.svg?style=flat)](http://cocoadocs.org/docsets/CloudBridge)

Synchronize your object graphed data model with it's cloud backend. CloudBridge supports CoreData, Realm and plain JSON models in combination with RESTful backends. It builds on top of [AFNetworking](https://github.com/AFNetworking/AFNetworking).

## Installation

CloudBridge is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

    pod "CloudBridge"

## Getting started

### Initialising the stack

```objc
// 1. Initializing a core data stack

NSURL *momURL = [NSBundle.mainBundle URLForResource:@"MyModel" withExtension:@"mom"];

NSURL *libraryDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].lastObject;
NSURL *location = [libraryDirectory URLByAppendingPathComponent:@"store.sqlite"];

CBRCoreDataStack *coreDataStack = [[CBRCoreDataStack alloc] initWithType:NSSQLiteStoreType location:location model:momURL inBundle:NSBundle.mainBundle type:CBRCoreDataStackTypeParallel];

// 2. Defining the data interface

CBRCoreDataInterface *coreDataInterface = [[CBRCoreDataInterface alloc] initWithStack:[CBRCoreDataStack iCuisineStack]];

// 3. Defining a property mapping

CBRUnderscoredPropertyMapping *propertyMapping = [[CBRUnderscoredPropertyMapping alloc] init];
[propertyMapping registerObjcNamingConvention:@"uuid" forJSONNamingConvention:@"UUID"];
[propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
[propertyMapping registerObjcNamingConvention:@"identifiers" forJSONNamingConvention:@"ids"];

// 4. Defining the network connection

AFHTTPSessionManager *sessionManager = ...
CBRRESTConnection *connection = [[CBRRESTConnection alloc] initWithPropertyMapping:propertyMapping sessionManager:sessionManager];

connection.objectTransformer.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
connection.objectTransformer.dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

// 5. Creating the cloud bridge

CBRThreadingEnvironment *threadingEnvironment = [[CBRThreadingEnvironment alloc] initWithCoreDataAdapter:coreDataInterface];
CBRCloudBridge *cloudBridge = [[CBRCloudBridge alloc] initWithCloudConnection:connection interface:coreDataInterface threadingEnvironment:threadingEnvironment];

// 6. Initialising the data model

NSManagedObject.cloudBridge = cloudBridge;
```

## Transmitting data

CloudBridge exposes a set of convinient methods on the data model to interact with the cloud backend

```objc
+ (void)fetchObjectFromPath:(NSString *)path withCompletionHandler:(void (^)(id fetchedObject, NSError *error))completionHandler; // GET path
+ (void)fetchObjectsFromPath:(NSString *)path withCompletionHandler:(void (^)(NSArray *fetchedObjects, NSError *error))completionHandler; // GET path

- (void)createToPath:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler; // POST path
- (void)reloadFromPath:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler; // GET path
- (void)saveToPath:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler; // PUT path
- (void)deleteToPath:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler; // DELETE path
```

and supports objects graphs

```objc
- (void)fetchObjectForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(idobject, NSError *error))completionHandler;
- (void)fetchObjectsForRelationship:(NSString *)relationship withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler;
```

If the path mapping is stored in the models user info dictionary, more convinient methods are available

```objc
- (void)createWithCompletionHandler:(void(^_Nullable)(id fetchedObject, NSError *error))completionHandler;
- (void)reloadWithCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler;
- (void)saveWithCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler;
- (void)deleteWithCompletionHandler:(void(^)(NSError *error))completionHandler;
```
