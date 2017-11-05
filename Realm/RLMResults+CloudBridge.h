//
//  RLMResults+CloudBridge.h
//  Pods
//
//  Created by Oliver Letterer on 05.04.17.
//
//

#import <Realm/RLMResults.h>



NS_ASSUME_NONNULL_BEGIN

@interface RLMResults<RLMObjectType> (CloudBridge)

- (NSSet<RLMObjectType> *)setValue;
- (NSArray<RLMObjectType> *)allObjects;
- (NSArray<RLMObjectType> *)sortedArrayUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors;

@end

NS_ASSUME_NONNULL_END
