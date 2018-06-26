//
//  CBREntityDescription.h
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, nullable, readonly) NSDictionary *userInfo;
@property (nonatomic, weak, readonly) id<CBRPersistentStoreInterface> interface;

@end



__attribute__((objc_subclassing_restricted))
@interface CBRAttributeDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) CBRAttributeType type;

@property (nonatomic, nullable) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRPersistentStoreInterface> interface;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface NS_DESIGNATED_INITIALIZER;

@end



__attribute__((objc_subclassing_restricted))
@interface CBRRelationshipDescription : NSObject <CBRPropertyDescription>

@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, readonly) CBREntityDescription *entity;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL toMany;
@property (nonatomic, assign) BOOL cascades;

@property (nonatomic, nullable) NSString *destinationEntityName;
@property (nonatomic, nullable, readonly) CBREntityDescription *destinationEntity;

@property (nonatomic, nullable, readonly) CBRRelationshipDescription *inverseRelationship;

@property (nonatomic, nullable) NSDictionary *userInfo;

@property (nonatomic, weak, readonly) id<CBRPersistentStoreInterface> interface;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface NS_DESIGNATED_INITIALIZER;

@end



__attribute__((objc_subclassing_restricted))
@interface CBREntityDescription : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, nullable) NSDictionary *userInfo;

@property (nonatomic, strong) NSArray<CBRAttributeDescription *> *attributes;
@property (nonatomic, strong) NSArray<CBRRelationshipDescription *> *relationships;
@property (nonatomic, strong) NSArray<NSString *> *subentityNames;

@property (nonatomic, readonly) NSDictionary<NSString *, CBRAttributeDescription *> *attributesByName;
@property (nonatomic, readonly) NSDictionary<NSString *, CBRRelationshipDescription *> *relationshipsByName;
@property (nonatomic, readonly) NSArray<CBRRelationshipDescription *> *subentities;

@property (nonatomic, weak, readonly) id<CBRPersistentStoreInterface> interface;

- (instancetype)init NS_DESIGNATED_INITIALIZER UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
