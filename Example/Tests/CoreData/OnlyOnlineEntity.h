//
//  OnlyOnlineEntity.h
//  CloudBridge
//
//  Created by Oliver Letterer on 21.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>



@interface OnlyOnlineEntity : NSManagedObject

@property (nonatomic, retain) NSNumber *identifier;

@end
