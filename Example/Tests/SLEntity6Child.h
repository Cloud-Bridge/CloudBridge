//
//  SLEntity6Child.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SLEntity6;

@interface SLEntity6Child : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) SLEntity6 *parent;

@end
