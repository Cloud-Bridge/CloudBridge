//
//  JSONEntity1.h
//  CBRRESTConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface JSONEntity1 : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) id dictionary;
@property (nonatomic, retain) NSNumber * floatNumber;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * otherString;
@property (nonatomic, retain) NSString * string;

@end
