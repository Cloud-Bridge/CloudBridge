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

#import <CloudBridge/CloudBridge.h>

#import <CBRRESTConnection/CBRPropertyMapping.h>
#import <CBRRESTConnection/NSDictionary+CBRRESTConnection.h>



/**
 Maps between `NSManagedObject` instances and `NSDictionary` instances.
 */
@interface CBRJSONDictionaryTransformer : NSObject <CBRCloudObjectTransformer>

/**
 Use `initWithPropertyMapping:`.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;

/**
 The designated initializer.
 */
- (instancetype)initWithPropertyMapping:(id<CBRPropertyMapping>)propertyMapping NS_DESIGNATED_INITIALIZER;

/**
 Specifies tge property mapping. `CoreDataCloud` ships with `CBRUnderscoredPropertyMapping` and `CBRIdentityPropertyMapping`.
 */
@property (nonatomic, readonly) id<CBRPropertyMapping> propertyMapping;

/**
 Used for converting between `NSDate` and `NSString` instances.
 
 Defaults to `yyyy-MM-dd'T'HH:mm:ss'Z'` format GMT timezone.
 */
@property (nonatomic, copy) NSDateFormatter *dateFormatter;

/**
 Transforms a `NSManagedObject` instance into a `NSDictionary`.
 */
- (NSDictionary *)cloudObjectFromPersistentObject:(id<CBRPersistentObject>)persistentObject;

/**
 Updates a `NSMutableDictionary` instance with all properties of a `NSManagedObject`.
 */
- (void)updateCloudObject:(NSMutableDictionary *)cloudObject withPropertiesFromPersistentObject:(id<CBRPersistentObject>)persistentObject;

/**
 Transforms a `NSDictionary` instance into a `NSManagedObject`.
 */
- (id<CBRPersistentObject>)persistentObjectFromCloudObject:(NSDictionary *)record
                                                 forEntity:(CBREntityDescription *)entity;

/**
 Updates a `NSManagedObject` instance with all properties of a `NSDictionary`.
 */
- (void)updatePersistentObject:(id<CBRPersistentObject>)persistentObject withPropertiesFromCloudObject:(NSDictionary *)cloudObject;

/**
 Converts a `managedObjectValue` into valid value for a cloud object.
 */
- (id)cloudValueFromPersistentObjectValue:(id)managedObjectValue forAttributeDescription:(CBRAttributeDescription *)attributeDescription;

/**
 Converts a `cloudValue` into valid value for a `NSManagedObject`.
 */
- (id)persistentObjectValueFromCloudValue:(id)cloudValue forAttributeDescription:(CBRAttributeDescription *)attributeDescription;

/**
 Converts a `NSPropertyDescription` into a cloud object key path.
 */
- (NSString *)cloudKeyPathFromPropertyDescription:(id<CBRPropertyDescription>)propertyDescription;

/**
 Converts a cloud key path into a `NSManagedObject` key path.
 */
- (NSString *)persistentObjectKeyPathFromCloudKeyPath:(NSString *)cloudKeyPath ofEntity:(CBREntityDescription *)entity;

@end
