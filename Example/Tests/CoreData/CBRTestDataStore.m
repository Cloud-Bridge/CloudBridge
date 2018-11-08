//
//  CBRTestDataStore.m
//  CloudBridge
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright 2014 Oliver Letterer. All rights reserved.
//

#import "CBRTestDataStore.h"

@implementation CBRCoreDataStack (CBRTestDataStore)

- (NSString *)humanReadableInterfaceName
{
    return NSLocalizedString(@"Database", @"");
}

- (NSString *)managedObjectModelName
{
    return @"CBRTestDataStore";
}

- (void)wipeAllData
{
    NSManagedObjectModel *model = self.managedObjectModel;

    for (NSEntityDescription *entity in model.entities) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entity.name];

        NSError *error = nil;
        NSArray *objects = [self.mainThreadManagedObjectContext executeFetchRequest:request error:&error];
        NSAssert(error == nil, @"");

        for (NSManagedObject *object in objects) {
            [self.mainThreadManagedObjectContext deleteObject:object];
        }
    }

    NSError *saveError = nil;
    [self.mainThreadManagedObjectContext save:&saveError];
    NSAssert(saveError == nil, @"error saving NSManagedObjectContext: %@", saveError);
}

+ (CBRCoreDataStack *)testStore
{
    static CBRCoreDataStack *testStore = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        testStore = [self buildConvenientSQLiteStackWithModel:@"CBRTestDataStore" inBundle:[NSBundle bundleForClass:[SLEntity6 class]]];
    });

    return testStore;
}

@end
