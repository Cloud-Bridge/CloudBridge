//
//  RLMEntity4.m
//  CloudBridge
//
//  Created by Oliver Letterer on 27.03.17.
//  Copyright © 2017 Oliver Letterer. All rights reserved.
//

#import "RLMEntity4.h"

@implementation RLMEntity4
@dynamic array;

+ (NSDictionary<NSString *, NSString *> *)userInfo
{
    return @{
             @"restBaseURL": @"entity4",
             };
}

@end
