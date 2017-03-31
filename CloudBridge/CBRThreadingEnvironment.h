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

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRDefines.h>

#if CBRCoreDataAvailable
#import <CloudBridge/CBRCoreDataDatabaseAdapter.h>
#endif

#if CBRRealmAvailable
#import <CloudBridge/CBRRealmDatabaseAdapter.h>
#endif

typedef NS_ENUM(NSInteger, CBRThread) {
    CBRThreadMain,
    CBRThreadBackground,
};

@protocol CBRThreadTransferable <NSObject> @end

@interface NSNumber (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSString (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSDate (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSData (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSArray (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSDictionary (CBRThreadTransferable) <CBRThreadTransferable> @end

#if CBRCoreDataAvailable
@interface NSManagedObject (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface NSManagedObjectID (CBRThreadTransferable) <CBRThreadTransferable> @end
#endif

#if CBRRealmAvailable
@interface CBRRealmObject (CBRThreadTransferable) <CBRThreadTransferable> @end
@interface RLMThreadSafeReference (CBRThreadTransferable) <CBRThreadTransferable> @end
#endif



NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_subclassing_restricted))
@interface CBRThreadingEnvironment : NSObject

#if CBRRealmAvailable
@property (nonatomic, nullable, readonly) CBRRealmDatabaseAdapter *realmAdapter;
- (instancetype)initWithRealmAdapter:(CBRRealmDatabaseAdapter *)realmAdapter NS_DESIGNATED_INITIALIZER;
#endif

#if CBRCoreDataAvailable
@property (nonatomic, nullable, readonly) CBRCoreDataDatabaseAdapter *coreDataAdapter;
- (instancetype)initWithCoreDataAdapter:(CBRCoreDataDatabaseAdapter *)coreDataAdapter NS_DESIGNATED_INITIALIZER;
#endif

#if CBRRealmAvailable && CBRCoreDataAvailable
- (instancetype)initWithCoreDataAdapter:(CBRCoreDataDatabaseAdapter *)coreDataAdapter realmAdapter:(CBRRealmDatabaseAdapter *)realmAdapter NS_DESIGNATED_INITIALIZER;
#endif

@property (nonatomic, nullable, readonly) dispatch_queue_t queue;

- (instancetype)init NS_DESIGNATED_INITIALIZER NS_UNAVAILABLE;
- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

- (void)moveObject:(nullable id<CBRThreadTransferable>)object toThread:(CBRThread)thread completion:(void(^)(id _Nullable object, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
