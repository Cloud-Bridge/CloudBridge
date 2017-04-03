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

#import "CBRJSONDictionaryTransformer.h"

#import <CBRAttributeDescription+CBRRESTConnection.h>
#import <CBREntityDescription+CBRRESTConnection.h>
#import <CBRRelationshipDescription+CBRRESTConnection.h>



@implementation CBRJSONDictionaryTransformer

#pragma mark - Initialization

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithPropertyMapping:(id<CBRPropertyMapping>)propertyMapping
{
    if (self = [super init]) {
        _propertyMapping = propertyMapping;

        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        _dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    return self;
}

#pragma mark - Instance methods

- (NSString *)primaryKeyOfEntitiyDescription:(CBREntityDescription *)entityDescription
{
    return entityDescription.restIdentifier;
}

- (id)cloudValueFromPersistentObjectValue:(id)managedObjectValue forAttributeDescription:(CBRAttributeDescription *)attributeDescription
{
    switch (attributeDescription.type) {
        case CBRAttributeTypeInteger:
        case CBRAttributeTypeDouble:
        case CBRAttributeTypeString:
            return managedObjectValue;
            break;
        case CBRAttributeTypeBoolean:
            return [managedObjectValue boolValue] ? @YES : @NO;
            break;
        case CBRAttributeTypeDate:
            return [self.dateFormatter stringFromDate:managedObjectValue];
            break;
        case CBRAttributeTypeTransformable: {
            NSValueTransformer *valueTransformer = attributeDescription.restValueTransformer;
            return valueTransformer ? [valueTransformer reverseTransformedValue:managedObjectValue] : managedObjectValue;
            break;
        }
        case CBRAttributeTypeBinary:
        case CBRAttributeTypeUnknown:
            return nil;
            break;
    }
}

- (id)persistentObjectValueFromCloudValue:(id)cloudValue forAttributeDescription:(CBRAttributeDescription *)attributeDescription
{
    if ([cloudValue isEqual:[NSNull null]]) {
        return nil;
    }

    switch (attributeDescription.type) {
        case CBRAttributeTypeInteger:
            return [cloudValue isKindOfClass:[NSNumber class]] ? cloudValue : nil;
            break;
        case CBRAttributeTypeDouble:
            return [cloudValue isKindOfClass:[NSNumber class]] ? cloudValue : nil;
            break;
        case CBRAttributeTypeString:
            return [cloudValue isKindOfClass:[NSString class]] ? cloudValue : nil;
            break;
        case CBRAttributeTypeBoolean:
            return [cloudValue isKindOfClass:[NSNumber class]] ? cloudValue : nil;
            break;
        case CBRAttributeTypeDate:
            return [cloudValue isKindOfClass:[NSString class]] ? [self.dateFormatter dateFromString:cloudValue] : nil;
            break;
        case CBRAttributeTypeTransformable: {
            NSValueTransformer *valueTransformer = attributeDescription.restValueTransformer;
            return valueTransformer ? [valueTransformer transformedValue:cloudValue] : cloudValue;
            break;
        }
        case CBRAttributeTypeBinary:
            return nil;
            break;
        case CBRAttributeTypeUnknown:
            return nil;
            break;
    }
}

- (NSString *)cloudKeyPathFromPropertyDescription:(id<CBRPropertyDescription>)propertyDescription
{
    return propertyDescription.userInfo[@"restKeyPath"] ?: [self.propertyMapping cloudKeyPathFromPersistentObjectProperty:propertyDescription.name];
}

- (NSString *)persistentObjectKeyPathFromCloudKeyPath:(NSString *)cloudKeyPath ofEntity:(CBREntityDescription *)entity
{
    for (CBRAttributeDescription *properyDescription in entity.attributes) {
        NSString *thisCloudKeyPath = [self cloudKeyPathFromPropertyDescription:properyDescription];
        if ([thisCloudKeyPath isEqual:cloudKeyPath]) {
            return properyDescription.name;
        }
    }

    for (CBRAttributeDescription *properyDescription in entity.relationships) {
        NSString *thisCloudKeyPath = [self cloudKeyPathFromPropertyDescription:properyDescription];
        if ([thisCloudKeyPath isEqual:cloudKeyPath]) {
            return properyDescription.name;
        }
    }

    return [self.propertyMapping persistentObjectPropertyFromCloudKeyPath:cloudKeyPath];
}

#pragma mark - CBRManagedObjectToCloudObjectTransformer

- (NSDictionary *)cloudObjectFromPersistentObject:(id<CBRPersistentObject>)persistentObject
{
    NSMutableDictionary *cloudObject = [NSMutableDictionary dictionary];
    [self updateCloudObject:cloudObject withPropertiesFromPersistentObject:persistentObject];

    CBREntityDescription *entity = persistentObject.cloudBridgeEntityDescription;
    if (entity.restPrefix) {
        return @{ entity.restPrefix: cloudObject };
    }

    return (NSDictionary *)[persistentObject finalizeCloudObject:cloudObject];
}

- (void)updateCloudObject:(NSMutableDictionary *)cloudObject withPropertiesFromPersistentObject:(id<CBRPersistentObject>)persistentObject
{
    if (![cloudObject isKindOfClass:[NSMutableDictionary class]]) {
        return;
    }

    CBREntityDescription *entity = persistentObject.cloudBridgeEntityDescription;
    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        if (attributeDescription.restDisabled) {
            continue;
        }

        id value = [persistentObject valueForKey:attributeDescription.name];
        if (!value) {
            continue;
        }

        NSString *JSONObjectKeyPath = [self cloudKeyPathFromPropertyDescription:attributeDescription];
        id JSONObjectValue = [self cloudValueFromPersistentObjectValue:value forAttributeDescription:attributeDescription];

        if (!JSONObjectValue) {
            continue;
        }

        __block NSMutableDictionary *currentDictionary = cloudObject;

        NSArray *JSONObjectKeyPaths = [JSONObjectKeyPath componentsSeparatedByString:@"."];
        NSUInteger count = JSONObjectKeyPaths.count;
        [JSONObjectKeyPaths enumerateObjectsUsingBlock:^(NSString *JSONObjectKey, NSUInteger idx, BOOL *stop) {
            if (idx == count - 1) {
                currentDictionary[JSONObjectKey] = JSONObjectValue;
            } else {
                NSMutableDictionary *dictionary = currentDictionary[JSONObjectKey];
                if (!dictionary) {
                    dictionary = [NSMutableDictionary dictionary];
                    currentDictionary[JSONObjectKey] = dictionary;
                }

                currentDictionary = dictionary;
            }
        }];
    }

    for (CBRRelationshipDescription *relationshipDescription in entity.relationships) {
        if (!relationshipDescription.restIncluded) {
            continue;
        }

        NSSet *entities = [persistentObject valueForKey:relationshipDescription.name];
        NSMutableArray *newArray = [NSMutableArray array];

        for (id<CBRPersistentObject> persistentObject in entities) {
            [newArray addObject:[self cloudObjectFromPersistentObject:persistentObject]];
        }

        cloudObject[[self cloudKeyPathFromPropertyDescription:relationshipDescription]] = newArray;
    }
}

- (id<CBRPersistentObject>)persistentObjectFromCloudObject:(NSDictionary *)cloudObject forEntity:(CBREntityDescription *)entity
{
    NSParameterAssert(entity);

    if (entity.restPrefix) {
        cloudObject = cloudObject[entity.restPrefix] ?: cloudObject;
    }

    cloudObject = (NSDictionary *)[NSClassFromString(entity.name) prepareForUpdateWithCloudObject:cloudObject];
    CBREntityDescription *stiEntity = [self _stiEntityForEntity:entity cloudObject:cloudObject];
    if (stiEntity != entity) {
        entity = stiEntity;
        cloudObject = (NSDictionary *)[NSClassFromString(entity.name) prepareForUpdateWithCloudObject:cloudObject];
    }

    NSString *managedObjectIdentifier = entity.restIdentifier;
    NSString *jsonIdentifier = [self cloudKeyPathFromPropertyDescription:entity.attributesByName[managedObjectIdentifier]];

    if (![cloudObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"WARNING: JSON Object is not a NSDictionary (%@)", cloudObject);
        return nil;
    }

    id identifier = cloudObject[jsonIdentifier];

    if (!identifier) {
        NSLog(@"WARNING: JSON Object did not have an id (%@)", cloudObject);
        return nil;
    }

    id<CBRPersistentObject> persistentObject = [[NSClassFromString(entity.name) cloudBridge].databaseAdapter persistentObjectOfType:entity withPrimaryKey:identifier];
    if (!persistentObject) {
        persistentObject = [[NSClassFromString(entity.name) cloudBridge].databaseAdapter newMutablePersistentObjectOfType:entity];
        [persistentObject awakeFromCloudFetch];
    }

    [self updatePersistentObject:persistentObject withPropertiesFromCloudObject:cloudObject];
    return persistentObject;
}

- (void)updatePersistentObject:(id<CBRPersistentObject>)persistentObject withPropertiesFromCloudObject:(NSDictionary *)cloudObject
{
    [persistentObject prepareForUpdateWithCloudObject:cloudObject];

    CBREntityDescription *entity = persistentObject.cloudBridgeEntityDescription;
    for (CBRAttributeDescription *attributeDescription in entity.attributes) {
        id jsonValue = [cloudObject valueForKeyPath:[self cloudKeyPathFromPropertyDescription:attributeDescription]];
        id newValue = [self persistentObjectValueFromCloudValue:jsonValue forAttributeDescription:attributeDescription];
        id oldValue = [persistentObject cloudValueForKey:attributeDescription.name];

        if (!jsonValue) {
            continue;
        }

        if ([jsonValue isKindOfClass:[NSNull class]]) {
            if (oldValue) {
                [persistentObject setCloudValue:nil forKey:attributeDescription.name fromCloudObject:cloudObject];
            }
            continue;
        }

        if (![newValue isEqual:oldValue] && newValue != oldValue) {
            [persistentObject setCloudValue:newValue forKey:attributeDescription.name fromCloudObject:cloudObject];
        }
    }

    for (CBRRelationshipDescription *relationshipDescription in entity.relationships) {
        CBREntityDescription *destinationEntity = relationshipDescription.destinationEntity;
        NSString *restKeyPath = [self cloudKeyPathFromPropertyDescription:relationshipDescription];

        if (!relationshipDescription.toMany) {
            // map destination_entity_id to destinationEntity
            NSString *restIdentifier = destinationEntity.restIdentifier;
            if (!restIdentifier) {
                continue;
            }

            NSString *firstLetterUppercaseString = [restIdentifier stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[restIdentifier substringToIndex:1].uppercaseString];
            restIdentifier = [self.propertyMapping cloudKeyPathFromPersistentObjectProperty:[relationshipDescription.name stringByAppendingString:firstLetterUppercaseString]];

            id jsonIdentifier = cloudObject[restIdentifier];
            id identifier = [self persistentObjectValueFromCloudValue:jsonIdentifier forAttributeDescription:destinationEntity.attributesByName[destinationEntity.restIdentifier]];

            if (identifier) {
                id<CBRPersistentObject> newPersistentObject = [[NSClassFromString(destinationEntity.name) cloudBridge].databaseAdapter persistentObjectOfType:destinationEntity withPrimaryKey:identifier];
                if (newPersistentObject) {
                    [persistentObject setValue:newPersistentObject forKey:relationshipDescription.name];
                }
            }
        }

        id relationshipObject = cloudObject[restKeyPath];

        if ([relationshipObject isKindOfClass:[NSNull class]]) {
            [persistentObject setValue:nil forKey:relationshipDescription.name];
            continue;
        }

        if (relationshipDescription.toMany) {
            if (![relationshipObject isKindOfClass:[NSArray class]]) {
                continue;
            }

            NSArray *cloudObjects = relationshipObject;
            NSString *primaryKey = relationshipDescription.destinationEntity.restIdentifier;
            NSString *dictionaryPrimaryKey = [self cloudKeyPathFromPropertyDescription:relationshipDescription.destinationEntity.attributesByName[primaryKey]];

            NSMutableSet *uniqueIdentifiers = [NSMutableSet set];
            for (NSDictionary *dictionary in cloudObjects) {
                if (![dictionary isKindOfClass:[NSDictionary class]]) {
                    continue;
                }

                if (dictionary[dictionaryPrimaryKey]) {
                    [uniqueIdentifiers addObject:dictionary[dictionaryPrimaryKey]];
                }
            }

            NSDictionary *existingObjectsByPrimaryKey = [[NSClassFromString(destinationEntity.name) cloudBridge].databaseAdapter indexedObjectsOfType:destinationEntity withValues:uniqueIdentifiers forAttribute:primaryKey];

            NSMutableSet *newEntities = [NSMutableSet set];
            for (NSDictionary *dictionary in cloudObjects) {
                if (![dictionary isKindOfClass:[NSDictionary class]]) {
                    continue;
                }

                CBREntityDescription *realDestinationEntity = [self _stiEntityForEntity:destinationEntity cloudObject:dictionary];

                id<CBRPersistentObject> newPersistentObject = existingObjectsByPrimaryKey[dictionary[dictionaryPrimaryKey]];
                if (!newPersistentObject) {
                    newPersistentObject = [[NSClassFromString(destinationEntity.name) cloudBridge].databaseAdapter newMutablePersistentObjectOfType:realDestinationEntity];
                    [newPersistentObject awakeFromCloudFetch];
                }

                [self updatePersistentObject:newPersistentObject withPropertiesFromCloudObject:dictionary];
                [newEntities addObject:newPersistentObject];
            }

            [persistentObject setValue:newEntities forKey:relationshipDescription.name];
        } else {
            if (![relationshipObject isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            id<CBRPersistentObject> newPersistentObject = [self persistentObjectFromCloudObject:relationshipObject forEntity:destinationEntity];
            if (newPersistentObject) {
                [persistentObject setValue:newPersistentObject forKey:relationshipDescription.name];
            }
        }
    }

    [persistentObject finalizeUpdateWithCloudObject:cloudObject];
}

#pragma mark - Private category implementation ()

- (CBREntityDescription *)_stiEntityForEntity:(CBREntityDescription *)entity cloudObject:(NSDictionary *)cloudObject
{
    if (entity.stiKeyPath) {
        NSString *restKeyPath = [self.propertyMapping cloudKeyPathFromPersistentObjectProperty:entity.stiKeyPath];
        NSString *stringToMatch = [NSString stringWithFormat:@"%@", [cloudObject valueForKeyPath:restKeyPath]];

        for (CBREntityDescription *subentity in entity.stiSubentities) {
            if ([stringToMatch isEqualToString:subentity.stiValue]) {
                return [self _stiEntityForEntity:subentity cloudObject:cloudObject];
            }
        }
    }

    return entity;
}

@end
