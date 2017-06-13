//
//  CBRJSONObject+REST.h
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRJSONObject.h>

@class AFHTTPSessionManager;



NS_ASSUME_NONNULL_BEGIN

@interface CBRJSONObject (REST)

@property (nonatomic, class) AFHTTPSessionManager *sessionManager;

+ (void)fetchObjectsFromPath:(NSString *)path completion:(void(^)(NSArray * _Nullable objects, NSError * _Nullable error))completion;
- (void)createToPath:(NSString *)path completion:(void(^ _Nullable)(id _Nullable object, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
