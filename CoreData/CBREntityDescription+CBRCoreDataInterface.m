//
//  CBREntityDescription+CBRCoreDataInterface.m
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import "CBREntityDescription+CBRCoreDataInterface.h"

@implementation CBRAttributeDescription (CBRCoreDataInterface)

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface coreDataAttributeDescription:(NSAttributeDescription *)attributeDescription
{
    if (self = [self initWithInterface:interface]) {
        self.name = attributeDescription.name;
        self.userInfo = attributeDescription.userInfo;

        switch (attributeDescription.attributeType) {
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
                self.type = CBRAttributeTypeInteger;
                break;
            case NSDecimalAttributeType:
            case NSDoubleAttributeType:
            case NSFloatAttributeType:
                self.type = CBRAttributeTypeDouble;
                break;
            case NSBooleanAttributeType:
                self.type = CBRAttributeTypeBoolean;
                break;
            case NSStringAttributeType:
                self.type = CBRAttributeTypeString;
                break;
            case NSDateAttributeType:
                self.type = CBRAttributeTypeDate;
                break;
            case NSTransformableAttributeType:
                self.type = CBRAttributeTypeTransformable;
                break;
            case NSBinaryDataAttributeType:
                self.type = CBRAttributeTypeBinary;
                break;
            default:
                self.type = CBRAttributeTypeUnknown;
                break;
        }
    }
    return self;
}

@end



@implementation CBRRelationshipDescription (CBRCoreDataInterface)

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface coreDataRelationshipDescription:(NSRelationshipDescription *)relationshipDescription
{
    NSAssert(relationshipDescription.inverseRelationship != nil, @"No inverseRelationship found for %@", relationshipDescription);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:relationshipDescription.userInfo];

    if (!userInfo[@"restBaseURL"] && relationshipDescription.inverseRelationship.userInfo[@"restBaseURL"]) {
        userInfo[@"restBaseURL"] = relationshipDescription.inverseRelationship.userInfo[@"restBaseURL"];
    }

    if (self = [self initWithInterface:interface]) {
        self.entityName = relationshipDescription.entity.name;
        
        self.name = relationshipDescription.name;
        self.toMany = relationshipDescription.isToMany;
        self.destinationEntityName = relationshipDescription.destinationEntity.name;
        self.userInfo = userInfo.copy;
        self.cascades = relationshipDescription.userInfo[@"cloudBridgeCascades"] != nil || relationshipDescription.inverseRelationship.userInfo[@"cloudBridgeCascades"] != nil;
    }
    return self;
}

@end



@implementation CBREntityDescription (CBRCoreDataInterface)

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface coreDataEntityDescription:(NSEntityDescription *)entityDescription
{
    if (self = [self initWithInterface:interface]) {
        self.name = entityDescription.name;
        self.userInfo = entityDescription.userInfo;
        self.subentityNames = entityDescription.subentitiesByName.allKeys;

        NSMutableArray *attributes = [NSMutableArray array];
        for (NSAttributeDescription *attributeDescription in entityDescription.attributesByName.allValues) {
            [attributes addObject:[[CBRAttributeDescription alloc] initWithInterface:interface coreDataAttributeDescription:attributeDescription] ];
        }
        self.attributes = attributes.copy;

        NSMutableArray *relationships = [NSMutableArray array];
        for (NSRelationshipDescription *relationshipDescription in entityDescription.relationshipsByName.allValues) {
            [relationships addObject:[[CBRRelationshipDescription alloc] initWithInterface:interface coreDataRelationshipDescription:relationshipDescription] ];
        }
        self.relationships = relationships.copy;
    }
    return self;
}

@end
