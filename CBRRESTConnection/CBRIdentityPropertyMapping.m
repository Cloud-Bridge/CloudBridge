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

#import "CBRIdentityPropertyMapping.h"

static NSString *filterNamingConvention(NSString *parentString, NSString *namingConvention, NSString *replacement)
{
    {
        NSString *capitalizedNamingConvention = [[namingConvention substringToIndex:1].uppercaseString stringByAppendingString:[namingConvention substringFromIndex:1]];

        NSRange range = [parentString rangeOfString:capitalizedNamingConvention];
        if (range.location != NSNotFound) {
            NSString *capitalizedReplacement = [[replacement substringToIndex:1].uppercaseString stringByAppendingString:[replacement substringFromIndex:1]];
            parentString = [parentString stringByReplacingOccurrencesOfString:capitalizedNamingConvention withString:capitalizedReplacement];
        }
    }

    {
        NSRange range = [parentString rangeOfString:namingConvention];
        if (range.location != NSNotFound) {
            parentString = [parentString stringByReplacingOccurrencesOfString:namingConvention withString:replacement];
        }
    }

    return parentString;
}

@interface CBRIdentityPropertyMapping ()
@property (nonatomic, strong) NSMutableDictionary *managedObjectJSONObjectNamingConventions;
@property (nonatomic, strong) NSMutableDictionary *JSONObjectManagedObjectNamingConventions;
@end


@implementation CBRIdentityPropertyMapping

- (instancetype)init
{
    if (self = [super init]) {
        _managedObjectJSONObjectNamingConventions = [NSMutableDictionary dictionary];
        _JSONObjectManagedObjectNamingConventions = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)managedObjectPropertyFromCloudKeyPath:(NSString *)cloudKeyPath
{
    for (NSString *namingConvention in self.JSONObjectManagedObjectNamingConventions) {
        cloudKeyPath = filterNamingConvention(cloudKeyPath, namingConvention, self.JSONObjectManagedObjectNamingConventions[namingConvention]);
    }

    return cloudKeyPath;
}

- (NSString *)cloudKeyPathFromManagedObjectProperty:(NSString *)managedObjectProperty
{
    for (NSString *namingConvention in self.managedObjectJSONObjectNamingConventions) {
        managedObjectProperty = filterNamingConvention(managedObjectProperty, namingConvention, self.managedObjectJSONObjectNamingConventions[namingConvention]);
    }

    return managedObjectProperty;
}

- (void)registerObjcNamingConvention:(NSString *)objcNamingConvention
             forJSONNamingConvention:(NSString *)JSONNamingConvention
{
    NSParameterAssert(objcNamingConvention);
    NSParameterAssert(JSONNamingConvention);

    self.managedObjectJSONObjectNamingConventions[objcNamingConvention] = JSONNamingConvention;
    self.JSONObjectManagedObjectNamingConventions[JSONNamingConvention] = objcNamingConvention;
}

@end
