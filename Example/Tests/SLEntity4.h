//
//  SLEntity4.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SLEntity4 : NSManagedObject

@property (nonatomic, retain) id array;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * string;

@end
