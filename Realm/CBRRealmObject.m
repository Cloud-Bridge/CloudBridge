/**
 CloudBridge
 Copyright (c) 2018 Layered Pieces gUG

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

#import "CBRRealmObject.h"
#import <objc/runtime.h>
#import "CBRPersistentObject.h"

//static void dumpProperty(objc_property_t property, Class klass)
//{
//    unsigned int count = 0;
//    objc_property_attribute_t *attributes = property_copyAttributeList(property, &count);
//
//    for (unsigned int j = 0; j < count; j++) {
//        NSLog(@"[%@ - %s] %s => %s", klass, property_getName(property), attributes[j].name, attributes[j].value);
//    }
//
//    free(attributes);
//}

@implementation CBRRealmObject

+ (BOOL)resolveInstanceMethod:(SEL)selector
{
    if ([super resolveInstanceMethod:selector]) {
        return YES;
    }

    if ([CBRPersistentObjectPrototype resolveRelationshipForSelector:selector inClass:NSClassFromString(self.className)]) {
        return YES;
    }

    return NO;
}

- (id)valueForKey:(NSString *)key
{
    if (self.isInvalidated) {
        NSLog(@"[Realm] Accessing %@ of invalidated object", key);
        return nil;
    } else {
        return [super valueForKey:key];
    }
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    if (self.isInvalidated) {
        NSLog(@"[Realm] Accessing %@ of invalidated object", keyPath);
        return nil;
    } else {
        return [super valueForKeyPath:keyPath];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if (self.isInvalidated) {
        NSLog(@"[Realm] Accessing %@ of invalidated object", key);
        return;
    } else {
        return [super setValue:value forKey:key];
    }
}

+ (NSString *)className
{
    return [super className];
}

+ (NSDictionary<NSString *, NSString *> *)userInfo
{
    return @{};
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)propertyUserInfo
{
    return @{};
}

+ (nullable NSArray<NSString *> *)ignoredProperties
{
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithArray:[self nonDynamicProperties]];
    [result addObjectsFromArray:[self transformableProperties]];
    [result removeObjectsInArray:[self primitiveProperties]];

    return result;
}

+ (nullable NSArray<NSString *> *)nonDynamicProperties
{
    Class klass = NSClassFromString([self className]);

    if (objc_getAssociatedObject(klass, _cmd)) {
        return objc_getAssociatedObject(klass, _cmd);
    }

    NSMutableArray<NSString *> *result = [NSMutableArray array];

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(klass, &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];

        char *dynamic = property_copyAttributeValue(property, "D");

        if (!dynamic) {
            [result addObject:@(property_getName(property))];
            continue;
        }

        free(dynamic);
    }

    objc_setAssociatedObject(klass, _cmd, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

+ (nullable NSArray<NSString *> *)primitiveProperties
{
    Class klass = NSClassFromString([self className]);

    if (objc_getAssociatedObject(klass, _cmd)) {
        return objc_getAssociatedObject(klass, _cmd);
    }

    NSMutableArray<NSString *> *result = [NSMutableArray array];

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(klass, &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];

        char *dynamic = property_copyAttributeValue(property, "D");
        char *type = property_copyAttributeValue(property, "T");

        if (!dynamic || !type || @(type).length <= 3) {
            if (!dynamic) { free(dynamic); }
            if (!type) { free(type); }
            continue;
        }

        NSString *typeClass = [@(type) substringWithRange:NSMakeRange(2, strlen(type) - 3)];
        if ([typeClass hasPrefix:@"NSNumber"] || [typeClass hasPrefix:@"NSString"] || [typeClass hasPrefix:@"NSDate"] || [typeClass hasPrefix:@"NSData"]) {
            [result addObject:@(property_getName(property))];
        } else if ([typeClass hasPrefix:@"RLMLinkingObjects<"]) {
            [result addObject:@(property_getName(property))];
        } else if ([NSClassFromString(typeClass) isSubclassOfClass:[CBRRealmObject class]]) {
            [result addObject:@(property_getName(property))];
        } else if ([NSClassFromString(typeClass) conformsToProtocol:@protocol(NSSecureCoding)]) {
            continue;
        } else if ([typeClass isEqualToString:@"?@"] || NSClassFromString(typeClass) == nil) {
            assert(false);
        }

        free(dynamic);
        free(type);
    }

    objc_setAssociatedObject(klass, _cmd, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

+ (nullable NSArray<NSString *> *)transformableProperties
{
    Class klass = NSClassFromString([self className]);

    if (objc_getAssociatedObject(klass, _cmd)) {
        return objc_getAssociatedObject(klass, _cmd);
    }

    NSMutableArray<NSString *> *result = [NSMutableArray array];

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(klass, &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];

        char *dynamic = property_copyAttributeValue(property, "D");
        char *type = property_copyAttributeValue(property, "T");

        if (!dynamic || !type || @(type).length <= 3) {
            if (!dynamic) { free(dynamic); }
            if (!type) { free(type); }
            continue;
        }

        NSString *typeClass = [@(type) substringWithRange:NSMakeRange(2, strlen(type) - 3)];
        if (![typeClass isEqualToString:NSStringFromClass(NSString.class)] && ![typeClass isEqualToString:NSStringFromClass(NSData.class)] && ![typeClass isEqualToString:NSStringFromClass(NSNumber.class)] && ![typeClass isEqualToString:NSStringFromClass(NSDate.class)]) {
            if ([NSClassFromString(typeClass) conformsToProtocol:@protocol(NSSecureCoding)]) {
                [result addObject:@(property_getName(property))];
            }
        }

        free(dynamic);
        free(type);
    }

    free(properties);

    objc_setAssociatedObject(klass, _cmd, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return result;
}

+ (void)initialize
{
    if ([self superclass] != [CBRRealmObject class]) {
        return;
    }

    for (NSString *property in [self primitiveProperties]) {
        IMP getter = imp_implementationWithBlock(^NSData *(id self) {
            return [self primitiveValueForKey:property];
        });
        class_addMethod(self, NSSelectorFromString(property), getter, "@@:");

        IMP setter = imp_implementationWithBlock(^(id self, id value) {
            [self setPrimitiveValue:value forKey:property];
        });
        NSArray *setterName = @[ @"set", [property substringToIndex:1].capitalizedString, [property substringFromIndex:1], @":" ];
        class_addMethod(self, NSSelectorFromString([setterName componentsJoinedByString:@""]), setter, "v@:@");
    }

    for (NSString *property in [self transformableProperties]) {
        NSString *backingProperty = [property stringByAppendingString:@"_Data"];

        IMP getter = imp_implementationWithBlock(^NSData *(id self) {
            return objc_getAssociatedObject(self, NSSelectorFromString(backingProperty));
        });
        BOOL success = class_addMethod(self, NSSelectorFromString(backingProperty), getter, "@@:");
        assert(success);

        IMP setter = imp_implementationWithBlock(^(id self, NSData *data) {
            objc_setAssociatedObject(self, NSSelectorFromString(backingProperty), data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        });
        NSArray *setterName = @[ @"set", [backingProperty substringToIndex:1].capitalizedString, [backingProperty substringFromIndex:1], @":" ];
        success = class_addMethod(self, NSSelectorFromString([setterName componentsJoinedByString:@""]), setter, "v@:@");
        assert(success);

        objc_property_attribute_t attributes[] = {
            {"&", ""},
            {"N", ""},
            {"D", ""},
            {"G", [backingProperty cStringUsingEncoding:NSASCIIStringEncoding]},
            {"S", [[setterName componentsJoinedByString:@""] cStringUsingEncoding:NSASCIIStringEncoding]},
            {"T", "@\"NSData\""},
        };

        success = class_addProperty(self, [backingProperty cStringUsingEncoding:NSASCIIStringEncoding], attributes, sizeof(attributes) / sizeof(objc_property_attribute_t));
        assert(success);

        {
            IMP getter = imp_implementationWithBlock(^id(id self) {
                return [self primitiveValueForKey:property];
            });
            class_addMethod(self, NSSelectorFromString(property), getter, "@@:");

            IMP setter = imp_implementationWithBlock(^(id self, id value) {
                [self setPrimitiveValue:value forKey:property];
            });
            NSArray *setterName = @[ @"set", [property substringToIndex:1].capitalizedString, [property substringFromIndex:1], @":" ];
            class_addMethod(self, NSSelectorFromString([setterName componentsJoinedByString:@""]), setter, "v@:@");
        }
    }
}

- (nullable id)primitiveValueForKey:(NSString *)property
{
    if (objc_getAssociatedObject(self, NSSelectorFromString(property))) {
        return objc_getAssociatedObject(self, NSSelectorFromString(property));
    }

    if ([[self.class transformableProperties] containsObject:property]) {
        NSString *backingProperty = [property stringByAppendingString:@"_Data"];

        NSData *data = [self valueForKey:backingProperty];
        if (data != nil) {
            NSError *error = nil;
            id result = [NSKeyedUnarchiver unarchiveTopLevelObjectWithData:data error:&error];

            if (error != nil) {
                NSLog(@"[%@ - %@], error unarchiving: %@", [self class], property, error);
            }

            objc_setAssociatedObject(self, NSSelectorFromString(property), result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        return objc_getAssociatedObject(self, NSSelectorFromString(property));
    }

    return nil;
}

- (void)setPrimitiveValue:(nullable id)value forKey:(NSString *)property
{
    objc_setAssociatedObject(self, NSSelectorFromString(property), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if ([[self.class transformableProperties] containsObject:property]) {
        NSString *backingProperty = [property stringByAppendingString:@"_Data"];

        if (value == nil) {
            [self setValue:nil forKey:backingProperty];
        } else {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            [self setValue:data forKey:backingProperty];
        }
    }
}

@end
