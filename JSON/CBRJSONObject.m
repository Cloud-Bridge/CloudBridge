//
//  CBRJSONObject.m
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import "CBRJSONObject.h"

#import <objc/runtime.h>
#import <CloudBridge/CloudBridge.h>

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

static BOOL property_isBackedByIVar(objc_property_t property)
{
    char *value = property_copyAttributeValue(property, "V");

    if (value) {
        free(value);
        return YES;
    }

    return NO;
}

static Class property_getClass(objc_property_t property)
{
    char *value = property_copyAttributeValue(property, "T");

    if ([@(property_getName(property)) isEqualToString:@"range"]) {
        NSLog(@"");
    }

    if (!value) {
        return Nil;
    }

    NSString *string = [NSString stringWithCString:value encoding:NSASCIIStringEncoding];
    free(value);

    if ([string characterAtIndex:0] != '@') {
        return Nil;
    }

    if (string.length <= 3) {
        return [NSObject class];
    }

    if ([string characterAtIndex:1] == '"' && [string characterAtIndex:string.length - 1] == '"') {
        NSString *className = [string substringWithRange:NSMakeRange(2, string.length - 3)];
        return NSClassFromString(className);
    }

    return Nil;
}



@implementation CBRJSONObject

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

+ (NSDictionary<NSString *, Class> *)relationMapping
{
    return @{};
}

+ (NSDictionary<NSString *, Class> *)propertyClassMapping
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (NSString *propertyName in [self serializableProperties]) {
        objc_property_t property = class_getProperty(self, propertyName.UTF8String);
        dictionary[propertyName] = property_getClass(property);
    }

    return dictionary;
}

+ (NSArray<NSString *> *)serializableProperties
{
    NSMutableArray *properties = [NSMutableArray array];

    unsigned int count = 0;
    objc_property_t *propertyList = class_copyPropertyList(self, &count);

    for (int i = 0; i < count; i++) {
        objc_property_t property = propertyList[i];

        if (!property_isBackedByIVar(property) || !property_getClass(property)) {
            continue;
        }

        [properties addObject:[NSString stringWithFormat:@"%s", property_getName(property)]];
    }

    free(propertyList);
    return properties;
}


#pragma mark - Initialization

- (instancetype)init
{
    return [super init];
}

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (self = [super init]) {
        if (![self _patchWithDictionary:dictionary error:error]) {
            return nil;
        }
    }
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[self.class allocWithZone:zone] init];

    for (NSString *property in [self.class serializableProperties]) {
        [copy setValue:[self valueForKey:property] forKey:property];
    }

    return copy;
}

#pragma mark - NSObject

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@: ", [super description]];

    [[self.class serializableProperties] enumerateObjectsUsingBlock:^(NSString *property, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [description appendFormat:@"%@ => %@", property, [self valueForKey:property]];
        } else {
            [description appendFormat:@", %@ => %@", property, [self valueForKey:property]];
        }
    }];

    return description;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        NSDictionary *propertyClassMapping = [self.class propertyClassMapping];

        for (NSString *property in propertyClassMapping) {
            Class class = propertyClassMapping[property];

            [self setValue:[aDecoder decodeObjectOfClass:class forKey:property] forKey:property];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSArray<NSString *> *serializableProperties = [self.class serializableProperties];

    for (NSString *property in serializableProperties) {
        [aCoder encodeObject:[self valueForKey:property] forKey:property];
    }
}

- (NSDictionary<NSString *, id> *)jsonRepresentation
{
    NSArray<NSString *> *serializableProperties = [self.class serializableProperties];
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];

    CBRRESTConnection *connection = [self.class restConnection];
    NSDateFormatter *dateFormatter = connection.objectTransformer.dateFormatter;

    for (NSString *property in serializableProperties) {
        id value = [self valueForKey:property];
        NSString *jsonProperty = [connection.propertyMapping cloudKeyPathFromPersistentObjectProperty:property];

        if ([[value class] isSubclassOfClass:[CBRJSONObject class]]) {
            CBRJSONObject *nextModel = value;
            result[jsonProperty] = nextModel.jsonRepresentation ?: [NSNull null];
        } else if ([[value class] isSubclassOfClass:[NSArray class]]) {

        } else if ([[value class] isSubclassOfClass:[NSDate class]]) {
            if (![value isKindOfClass:[NSString class]]) {
                continue;
            }

            result[jsonProperty] = [dateFormatter stringFromDate:value] ?: [NSNull null];
        } else {
            result[jsonProperty] = value ?: [NSNull null];
        }
    }

    return result;
}

#pragma mark - Private category implementation ()

- (BOOL)patchWithDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    return [self _patchWithDictionary:dictionary error:error];
}

- (BOOL)_patchWithDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    CBRRESTConnection *connection = [self.class restConnection];
    NSDateFormatter *dateFormatter = connection.objectTransformer.dateFormatter;

    NSDictionary *propertyClassMapping = [self.class propertyClassMapping];

    for (NSString *property in propertyClassMapping) {
        NSString *jsonProperty = [connection.propertyMapping cloudKeyPathFromPersistentObjectProperty:property];

        Class expectedClass = propertyClassMapping[property];
        id value = dictionary[jsonProperty];

        if ([expectedClass isSubclassOfClass:[CBRJSONObject class]]) {
            if (![value isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            id nextValue = [[expectedClass alloc] initWithDictionary:value error:error];
            [self setValue:nextValue forKey:property];
        } else if ([expectedClass isSubclassOfClass:[NSArray class]]) {
            if (![value isKindOfClass:[NSArray class]]) {
                continue;
            }

            NSMutableArray *result = [NSMutableArray array];
            for (id nextValue in value) {
                if ([self.class relationMapping][property] == nil) {
                    [result addObject:nextValue];
                } else {
                    Class nextClass = [self.class relationMapping][property];
                    id nextResult = [[nextClass alloc] initWithDictionary:nextValue error:error];

                    if (nextResult) {
                        [result addObject:nextResult];
                    }
                }
            }
            [self setValue:result forKey:property];
        } else if ([expectedClass isSubclassOfClass:[NSDate class]]) {
            if (![value isKindOfClass:[NSString class]]) {
                continue;
            }

            [self setValue:[dateFormatter dateFromString:value] forKey:property];
        } else {
            if (![value isKindOfClass:expectedClass]) {
                continue;
            }

            [self setValue:value forKey:property];
        }
    }

    return YES;
}

@end



@implementation CBRJSONObject (CBRPersistentObjectQueryInterface)

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



@implementation CBRJSONObjectValueTransformer

+ (Class)destinationClass
{
    [self doesNotRecognizeSelector:_cmd];
    return Nil;
}

- (id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];

        for (id jsonvalue in value) {
            NSError *error = nil;
            CBRJSONObject *object = [[[self.class destinationClass] alloc] initWithDictionary:jsonvalue error:&error];

            if (object != nil) {
                [result addObject:object];
            }
        }

        return result;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSError *error = nil;
        return [[[self.class destinationClass] alloc] initWithDictionary:value error:&error];
    } else {
        return nil;
    }
}

- (id)reverseTransformedValue:(id)value
{
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];

        for (CBRJSONObject *jsonModel in value) {
            [result addObject:jsonModel.jsonRepresentation ?: @{}];
        }

        return result;
    } else if ([value isKindOfClass:[CBRJSONObject class]]) {
        CBRJSONObject *jsonModel = value;
        return jsonModel.jsonRepresentation ?: @{};
    } else {
        return [NSNull null];
    }
}

@end
