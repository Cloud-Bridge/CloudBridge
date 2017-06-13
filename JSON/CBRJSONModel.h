//
//  CBRJSONModel.h
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRThreadingEnvironment.h>

@class AFHTTPSessionManager;



NS_ASSUME_NONNULL_BEGIN

@interface CBRJSONModel : NSObject <NSSecureCoding, NSCopying, CBRThreadTransferable>

@property (nonatomic, class) AFHTTPSessionManager *sessionManager;

+ (NSDictionary<NSString *, Class> *)propertyClassMapping;
+ (NSArray<NSString *> *)serializableProperties;
+ (NSDictionary<NSString *, Class> *)relationMapping;

@property (nonatomic, readonly) NSDictionary<NSString *, id> *jsonRepresentation;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (id)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (BOOL)patchWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;
+ (void)fetchObjectsFromPath:(NSString *)path completion:(void(^)(NSArray * _Nullable objects, NSError * _Nullable error))completion;
- (void)createToPath:(NSString *)path completion:(void(^ _Nullable)(id _Nullable object, NSError * _Nullable error))completion;

@end



@interface CBRJSONModelValueTransformer : NSValueTransformer

+ (Class)destinationClass;

@end

NS_ASSUME_NONNULL_END
