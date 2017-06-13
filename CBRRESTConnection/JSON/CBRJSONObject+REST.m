//
//  CBRJSONObject+REST.m
//  Pods
//
//  Created by Oliver Letterer on 13.06.17.
//
//

#import "CBRJSONObject+REST.h"
#import <AFNetworking/AFHTTPSessionManager.h>

static AFHTTPSessionManager *_sessionManager = nil;



@implementation CBRJSONObject (REST)

+ (void)setSessionManager:(AFHTTPSessionManager *)sessionManager
{
    _sessionManager = sessionManager;
}

+ (AFHTTPSessionManager *)sessionManager
{
    return _sessionManager;
}

+ (void)fetchObjectsFromPath:(NSString *)path completion:(void(^)(NSArray * _Nullable objects, NSError * _Nullable error))completion
{
    assert([self sessionManager]);
    [[self sessionManager] GET:path parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = @[ responseObject ];
        }

        NSError *error = nil;
        NSMutableArray *results = [NSMutableArray array];
        for (NSDictionary *json in responseObject) {
            CBRJSONObject *model = [[self alloc] initWithDictionary:json error:&error];

            if (error == nil) {
                [results addObject:model];
            } else {
                completion(nil, error);
                return;
            }
        }

        completion(results, nil);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completion(nil, error);
    }];
}

- (void)createToPath:(NSString *)path completion:(void(^ _Nullable)(id _Nullable object, NSError * _Nullable error))completion
{
    assert([self.class sessionManager]);
    [[self.class sessionManager] POST:path parameters:self.jsonRepresentation progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        [self patchWithDictionary:responseObject error:&error];

        if (completion) {
            completion(self, error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

@end
