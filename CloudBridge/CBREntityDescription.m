//
//  CBREntityDescription.m
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "CBREntityDescription.h"
#import "CBRDatabaseAdapter.h"

static NSDictionary *indexBy(NSArray *array, NSString *key)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    for (id object in array) {
        result[[object valueForKey:key]] = object;
    }

    return result;
}



@implementation CBRAttributeDescription

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface
{
    if (self = [super init]) {
        _interface = interface;
    }
    return self;
}

@end



@implementation CBRRelationshipDescription

- (CBREntityDescription *)entity
{
    return self.interface.entitiesByName[self.entityName];
}

- (CBRRelationshipDescription *)inverseRelationship
{
    return [self.interface inverseRelationshipForEntity:self.entity relationship:self];
}

- (CBREntityDescription *)destinationEntity
{
    return self.interface.entitiesByName[self.destinationEntityName];
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface
{
    if (self = [super init]) {
        _interface = interface;
    }
    return self;
}

@end



@implementation CBREntityDescription

- (NSDictionary *)attributesByName
{
    return indexBy(self.attributes, @"name");
}

- (NSDictionary *)relationshipsByName
{
    return indexBy(self.relationships, @"name");
}

- (NSArray *)subentities
{
    NSMutableArray *result = [NSMutableArray array];

    for (NSString *name in self.subentityNames) {
        [result addObject:self.interface.entitiesByName[name]];
    }

    return result;
}

- (instancetype)init
{
    return [super init];
}

- (instancetype)initWithInterface:(id<CBRPersistentStoreInterface>)interface
{
    if (self = [super init]) {
        _interface = interface;
    }
    return self;
}

@end
