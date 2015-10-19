/**
 CBRRESTConnection
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "CBRRESTConnection.h"

#import <CBRUnderscoredPropertyMapping.h>
#import <CBREntityDescription+CBRRESTConnection.h>

NSString * const CBRRESTConnectionUserInfoURLOverrideKey = @"restBaseURL";



@interface _CBRRESTConnectionFetchQuery : NSObject
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *parameters;
@end

@implementation _CBRRESTConnectionFetchQuery
@end



@implementation CBRRESTConnection

#pragma mark - Initialization

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithPropertyMapping:(id<CBRPropertyMapping>)propertyMapping sessionManager:(AFHTTPSessionManager *)sessionManager
{
    if (self = [super init]) {
        _propertyMapping = propertyMapping;
        _objectTransformer = [[CBRJSONDictionaryTransformer alloc] initWithPropertyMapping:propertyMapping];
        _sessionManager = sessionManager;
    }
    return self;
}

#pragma mark - Instance methods

- (void)fetchCloudObjectsFromPath:(NSString *)path
                       parameters:(NSDictionary *)parameters
            withCompletionHandler:(void (^)(NSArray *fetchedCloudObjects, NSError *error))completionHandler
{
    void(^successHandler)(id responseObject) = ^(id responseObject) {
        NSMutableArray *result = [NSMutableArray array];

        if ([responseObject isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dictionary in responseObject) {
                if ([dictionary isKindOfClass:[NSDictionary class]]) {
                    [result addObject:dictionary];
                }
            }
        } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
            [result addObject:responseObject];
        }

        if (completionHandler) {
            completionHandler(result, nil);
        }
    };

    void(^errorHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    };

    [self.sessionManager GET:path parameters:parameters success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        successHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (NSString *)pathBySubstitutingParametersInPath:(NSString *)path fromPersistentObject:(id<CBRPersistentObject>)persistentObject
{
    NSMutableArray *newComponents = [NSMutableArray array];
    NSArray *components = [path componentsSeparatedByString:@"/"];

    for (NSString *path in components) {
        if (![path hasPrefix:@":"]) {
            [newComponents addObject:path];
            continue;
        }

        NSString *keyPath = [path substringFromIndex:1];
        NSMutableArray *newKeyPathComponents = [NSMutableArray array];
        NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];

        id currentObject = persistentObject;
        for (NSString *thisComponent in keyPathComponents) {
            if ([currentObject conformsToProtocol:@protocol(CBRPersistentObject)]) {
                id<CBRPersistentObject> currentManagedObject = currentObject;
                CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:currentManagedObject.class];
                NSString *managedObjectKeyPath = [self.objectTransformer persistentObjectKeyPathFromCloudKeyPath:thisComponent ofEntity:entity];

                currentObject = [currentManagedObject valueForKey:managedObjectKeyPath];
                [newKeyPathComponents addObject:managedObjectKeyPath];
            } else {
                NSString *managedObjectKeyPath = [self.objectTransformer.propertyMapping persistentObjectPropertyFromCloudKeyPath:thisComponent];

                currentObject = [currentObject valueForKey:managedObjectKeyPath];
                [newKeyPathComponents addObject:managedObjectKeyPath];
            }
        }

        NSString *managedObjectKeyPath = [newKeyPathComponents componentsJoinedByString:@"."];
        id value = [persistentObject valueForKeyPath:managedObjectKeyPath];
        NSString *restValue = [NSString stringWithFormat:@"%@", value];

        if ([value isKindOfClass:[NSDate class]]) {
            restValue = [self.objectTransformer.dateFormatter stringFromDate:value];
        }

        [newComponents addObject:[restValue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    }
    
    return [newComponents componentsJoinedByString:@"/"];
}

#pragma mark - CBRBackend

- (void)fetchCloudObjectsForEntity:(CBREntityDescription *)entity
                     withPredicate:(NSPredicate *)predicate
                          userInfo:(NSDictionary *)userInfo
                 completionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    _CBRRESTConnectionFetchQuery *query = [self _parsePredicate:predicate ofEntity:entity];

    if (userInfo[CBRRESTConnectionUserInfoURLOverrideKey]) {
        query.path = userInfo[CBRRESTConnectionUserInfoURLOverrideKey];
    }

    [self fetchCloudObjectsFromPath:query.path parameters:query.parameters withCompletionHandler:completionHandler];
}

- (void)createCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(id<CBRCloudObject>, NSError *))completionHandler
{
    NSString *path = [self _CRUDPathForPersistentObject:persistentObject userInfo:userInfo appendIdentifier:NO];

    void(^successHandler)(id responseObject) = ^(id responseObject) {
        if (completionHandler) {
            completionHandler(responseObject, nil);
        }
    };

    void(^errorHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    };

    [self.sessionManager POST:path parameters:cloudObject success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        successHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)latestCloudObjectForPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(id<CBRCloudObject>, NSError *))completionHandler
{
    NSString *path = [self _CRUDPathForPersistentObject:persistentObject userInfo:userInfo appendIdentifier:YES];

    void(^successHandler)(id responseObject) = ^(id responseObject) {
        if (completionHandler) {
            completionHandler(responseObject, nil);
        }
    };

    void(^errorHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    };

    [self.sessionManager GET:path parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        successHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)saveCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(id<CBRCloudObject>, NSError *))completionHandler
{
    NSString *path = [self _CRUDPathForPersistentObject:persistentObject userInfo:userInfo appendIdentifier:YES];

    void(^successHandler)(id responseObject) = ^(id responseObject) {
        if (completionHandler) {
            completionHandler(responseObject, nil);
        }
    };

    void(^errorHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(nil, error);
        }
    };

    [self.sessionManager PUT:path parameters:cloudObject success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        successHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

- (void)deleteCloudObject:(id<CBRCloudObject>)cloudObject forPersistentObject:(id<CBRPersistentObject>)persistentObject withUserInfo:(NSDictionary *)userInfo completionHandler:(void (^)(NSError *))completionHandler
{
    NSString *path = [self _CRUDPathForPersistentObject:persistentObject userInfo:userInfo appendIdentifier:YES];

    void(^successHandler)(id responseObject) = ^(id responseObject) {
        if (completionHandler) {
            completionHandler(nil);
        }
    };

    void(^errorHandler)(NSError *error) = ^(NSError *error) {
        if (completionHandler) {
            completionHandler(error);
        }
    };

    [self.sessionManager DELETE:path parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        successHandler(responseObject);
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        errorHandler(error);
    }];
}

#pragma mark - Private category implementation ()

- (NSString *)_CRUDPathForPersistentObject:(id<CBRPersistentObject>)persistentObject userInfo:(NSDictionary *)userInfo appendIdentifier:(BOOL)appendIdentifier
{
    NSString *path = userInfo[CBRRESTConnectionUserInfoURLOverrideKey];

    if (!path) {
        CBREntityDescription *entity = [persistentObject.cloudBridge.databaseAdapter entityDescriptionForClass:persistentObject.class];
        NSParameterAssert(entity.restBaseURL);
        path = entity.restBaseURL;

        if (appendIdentifier) {
            CBRAttributeDescription *identifier = entity.attributesByName[entity.restIdentifier];
            path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@":%@", [self.objectTransformer cloudKeyPathFromPropertyDescription:identifier]]];
        }
    }

    return [self pathBySubstitutingParametersInPath:path fromPersistentObject:persistentObject];
}

- (_CBRRESTConnectionFetchQuery *)_parsePredicate:(NSPredicate *)predicate ofEntity:(CBREntityDescription *)entityDescription
{
    NSParameterAssert(entityDescription);

    __block BOOL hasFoundRelationship = NO;
   __block  NSString *path = entityDescription.restBaseURL;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (!predicate || [predicate isEqual:[NSPredicate predicateWithValue:YES]]) {
        _CBRRESTConnectionFetchQuery *query = [[_CBRRESTConnectionFetchQuery alloc] init];
        query.path = path;
        query.parameters = nil;

        return query;
    }

    void(^parseComparisonPredicate)(NSComparisonPredicate *comparisonPredicate) = ^(NSComparisonPredicate *comparisonPredicate) {
        NSParameterAssert(comparisonPredicate.predicateOperatorType == NSEqualToPredicateOperatorType);
        NSParameterAssert(comparisonPredicate.leftExpression.keyPath);
        NSParameterAssert(comparisonPredicate.rightExpression.constantValue);

        if ([comparisonPredicate.rightExpression.constantValue conformsToProtocol:@protocol(CBRPersistentObject)]) {
            NSAssert(hasFoundRelationship == NO, @"only one relationship is supported.");
            hasFoundRelationship = YES;

            CBRRelationshipDescription *relationshipDescription = entityDescription.relationshipsByName[comparisonPredicate.leftExpression.keyPath];
            NSParameterAssert(relationshipDescription);

            NSString *baseURL = relationshipDescription.restBaseURL;
            NSAssert1(baseURL != nil, @"restBaseURL not found for relationship %@", relationshipDescription);

            baseURL = [self pathBySubstitutingParametersInPath:baseURL fromPersistentObject:comparisonPredicate.rightExpression.constantValue];
            path = baseURL;
        } else if ([comparisonPredicate.leftExpression.keyPath isEqualToString:@"__PATH__"]) {
            NSAssert(NO, @"__PATH__ is not supported anymore");
        } else {
            CBRAttributeDescription *attributeDescription = entityDescription.attributesByName[comparisonPredicate.leftExpression.keyPath];
            NSString *parameterKeyPath = attributeDescription ? [self.objectTransformer cloudKeyPathFromPropertyDescription:attributeDescription] : comparisonPredicate.leftExpression.keyPath;

            if ([comparisonPredicate.rightExpression.constantValue isKindOfClass:[NSDate class]]) {
                parameters[parameterKeyPath] = [self.objectTransformer.dateFormatter stringFromDate:comparisonPredicate.rightExpression.constantValue];
            } else {
                parameters[parameterKeyPath] = comparisonPredicate.rightExpression.constantValue;
            }
        }
    };

    if ([predicate isKindOfClass:[NSComparisonPredicate class]]) {
        NSComparisonPredicate *comparisonPredicate = (NSComparisonPredicate *)predicate;
        parseComparisonPredicate(comparisonPredicate);
    } else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
        NSCompoundPredicate *compoundPredicate = (NSCompoundPredicate *)predicate;

        for (NSComparisonPredicate *comparisonPredicate in compoundPredicate.subpredicates) {
            NSParameterAssert([comparisonPredicate isKindOfClass:[NSComparisonPredicate class]]);
            parseComparisonPredicate(comparisonPredicate);
        }
    }

    _CBRRESTConnectionFetchQuery *query = [[_CBRRESTConnectionFetchQuery alloc] init];
    query.path = path;
    query.parameters = parameters;

    return query;
}

@end
