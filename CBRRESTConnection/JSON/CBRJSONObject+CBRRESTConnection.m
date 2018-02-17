//
//  CBRJSONObject+REST.m
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import "CBRJSONObject+CBRRESTConnection.h"
#import "CBRRESTConnection.h"
#import <objc/runtime.h>

static NSString *substitutePath(CBRJSONObject *object, NSString *path, CBRRESTConnection *connection)
{
    NSCParameterAssert(connection);

    NSMutableArray *newComponents = [NSMutableArray array];
    NSArray *components = [path componentsSeparatedByString:@"/"];

    for (NSString *path in components) {
        if (![path hasPrefix:@":"]) {
            [newComponents addObject:path];
            continue;
        }

        NSString *keyPath = [path substringFromIndex:1];
        NSMutableArray *newKeyPathComponents = [NSMutableArray array];
        NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

        id currentObject = object;
        for (NSString *thisComponent in keyPathComponents) {
            NSString *managedObjectKeyPath = [connection.propertyMapping persistentObjectPropertyFromCloudKeyPath:thisComponent];

            currentObject = [currentObject valueForKey:managedObjectKeyPath];
            [newKeyPathComponents addObject:managedObjectKeyPath];
        }

        NSString *managedObjectKeyPath = [newKeyPathComponents componentsJoinedByString:@"."];
        id value = [object valueForKeyPath:managedObjectKeyPath];
        NSString *restValue = [NSString stringWithFormat:@"%@", value];

        [newComponents addObject:[restValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }

    return [newComponents componentsJoinedByString:@"/"];
}



@implementation CBRJSONObject (CBRPersistentObjectQueryInterface)

+ (CBRRESTConnection *)restConnection
{
    Class klass = self;
    while (klass != Nil) {
        if (objc_getAssociatedObject(klass, @selector(restConnection))) {
            return objc_getAssociatedObject(klass, @selector(restConnection));
        }

        klass = class_getSuperclass(klass);
    }

    return nil;
}

+ (void)setRestConnection:(CBRRESTConnection *)restConnection
{
    objc_setAssociatedObject(self, @selector(restConnection), restConnection, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBRRESTConnection *)restConnection
{
    return [self.class restConnection];
}

+ (void)fetchObject:(NSString *)path withCompletionHandler:(void(^)(id fetchedObject, NSError *error))completionHandler
{
    [self fetchObjects:path withCompletionHandler:^(NSArray * _Nonnull fetchedObjects, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(fetchedObjects.firstObject, error);
        }
    }];
}

+ (void)fetchObjects:(NSString *)path withCompletionHandler:(void(^)(NSArray *fetchedObjects, NSError *error))completionHandler
{
    [self.restConnection.sessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        NSMutableArray *results = [NSMutableArray array];

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id object = [[self alloc] initWithDictionary:responseObject error:&error];

            if (object != nil) {
                [results addObject:object];
            }
        } else if ([responseObject isKindOfClass:[NSArray class]]) {
            for (id jsonObject in responseObject) {
                id object = [[self alloc] initWithDictionary:jsonObject error:&error];

                if (object != nil) {
                    [results addObject:object];
                }
            }
        }

        if (completionHandler) {
            completionHandler(results, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    }];
}

- (void)fetchRelation:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(id object, NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [relation fetchObject:path withCompletionHandler:completionHandler];
}

- (void)fetchRelations:(Class)relation path:(NSString *)path withCompletionHandler:(void(^)(NSArray *objects, NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [relation fetchObjects:path withCompletionHandler:completionHandler];
}

- (void)create:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [self.restConnection.sessionManager POST:path parameters:self.jsonRepresentation progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self patchWithDictionary:responseObject error:NULL];

        if (completionHandler) {
            completionHandler(self, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(self, error);
        }
    }];
}

- (void)reload:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [self.restConnection.sessionManager GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self patchWithDictionary:responseObject error:NULL];

        if (completionHandler) {
            completionHandler(self, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(self, error);
        }
    }];
}

- (void)save:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [self.restConnection.sessionManager PUT:path parameters:self.jsonRepresentation success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self patchWithDictionary:responseObject error:NULL];

        if (completionHandler) {
            completionHandler(self, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(self, error);
        }
    }];
}

- (void)delete:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    path = substitutePath(self, path, [self.class restConnection]);
    [self.restConnection.sessionManager DELETE:path parameters:self.jsonRepresentation success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completionHandler) {
            completionHandler(nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

@end
