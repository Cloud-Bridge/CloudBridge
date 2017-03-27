//
//  OCMStubRecorder+Tests.h
//  CloudBridge
//
//  Created by Oliver Letterer on 27.03.17.
//  Copyright © 2017 Oliver Letterer. All rights reserved.
//

#import <OCMock/OCMock.h>
#import <Foundation/Foundation.h>



typedef void(^AFSuccessBlock)(NSURLSessionDataTask *task, id responseObject);
typedef void(^AFErrorBlock)(NSURLSessionDataTask *task, NSError *error);

@interface AFQueryDescription : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) id parameters;
@property (nonatomic, copy) AFSuccessBlock successBlock;
@property (nonatomic, copy) AFErrorBlock errorBlock;
@end



@interface OCMStubRecorder (CBRRESTConnectionTests)

#define andQuery(aBlock) _andQuery(aBlock)
@property (nonatomic, readonly) OCMStubRecorder *(^ _andQuery)(void (^)(AFQueryDescription *query));

@end

