//
//  CBREntityDescription.h
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CBREntityDescription;
@protocol CBRDatabaseAdapter;

typedef NS_ENUM(NSInteger, CBRAttributeType) {
    CBRAttributeTypeNumber,
    CBRAttributeTypeBoolean,
    CBRAttributeTypeString,
    CBRAttributeTypeDate,
    CBRAttributeTypeTransformable,

    CBRAttributeTypeUnknown,
};

@protocol CBRPropertyDescription <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;

@end



@interface CBRAttributeDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) CBRAttributeType type;

@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end



@interface CBRRelationshipDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL toMany;

@property (nonatomic, strong) NSString *destinationEntityName;
@property (nonatomic, readonly) CBREntityDescription *destinationEntity;

@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end



@interface CBREntityDescription : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, strong) NSArray *attributes;
@property (nonatomic, strong) NSArray *relationships;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end
