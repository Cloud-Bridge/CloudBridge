//
//  RLMEntity4.h
//  CloudBridge
//
//  Created by Oliver Letterer on 27.03.17.
//  Copyright © 2017 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRRealmObject.h>

@interface RLMEntity4 : CBRRealmObject

@property (nonatomic, retain) NSArray<id> *array;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber<RLMInt> * identifier;
@property (nonatomic, retain) NSNumber<RLMDouble> * number;
@property (nonatomic, retain) NSString * string;

@end
