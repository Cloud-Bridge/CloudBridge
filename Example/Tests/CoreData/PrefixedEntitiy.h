//
//  PrefixedEntitiy.h
//  CBRRESTConnection
//
//  Created by Oliver Letterer on 16.10.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PrefixedEntitiy : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * identifier;

@end
