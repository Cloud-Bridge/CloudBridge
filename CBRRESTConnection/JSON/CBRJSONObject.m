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

static id encodeJsonValue(id value, CBRRESTConnection *connection)
{
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value isKindOfClass:[NSDate class]]) {
        NSDateFormatter *dateFormatter = connection.objectTransformer.dateFormatter;
        return [dateFormatter stringFromDate:value];
    } else if ([value isKindOfClass:[CBRJSONObject class]]) {
        return [value jsonRepresentation];
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:[value count]];
        [value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (encodeJsonValue(obj, connection)) {
                [result addObject:encodeJsonValue(obj, connection)];
            }
        }];
        return result;
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[value count]];
        [value enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (encodeJsonValue(obj, connection)) {
                result[key] = encodeJsonValue(obj, connection);
            }
        }];
        return result;
    }

    return nil;
}

@implementation CBRJSONObject

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

+ (NSArray *)parse:(id)object error:(NSError **)error
{
    id jsonObject = nil;
    if ([object isKindOfClass:NSArray.class] || [object isKindOfClass:NSDictionary.class]) {
        jsonObject = object;
    } else if ([object isKindOfClass:NSData.class]) {
        jsonObject = [NSJSONSerialization JSONObjectWithData:object options:kNilOptions error:error];
    } else if ([object isKindOfClass:NSString.class]) {
        jsonObject = [NSJSONSerialization JSONObjectWithData:[object dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:error];
    }

    if (jsonObject == nil) {
        return nil;
    }

    NSMutableArray *result = [NSMutableArray array];
    if ([jsonObject isKindOfClass:NSDictionary.class]) {
        id object = [[self alloc] initWithDictionary:jsonObject error:error];

        if (object != nil) {
            [result addObject:object];
            return result;
        }

        return nil;
    } else if ([jsonObject isKindOfClass:NSArray.class]) {
        for (id jsonDictionary in jsonObject) {
            id object = [[self alloc] initWithDictionary:jsonDictionary error:error];

            if (object == nil) {
                return nil;
            }

            [result addObject:object];
        }

        return result;
    }

    return result;
}

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        [[self.class propertyClassMapping] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Class  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj == [NSDate class] || [obj isKindOfClass:[NSDate class]]) {
                [self setValue:[NSDate date] forKey:key];
            }
        }];
    }
    return self;
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

    for (NSString *property in serializableProperties) {
        id value = [self valueForKey:property];
        NSString *jsonProperty = [connection.propertyMapping cloudKeyPathFromPersistentObjectProperty:property];
        result[jsonProperty] = encodeJsonValue(value, connection) ?: [NSNull null];
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
