//
//  CBREntityDescription.m
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "CBREntityDescription.h"
#import "CBRDatabaseAdapter.h"

@implementation CBRAttributeDescription

- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter
{
    if (self = [super init]) {
        _databaseAdapter = databaseAdapter;
    }
    return self;
}

@end



@implementation CBRRelationshipDescription

- (CBREntityDescription *)destinationEntity
{
    return [self.databaseAdapter entityDescriptionForClass:NSClassFromString(self.destinationEntityName)];
}

- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter
{
    if (self = [super init]) {
        _databaseAdapter = databaseAdapter;
    }
    return self;
}

@end



@implementation CBREntityDescription

- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter
{
    if (self = [super init]) {
        _databaseAdapter = databaseAdapter;
    }
    return self;
}

@end
