/**
 CBRRESTConnection
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

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

#import "CBRUnderscoredPropertyMapping.h"

static NSString *underscoredStringFromCamelizedString(NSString *camelizedString)
{
    static NSCache *cache = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });

    NSString *cachedString = [cache objectForKey:camelizedString];
    if (cachedString) {
        return cachedString;
    }

    NSString *underscoredString = camelizedString;

    underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"([A-Z]+)([A-Z][a-z])" withString:@"$1_$2" options:NSRegularExpressionSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"([a-z\\d])([A-Z])" withString:@"$1_$2" options:NSRegularExpressionSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = [underscoredString stringByReplacingOccurrencesOfString:@"-" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, underscoredString.length)];
    underscoredString = underscoredString.lowercaseString;

    [cache setObject:underscoredString forKey:camelizedString];

    return underscoredString;
}

static NSString *camelizedStringFromUnderscoredString(NSString *underscoredString)
{
    static NSCache *cache = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
    });

    NSString *cachedString = [cache objectForKey:underscoredString];
    if (cachedString) {
        return cachedString;
    }

    NSArray *components = [underscoredString componentsSeparatedByString:@"_"];

    NSMutableString *camelizedString = [NSMutableString stringWithCapacity:underscoredString.length];
    [components enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        if (idx == 0) {
            [camelizedString appendString:component];
        } else {
            if (component.length > 0) {
                NSString *firstLetter = [component substringToIndex:1];
                NSString *restString = [component substringFromIndex:1];
                [camelizedString appendFormat:@"%@%@", firstLetter.uppercaseString, restString];
            }
        }
    }];

    [cache setObject:camelizedString forKey:underscoredString];
    return camelizedString;
}



@interface CBRUnderscoredPropertyMapping ()
@property (nonatomic, strong) NSCache *attributesCache;
@property (nonatomic, strong) NSMutableDictionary *managedObjectJSONObjectNamingConventions;
@property (nonatomic, strong) NSMutableDictionary *JSONObjectManagedObjectNamingConventions;
@end

@implementation CBRUnderscoredPropertyMapping

- (NSCache *)attributesCache
{
    @synchronized(self) {
        if (!_attributesCache) {
            _attributesCache = [[NSCache alloc] init];
        }

        return _attributesCache;
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        self.managedObjectJSONObjectNamingConventions = [NSMutableDictionary dictionary];
        self.JSONObjectManagedObjectNamingConventions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerObjcNamingConvention:(NSString *)objcNamingConvention
             forJSONNamingConvention:(NSString *)JSONNamingConvention
{
    NSParameterAssert(objcNamingConvention);
    NSParameterAssert(JSONNamingConvention);

    self.managedObjectJSONObjectNamingConventions[objcNamingConvention] = JSONNamingConvention;
    self.JSONObjectManagedObjectNamingConventions[JSONNamingConvention] = objcNamingConvention;

    [self.attributesCache removeAllObjects];
}

- (NSString *)cloudKeyPathFromManagedObjectProperty:(NSString *)managedObjectProperty
{
    NSCache *attributesCache = self.attributesCache;
    NSString *cachedKey = [attributesCache objectForKey:managedObjectProperty];
    if (cachedKey) {
        return cachedKey;
    }

    NSMutableCharacterSet *lowercaseCharacterSet = [NSMutableCharacterSet lowercaseLetterCharacterSet];
    [lowercaseCharacterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSMutableCharacterSet *uppercaseCharacterSet = [NSMutableCharacterSet uppercaseLetterCharacterSet];

    NSDictionary *mergedManagedObjectJSONObjectNamingConventions = self.managedObjectJSONObjectNamingConventions;
    NSArray *possibleConventions = [mergedManagedObjectJSONObjectNamingConventions.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        } else if (obj1.length > obj2.length) {
            return NSOrderedAscending;
        }

        return NSOrderedSame;
    }];

    NSString *originalAttribute = managedObjectProperty;
    for (NSString *namingConvention in possibleConventions) {
        if ([namingConvention isEqualToString:managedObjectProperty]) {
            NSString *key = mergedManagedObjectJSONObjectNamingConventions[namingConvention];
            [attributesCache setObject:key forKey:managedObjectProperty];
            return key;
        }

        NSRange range = [managedObjectProperty.uppercaseString rangeOfString:namingConvention.uppercaseString];

        if (range.location == NSNotFound) {
            continue;
        }

        BOOL isAtStartOfString = range.location == 0;
        BOOL isAtEndOfString = range.location + range.length == managedObjectProperty.length;

        if (isAtStartOfString && isAtEndOfString) {
            managedObjectProperty = [managedObjectProperty stringByReplacingCharactersInRange:range withString:mergedManagedObjectJSONObjectNamingConventions[namingConvention]];
            continue;
        }

        BOOL isLeftCharacterValid = isAtStartOfString;
        BOOL isRightCharacterValid = isAtEndOfString;

        if (!isLeftCharacterValid && !isAtStartOfString) {
            isLeftCharacterValid = [lowercaseCharacterSet characterIsMember:[managedObjectProperty characterAtIndex:range.location - 1]];
        }

        if (!isRightCharacterValid && !isAtEndOfString) {
            if (managedObjectProperty.length > range.location + range.length + 1) {
                isRightCharacterValid = ![uppercaseCharacterSet characterIsMember:[managedObjectProperty characterAtIndex:range.location + range.length + 1]];
            } else {
                isRightCharacterValid = [lowercaseCharacterSet characterIsMember:[managedObjectProperty characterAtIndex:range.location + range.length]];
            }
        }

        // string is in the middle, only allow substitution of full path components
        if (isLeftCharacterValid && isRightCharacterValid) {
            NSString *replacementString = mergedManagedObjectJSONObjectNamingConventions[namingConvention];

            if (!isAtStartOfString) {
                replacementString = [@"_" stringByAppendingString:replacementString];
            }

            if (!isAtEndOfString) {
                replacementString = [replacementString stringByAppendingString:@"_"];
            }

            managedObjectProperty = [managedObjectProperty stringByReplacingCharactersInRange:range withString:replacementString];
        }
    }

    NSString *underscoredString = underscoredStringFromCamelizedString(managedObjectProperty);
    [attributesCache setObject:underscoredString forKey:originalAttribute];

    return underscoredString;
}

- (NSString *)managedObjectPropertyFromCloudKeyPath:(NSString *)cloudKeyPath
{
    NSCache *attributesCache = self.attributesCache;
    NSString *cachedKey = [attributesCache objectForKey:cloudKeyPath];
    if (cachedKey) {
        return cachedKey;
    }

    NSDictionary *mergedJSONObjectManagedObjectNamingConventions = self.JSONObjectManagedObjectNamingConventions;
    NSArray *possibleConventions = [mergedJSONObjectManagedObjectNamingConventions.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        if (obj1.length < obj2.length) {
            return NSOrderedDescending;
        } else if (obj1.length > obj2.length) {
            return NSOrderedAscending;
        }

        return NSOrderedSame;
    }];

    NSString *originalJSONObjectKeyPath = cloudKeyPath;
    for (NSString *namingConvention in possibleConventions) {
        if ([cloudKeyPath isEqualToString:namingConvention]) {
            NSString *key = mergedJSONObjectManagedObjectNamingConventions[cloudKeyPath];
            [attributesCache setObject:key forKey:cloudKeyPath];
            return key;
        }

        NSRange range = [cloudKeyPath rangeOfString:namingConvention];

        if (range.location == NSNotFound) {
            continue;
        }

        BOOL isAtStartOfString = range.location == 0;
        BOOL isAtEndOfString = range.location + range.length == cloudKeyPath.length;

        if (isAtStartOfString && isAtEndOfString) {
            cloudKeyPath = [cloudKeyPath stringByReplacingCharactersInRange:range withString:mergedJSONObjectManagedObjectNamingConventions[namingConvention]];
            continue;
        }

        BOOL isLeftCharacterValid = isAtStartOfString;
        BOOL isRightCharacterValid = isAtEndOfString;

        if (!isLeftCharacterValid && !isAtStartOfString) {
            isLeftCharacterValid = [cloudKeyPath characterAtIndex:range.location - 1] == '_';
        }

        if (!isRightCharacterValid && !isAtEndOfString) {
            isRightCharacterValid = [cloudKeyPath characterAtIndex:range.location + range.length] == '_';
        }

        // string is in the middle, only allow substitution of full path components
        if (isLeftCharacterValid && isRightCharacterValid) {
            cloudKeyPath = [cloudKeyPath stringByReplacingCharactersInRange:range withString:mergedJSONObjectManagedObjectNamingConventions[namingConvention]];
        }
    }

    NSString *camelizedString = camelizedStringFromUnderscoredString(cloudKeyPath);
    [attributesCache setObject:camelizedString forKey:originalJSONObjectKeyPath];

    return camelizedString;
}

@end
