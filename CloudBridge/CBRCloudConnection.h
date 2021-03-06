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

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRCloudObject.h>
#import <CloudBridge/CBRPersistentObject.h>
#import <CloudBridge/CBRCloudObjectTransformer.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Abstract interface that handles all communication with a specific Cloud backend.
 */
@protocol CBRCloudConnection <NSObject>

@property (nonatomic, readonly) id<CBRCloudObjectTransformer> objectTransformer;

- (void)fetchCloudObjectsForEntity:(CBREntityDescription *)entity
                     withPredicate:(nullable NSPredicate *)predicate
                          userInfo:(nullable NSDictionary *)userInfo
                 completionHandler:(void(^_Nullable)(NSArray * _Nullable fetchedObjects, NSError * _Nullable error))completionHandler;

- (void)createCloudObject:(nullable id<CBRCloudObject>)cloudObject
      forPersistentObject:(id<CBRPersistentObject>)persistentObject
             withUserInfo:(nullable NSDictionary *)userInfo
        completionHandler:(void(^_Nullable)(id<CBRCloudObject> _Nullable cloudObject, NSError * _Nullable error))completionHandler;

- (void)latestCloudObjectForPersistentObject:(id<CBRPersistentObject>)persistentObject
                                withUserInfo:(nullable NSDictionary *)userInfo
                           completionHandler:(void(^_Nullable)(id<CBRCloudObject> _Nullable cloudObject, NSError * _Nullable error))completionHandler;

- (void)saveCloudObject:(nullable id<CBRCloudObject>)cloudObject
    forPersistentObject:(id<CBRPersistentObject>)persistentObject
           withUserInfo:(nullable NSDictionary *)userInfo
      completionHandler:(void(^_Nullable)(id<CBRCloudObject> _Nullable cloudObject, NSError * _Nullable error))completionHandler;

- (void)deleteCloudObject:(nullable id<CBRCloudObject>)cloudObject
      forPersistentObject:(id<CBRPersistentObject>)persistentObject
             withUserInfo:(nullable NSDictionary *)userInfo
        completionHandler:(void(^_Nullable)(NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
