//
//  CBREntityDescription+Realm.m
//  Pods
//
//  Created by Oliver Letterer on 27.03.17.
//
//

#import "CBREntityDescription+Realm.h"
#import "CBRRealmDatabaseAdapter.h"
#import "CBRRealmObject.h"



@implementation CBRRelationshipDescription (Realm)

- (instancetype)initWithDatabaseAdapter:(CBRRealmDatabaseAdapter *)databaseAdapter schema:(RLMObjectSchema *)schema property:(RLMProperty *)property
{
    if (self = [self initWithDatabaseAdapter:databaseAdapter]) {
        self.entityName = schema.className;

        self.name = property.name;
        self.toMany = property.type == RLMPropertyTypeArray;
        self.destinationEntityName = property.objectClassName;
        self.userInfo = [NSClassFromString(schema.className) propertyUserInfo][property.name] ?: @{};
        self.cascades = self.userInfo[@"cloudBridgeCascades"] != nil;
    }
    return self;
}

@end



@implementation CBRAttributeDescription (Realm)

- (instancetype)initWithDatabaseAdapter:(CBRRealmDatabaseAdapter *)databaseAdapter schema:(RLMObjectSchema *)schema property:(RLMProperty *)property
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[NSClassFromString(schema.className) propertyUserInfo][property.name]];

    if (self = [self initWithDatabaseAdapter:databaseAdapter]) {
        self.name = property.name;
        self.userInfo = userInfo;

        switch (property.type) {
            case RLMPropertyTypeInt:
                self.type = CBRAttributeTypeInteger;
                break;
            case RLMPropertyTypeFloat:
            case RLMPropertyTypeDouble:
                self.type = CBRAttributeTypeDouble;
                break;
            case RLMPropertyTypeBool:
                self.type = CBRAttributeTypeBoolean;
                break;
            case RLMPropertyTypeString:
                self.type = CBRAttributeTypeString;
                break;
            case RLMPropertyTypeDate:
                self.type = CBRAttributeTypeDate;
                break;
            case RLMPropertyTypeAny:
                self.type = CBRAttributeTypeTransformable;
                break;
            case RLMPropertyTypeData:
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



@implementation CBREntityDescription (Realm)

+ (void)load
{
    NSAssert([RLMObjectSchema instancesRespondToSelector:NSSelectorFromString(@"computedProperties")], @"RLMObjectSchema is expected to return computedProperties");
}

- (instancetype)initWithDatabaseAdapter:(CBRRealmDatabaseAdapter *)databaseAdapter realmObjectSchema:(RLMObjectSchema *)schema
{
    if (self = [self initWithDatabaseAdapter:databaseAdapter]) {
        self.name = schema.className;
        self.userInfo = [NSClassFromString(schema.className) userInfo];
        self.subentityNames = @[];

        NSMutableArray<CBRAttributeDescription *> *attributes = [NSMutableArray array];
        NSMutableArray<CBRRelationshipDescription *> *relationships = [NSMutableArray array];

        for (RLMProperty *property in [schema.properties arrayByAddingObjectsFromArray:[schema valueForKey:@"computedProperties"]]) {
            switch (property.type) {
                case RLMPropertyTypeObject:
                case RLMPropertyTypeArray:
                case RLMPropertyTypeLinkingObjects:
                    [relationships addObject:[[CBRRelationshipDescription alloc] initWithDatabaseAdapter:databaseAdapter schema:schema property:property]];
                    break;
                    
                default:
                    [attributes addObject:[[CBRAttributeDescription alloc] initWithDatabaseAdapter:databaseAdapter schema:schema property:property]];
                    break;
            }
        }

        self.attributes = attributes.copy;
        self.relationships = relationships.copy;
    }
    return self;
}

@end
