//
//  SLEntity6.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SLEntity6Child;

@interface SLEntity6 : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *children;
@end

@interface SLEntity6 (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(SLEntity6Child *)value;
- (void)removeChildrenObject:(SLEntity6Child *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

@end
