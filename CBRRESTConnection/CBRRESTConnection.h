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
#import <AFNetworking/AFNetworking.h>

#import <CBRRESTConnection/CBRPropertyMapping.h>
#import <CBRRESTConnection/CBRIdentityPropertyMapping.h>
#import <CBRRESTConnection/CBRUnderscoredPropertyMapping.h>

#import <CBRRESTConnection/NSManagedObject+CBRRESTConnection.h>
#import <CBRRESTConnection/CBRJSONDictionaryTransformer.h>
#import <CBRRESTConnection/NSDictionary+CBRRESTConnection.h>
#import <CBRRESTConnection/CBREntityDescription+CBRRESTConnection.h>
#import <CBRRESTConnection/CBRAttributeDescription+CBRRESTConnection.h>
#import <CBRRESTConnection/CBRRelationshipDescription+CBRRESTConnection.h>

extern NSString * const CBRRESTConnectionUserInfoURLOverrideKey;



/**
 `CBRCloudConnection` implementation for RESTful backends.
 
 * `requestSerializer` defaults to `AFJSONRequestSerializer` and `responseSerializer` to `AFJSONResponseSerializer`.
 * CRUD accessors require `restBaseURL` to be set on the corresponding `NSEntityDescription`.
 */
@interface CBRRESTConnection : AFHTTPRequestOperationManager <CBRCloudConnection>

/**
 @param propertyMapping The `CBRRESTConnection.objectTransformers`' property mapping. `CoreDataCloud` ships with `CBRUnderscoredPropertyMapping` and `CBRIdentityPropertyMapping`.
 */
- (instancetype)initWithBaseURL:(NSURL *)url propertyMapping:(id<CBRPropertyMapping>)propertyMapping NS_DESIGNATED_INITIALIZER;

/**
 The `objectTransformer` with underscored `propertyMapping` by default.
 */
@property (nonatomic, readonly) CBRJSONDictionaryTransformer *objectTransformer;

/**
 Fetches entites of a given type from a path with or without search parameters.
 */
- (void)fetchCloudObjectsFromPath:(NSString *)path
                       parameters:(NSDictionary *)parameters
            withCompletionHandler:(void (^)(NSArray *fetchedCloudObjects, NSError *error))completionHandler;

/**
 Substitues parameters (aka `:id`) with the corresponding values from `managedObject` based on `objectTransformer.propertyMapping`
 */
- (NSString *)pathBySubstitutingParametersInPath:(NSString *)path fromPersistentObject:(id<CBRPersistentObject>)persistentObject;

/**
 Use `initWithBaseURL:propertyMapping:`.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 Use `initWithBaseURL:propertyMapping:`.
 */
- (instancetype)initWithBaseURL:(NSURL *)url NS_DESIGNATED_INITIALIZER NS_UNAVAILABLE;

@end
