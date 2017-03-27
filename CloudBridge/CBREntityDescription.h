//
//  CBREntityDescription.h
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
@class CBREntityDescription;

typedef NS_ENUM(NSInteger, CBRAttributeType) {
    CBRAttributeTypeInteger,
    CBRAttributeTypeDouble,
    CBRAttributeTypeBoolean,
    CBRAttributeTypeString,
    CBRAttributeTypeDate,
    CBRAttributeTypeBinary,
    CBRAttributeTypeTransformable,

    CBRAttributeTypeUnknown,
};

@protocol CBRPropertyDescription <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDictionary *userInfo;
@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;

@end



@interface CBRAttributeDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) CBRAttributeType type;

@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end



@interface CBRRelationshipDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, readonly) CBREntityDescription *entity;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL toMany;
@property (nonatomic, assign) BOOL cascades;

@property (nonatomic, strong) NSString *destinationEntityName;
@property (nonatomic, readonly) CBREntityDescription *destinationEntity;

@property (nonatomic, readonly) CBRRelationshipDescription *inverseRelationship;

@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end



@interface CBREntityDescription : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDictionary *userInfo;

@property (nonatomic, strong) NSArray<CBRAttributeDescription *> *attributes;
@property (nonatomic, strong) NSArray<CBRRelationshipDescription *> *relationships;
@property (nonatomic, strong) NSArray<NSString *> *subentityNames;

@property (nonatomic, readonly) NSDictionary<NSString *, CBRAttributeDescription *> *attributesByName;
@property (nonatomic, readonly) NSDictionary<NSString *, CBRRelationshipDescription *> *relationshipsByName;
@property (nonatomic, readonly) NSArray<CBRRelationshipDescription *> *subentities;

@property (nonatomic, weak, readonly) id<CBRDatabaseAdapter> databaseAdapter;
- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter NS_DESIGNATED_INITIALIZER;

@end
