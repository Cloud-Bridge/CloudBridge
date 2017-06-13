//
//  CBRJSONModel.h
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRThreadingEnvironment.h>



NS_ASSUME_NONNULL_BEGIN

@protocol CBRJSONObject <NSObject>
@end



@interface CBRJSONObject : NSObject <NSSecureCoding, NSCopying, CBRThreadTransferable>

+ (NSDictionary<NSString *, Class> *)propertyClassMapping;
+ (NSArray<NSString *> *)serializableProperties;
+ (NSDictionary<NSString *, Class> *)relationMapping;

@property (nonatomic, readonly) NSDictionary<NSString *, id> *jsonRepresentation;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (id)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (BOOL)patchWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;

@end



@interface CBRJSONObjectValueTransformer : NSValueTransformer

+ (Class)destinationClass;

@end

NS_ASSUME_NONNULL_END
