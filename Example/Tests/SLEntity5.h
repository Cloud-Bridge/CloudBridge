//
//  SLEntity5.h
//  CBRRESTConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SLEntity5Child1, SLEntity5Child2, SLEntity5Child3, SLEntity5Child4, SLEntity5Child5, SLEntity5Child6;

@interface SLEntity5 : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) id dictionary;
@property (nonatomic, retain) NSNumber * floatNumber;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * otherString;
@property (nonatomic, retain) NSString * string;
@property (nonatomic, retain) NSSet *camelizedChilds;
@property (nonatomic, retain) SLEntity5Child1 *child;
@property (nonatomic, retain) NSSet *differentChilds;
@property (nonatomic, retain) SLEntity5Child2 *otherChild;
@property (nonatomic, retain) NSSet *otherToManyChilds;
@property (nonatomic, retain) NSSet *toManyChilds;
@end

@interface SLEntity5 (CoreDataGeneratedAccessors)

- (void)addCamelizedChildsObject:(SLEntity5Child5 *)value;
- (void)removeCamelizedChildsObject:(SLEntity5Child5 *)value;
- (void)addCamelizedChilds:(NSSet *)values;
- (void)removeCamelizedChilds:(NSSet *)values;

- (void)addDifferentChildsObject:(SLEntity5Child6 *)value;
- (void)removeDifferentChildsObject:(SLEntity5Child6 *)value;
- (void)addDifferentChilds:(NSSet *)values;
- (void)removeDifferentChilds:(NSSet *)values;

- (void)addOtherToManyChildsObject:(SLEntity5Child4 *)value;
- (void)removeOtherToManyChildsObject:(SLEntity5Child4 *)value;
- (void)addOtherToManyChilds:(NSSet *)values;
- (void)removeOtherToManyChilds:(NSSet *)values;

- (void)addToManyChildsObject:(SLEntity5Child3 *)value;
- (void)removeToManyChildsObject:(SLEntity5Child3 *)value;
- (void)addToManyChilds:(NSSet *)values;
- (void)removeToManyChilds:(NSSet *)values;

@end
