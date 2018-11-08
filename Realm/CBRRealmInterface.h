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

#import <Realm/Realm.h>
#import <Foundation/Foundation.h>

#import <CloudBridge/CBRRealmObject.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
#import <CloudBridge/CBRPersistentObject.h>
#import <CloudBridge/CBRPersistentObjectCache.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>

@class CBRThreadingEnvironment;



NS_ASSUME_NONNULL_BEGIN

@interface CBRRealmObject (CBRPersistentObject) <CBRPersistentObject>

@end



__attribute__((objc_subclassing_restricted))
@interface CBRRealmInterface : NSObject <CBRPersistentStoreInterface>

@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) RLMRealmConfiguration *configuration;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (CBRPersistentObjectCache *)cacheForRealm:(RLMRealm *)realm;

@end



@interface CBRRealmInterface (Convenience)

- (BOOL)assertClasses:(nullable NSArray<Class> *)classes;
- (BOOL)assertClassesExcept:(nullable NSArray<Class> *)exceptClasses;

@end

NS_ASSUME_NONNULL_END
