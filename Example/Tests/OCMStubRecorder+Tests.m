//
//  OCMStubRecorder+Tests.m
//  CloudBridge
//
//  Created by Oliver Letterer on 27.03.17.
//  Copyright © 2017 Oliver Letterer. All rights reserved.
//

#import "OCMStubRecorder+Tests.h"

@implementation AFQueryDescription @end

@implementation OCMStubRecorder (CBRRESTConnectionTests)

- (OCMStubRecorder *(^)(void (^)(AFQueryDescription *query)))_andQuery
{
    id (^theBlock)(void (^)(AFQueryDescription *query)) = ^ (void (^ blockToCall)(AFQueryDescription *query))
    {
        return [self andDo:^(NSInvocation *invocation) {
            AFQueryDescription *query = [[AFQueryDescription alloc] init];

            __unsafe_unretained NSString *path = nil;
            __unsafe_unretained id parameters = nil;
            __unsafe_unretained AFSuccessBlock successBlock = nil;
            __unsafe_unretained AFErrorBlock errorBlock = nil;

            [invocation getArgument:&path atIndex:2];
            [invocation getArgument:&parameters atIndex:3];
            [invocation getArgument:&successBlock atIndex:4];
            [invocation getArgument:&errorBlock atIndex:5];

            query.path = path;
            query.parameters = parameters;
            query.successBlock = successBlock;
            query.errorBlock = errorBlock;

            blockToCall(query);
        }];
    };
    return theBlock;
}

@end
