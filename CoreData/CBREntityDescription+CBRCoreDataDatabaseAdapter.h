//
//  CBREntityDescription+CBRCoreDataDatabaseAdapter.h
//  Pods
//
//  Created by Oliver Letterer.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CloudBridge/CBREntityDescription.h>



NS_ASSUME_NONNULL_BEGIN

@interface CBREntityDescription (CBRCoreDataDatabaseAdapter)

- (instancetype)initWithDatabaseAdapter:(id<CBRDatabaseAdapter>)databaseAdapter coreDataEntityDescription:(NSEntityDescription *)entityDescription;

@end

NS_ASSUME_NONNULL_END
