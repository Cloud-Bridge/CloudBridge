//
//  OfflineEntity.h
//  CloudBridge
//
//  Created by Oliver Letterer on 21.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <CloudBridge/CloudBridge.h>
#import <CloudBridge/CBRCoreDataInterface.h>



@interface OfflineEntity : NSManagedObject <CBROfflineCapablePersistentObject>

@property (nonatomic, retain) NSNumber *identifier;
@property (nonatomic, strong) NSNumber *hasPendingCloudBridgeChanges;
@property (nonatomic, strong) NSNumber *hasPendingCloudBridgeDeletion;

@end
