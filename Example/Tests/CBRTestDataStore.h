//
//  CBRTestDataStore.h
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <SLCoreDataStack/SLCoreDataStack.h>

#import "SLEntity4.h"
#import "SLEntity6.h"
#import "SLEntity6Child.h"

#import "OfflineEntity.h"
#import "OnlyOnlineEntity.h"


@interface CBRTestDataStore : SLCoreDataStack

- (void)wipeAllData;

@end
