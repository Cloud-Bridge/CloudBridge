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

#import "CBRRealmObject.h"
#import <objc/runtime.h>

@implementation CBRRealmObject

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
    return [self transformableProperties];
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

//        unsigned int count = 0;
//        objc_property_attribute_t *attributes = property_copyAttributeList(property, &count);
//
//        for (unsigned int j = 0; j < count; j++) {
//            NSLog(@"[%@ - %s] %s => %s", self, property_getName(property), attributes[j].name, attributes[j].value);
//        }
//
//        free(attributes);

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

    for (NSString *property in [self transformableProperties]) {
        NSString *backingProperty = [property stringByAppendingString:@"Data"];

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
            {"G", [backingProperty cStringUsingEncoding:NSASCIIStringEncoding]},
            {"S", [[setterName componentsJoinedByString:@""] cStringUsingEncoding:NSASCIIStringEncoding]},
            {"T", "@\"NSData\""},
        };
        
        success = class_addProperty(self, [backingProperty cStringUsingEncoding:NSASCIIStringEncoding], attributes, sizeof(attributes) / sizeof(objc_property_attribute_t));
        assert(success);

        {
            IMP getter = imp_implementationWithBlock(^id(id self) {
                if (objc_getAssociatedObject(self, NSSelectorFromString(property))) {
                    return objc_getAssociatedObject(self, NSSelectorFromString(property));
                }

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
            });
            success = class_addMethod(self, NSSelectorFromString(property), getter, "@@:");
            assert(success);

            IMP setter = imp_implementationWithBlock(^(id self, id value) {
                objc_setAssociatedObject(self, NSSelectorFromString(property), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                if (value == nil) {
                    [self setValue:nil forKey:backingProperty];
                } else {
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
                    [self setValue:data forKey:backingProperty];
                }
            });
            NSArray *setterName = @[ @"set", [property substringToIndex:1].capitalizedString, [property substringFromIndex:1], @":" ];
            success = class_addMethod(self, NSSelectorFromString([setterName componentsJoinedByString:@""]), setter, "v@:@");
            assert(success);
        }
    }
}

@end
