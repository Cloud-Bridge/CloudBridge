//
//  RLMEntity6.m
//  CloudBridge
//
//  Created by Oliver Letterer on 27.03.17.
//  Copyright © 2017 Oliver Letterer. All rights reserved.
//

#import "RLMEntity6.h"

@implementation RLMEntity6Child
@end



@implementation RLMEntity6

+ (NSDictionary *)linkingObjectsProperties
{
    return @{
             @"children": [RLMPropertyDescriptor descriptorWithClass:RLMEntity6Child.class propertyName:@"parent"],
             };
}

+ (NSDictionary<NSString *, NSString *> *)userInfo
{
    return @{
             @"restBaseURL": @"entity6",
             };
}

+ (NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *)propertyUserInfo
{
    return @{
             @"children": @{
                     @"cloudBridgeCascades": @"1",
                     @"restBaseURL": @"entity6/:id/children",
                     },
             };
}

@end
