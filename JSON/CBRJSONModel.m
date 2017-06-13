//
//  CBRJSONModel.m
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import "CBRJSONModel.h"

#import <objc/runtime.h>
#import <CloudBridge/CloudBridge.h>
#import <AFNetworking/AFHTTPSessionManager.h>



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



static AFHTTPSessionManager *_sessionManager = nil;
@implementation CBRJSONModel


+ (void)setSessionManager:(AFHTTPSessionManager *)sessionManager
{
    _sessionManager = sessionManager;
}

+ (AFHTTPSessionManager *)sessionManager
{
    return _sessionManager;
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

+ (void)fetchObjectsFromPath:(NSString *)path completion:(void(^)(NSArray * _Nullable objects, NSError * _Nullable error))completion
{
    assert([self sessionManager]);
    [[self sessionManager] GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = @[ responseObject ];
        }

        NSError *error = nil;
        NSMutableArray *results = [NSMutableArray array];
        for (NSDictionary *json in responseObject) {
            CBRJSONModel *model = [[self alloc] initWithDictionary:json error:&error];

            if (error == nil) {
                [results addObject:model];
            } else {
                completion(nil, error);
                return;
            }
        }

        completion(results, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

- (void)createToPath:(NSString *)path completion:(void(^ _Nullable)(id _Nullable object, NSError * _Nullable error))completion
{
    assert([self.class sessionManager]);
    [[self.class sessionManager] POST:path parameters:self.jsonRepresentation progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        [self patchWithDictionary:responseObject error:&error];

        if (completion) {
            completion(self, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(nil, error);
        }
    }];
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

    CBRRESTConnection *connection = [CBRRealmObject cloudBridge].cloudConnection;
    NSDateFormatter *dateFormatter = connection.objectTransformer.dateFormatter;

    for (NSString *property in serializableProperties) {
        id value = [self valueForKey:property];
        NSString *jsonProperty = [connection.propertyMapping cloudKeyPathFromPersistentObjectProperty:property];

        if ([[value class] isSubclassOfClass:[CBRJSONModel class]]) {
            CBRJSONModel *nextModel = value;
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

    CBRRESTConnection *connection = [CBRRealmObject cloudBridge].cloudConnection;
    NSDateFormatter *dateFormatter = connection.objectTransformer.dateFormatter;

    NSDictionary *propertyClassMapping = [self.class propertyClassMapping];

    for (NSString *property in propertyClassMapping) {
        NSString *jsonProperty = [connection.propertyMapping cloudKeyPathFromPersistentObjectProperty:property];

        Class expectedClass = propertyClassMapping[property];
        id value = dictionary[jsonProperty];

        if ([expectedClass isSubclassOfClass:[CBRJSONModel class]]) {
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



@implementation CBRJSONModelValueTransformer

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
            CBRJSONModel *object = [[[self.class destinationClass] alloc] initWithDictionary:jsonvalue error:&error];

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

        for (CBRJSONModel *jsonModel in value) {
            [result addObject:jsonModel.jsonRepresentation ?: @{}];
        }

        return result;
    } else if ([value isKindOfClass:[CBRJSONModel class]]) {
        CBRJSONModel *jsonModel = value;
        return jsonModel.jsonRepresentation ?: @{};
    } else {
        return [NSNull null];
    }
}

@end
