//
//  RLMResults+CloudBridge.m
//  Pods
//
//  Created by Oliver Letterer on 05.04.17.
//
//

#import "RLMResults+CloudBridge.h"



@implementation RLMResults (CloudBridge)

- (NSSet *)setValue
{
    return [NSSet setWithArray:self.allObjects];
}

- (NSArray *)allObjects
{
    return [self sortedArrayUsingDescriptors:@[]];
}

- (NSArray *)sortedArrayUsingDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
{
    NSMutableArray *allObjects = [NSMutableArray array];

    for (id object in self) {
        [allObjects addObject:object];
    }

    return [allObjects sortedArrayUsingDescriptors:sortDescriptors];
}

@end
