//
//  OfflineEntity.m
//  CloudBridge
//
//  Created by Oliver Letterer on 21.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import "OfflineEntity.h"


@implementation OfflineEntity
@dynamic identifier, hasPendingCloudBridgeChanges, hasPendingCloudBridgeDeletion;
@dynamic cloudObjectRepresentation, cloudBridge, cloudBridgeEntityDescription, databaseAdapter;

+ (CBRDatabaseAdapter *)databaseAdapter
{
    return [super databaseAdapter];
}

+ (CBREntityDescription *)cloudBridgeEntityDescription
{
    return [super cloudBridgeEntityDescription];
}

+ (CBRCloudBridge *)cloudBridge
{
    return [super cloudBridge];
}

+ (void)setCloudBridge:(CBRCloudBridge *)cloudBridge
{
    [super setCloudBridge:cloudBridge];
}

@end
