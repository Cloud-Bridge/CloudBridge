//
//  SLEntity5Child3.h
//  CBRRESTConnection
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SLEntity5;

@interface SLEntity5Child3 : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) SLEntity5 *parent;

@end
