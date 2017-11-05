//
//  CBREntityDescription+Realm.m
//  Pods
//
//  Created by Oliver Letterer on 27.03.17.
//
//

#import "CBREntityDescription+Realm.h"
#import "CBRRealmInterface.h"
#import "CBRRealmObject.h"



@implementation CBRRelationshipDescription (Realm)

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface schema:(RLMObjectSchema *)schema property:(RLMProperty *)property
{
    if (self = [self initWithInterface:interface]) {
        self.entityName = schema.className;

        self.name = property.name;
        self.toMany = property.type == RLMPropertyTypeLinkingObjects;
        self.destinationEntityName = property.objectClassName;
        self.userInfo = [NSClassFromString(schema.className) propertyUserInfo][property.name] ?: @{};
        self.cascades = self.userInfo[@"cloudBridgeCascades"] != nil;
    }
    return self;
}

@end



@implementation CBRAttributeDescription (Realm)

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface schema:(RLMObjectSchema *)schema property:(RLMProperty *)property
{
    NSArray<NSString *> *transformableProperties = [NSClassFromString(schema.className) transformableProperties];

    if (self = [self initWithInterface:interface]) {
        self.name = property.name;

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
                if ([property.name hasSuffix:@"_Data"] && [transformableProperties containsObject:[property.name stringByReplacingOccurrencesOfString:@"_Data" withString:@""]]) {
                    self.name = [property.name stringByReplacingOccurrencesOfString:@"_Data" withString:@""];
                    self.type = CBRAttributeTypeTransformable;
                } else {
                    self.type = CBRAttributeTypeBinary;
                }
                break;
            default:
                self.type = CBRAttributeTypeUnknown;
                break;
        }

        self.userInfo = [NSClassFromString(schema.className) propertyUserInfo][self.name];
    }
    return self;
}

@end



@implementation CBREntityDescription (Realm)

+ (void)load
{
    NSAssert([RLMObjectSchema instancesRespondToSelector:NSSelectorFromString(@"computedProperties")], @"RLMObjectSchema is expected to return computedProperties");
}

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface realmObjectSchema:(RLMObjectSchema *)schema
{
    assert(schema);

    if (self = [self initWithInterface:interface]) {
        self.name = schema.className;
        self.userInfo = [NSClassFromString(schema.className) userInfo];
        self.subentityNames = @[];

        NSMutableArray<CBRAttributeDescription *> *attributes = [NSMutableArray array];
        NSMutableArray<CBRRelationshipDescription *> *relationships = [NSMutableArray array];

        for (RLMProperty *property in [schema.properties arrayByAddingObjectsFromArray:[schema valueForKey:@"computedProperties"]]) {
            switch (property.type) {
                case RLMPropertyTypeObject:
                case RLMPropertyTypeLinkingObjects:
                    [relationships addObject:[[CBRRelationshipDescription alloc] initWithInterface:interface schema:schema property:property]];
                    break;
                    
                default:
                    [attributes addObject:[[CBRAttributeDescription alloc] initWithInterface:interface schema:schema property:property]];
                    break;
            }
        }

        self.attributes = attributes.copy;
        self.relationships = relationships.copy;
    }

    return self;
}

@end
