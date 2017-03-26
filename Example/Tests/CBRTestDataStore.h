//
//  CBRTestDataStore.h
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import <CloudBridge/CBRCoreDataStack.h>

#import "OfflineEntity.h"
#import "OnlyOnlineEntity.h"

#import "JSONEntity1.h"
#import "SLEntity1.h"
#import "SLEntity2.h"
#import "SLEntity3.h"
#import "SLEntity4.h"
#import "SLEntity4Subclass.h"
#import "SLEntity5.h"
#import "SLEntity5Child1.h"
#import "SLEntity5Child2.h"
#import "SLEntity5Child3.h"
#import "SLEntity5Child4.h"
#import "SLEntity5Child5.h"
#import "SLEntity5Child6.h"
#import "SLEntity5Subclass.h"
#import "SLEntity6.h"
#import "SLEntity6Child.h"
#import "PrefixedEntitiy.h"


@interface CBRTestDataStore : CBRCoreDataStack

+ (CBRTestDataStore *)testStore;

- (void)wipeAllData;

@end
