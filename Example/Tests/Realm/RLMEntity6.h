//
//  SLEntity6.h
//  CloudBridge
//
//  Created by Oliver Letterer on 11.08.14.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRRealmObject.h>
#import <CloudBridge/CBRRealmDatabaseAdapter.h>

@protocol RLMEntity6, RLMEntity6Child;
@class RLMEntity6, RLMEntity6Child;



@interface RLMEntity6Child : CBRRealmObject

@property (nonatomic, strong) NSNumber<RLMInt> *identifier;
@property (nonatomic, strong) RLMEntity6 *parent;

@end

RLM_ARRAY_TYPE(RLMEntity6Child)



@interface RLMEntity6 : CBRRealmObject

@property (nonatomic, strong) NSNumber<RLMInt> *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) RLMLinkingObjects<RLMEntity6Child *><RLMEntity6Child> *children;

@end

RLM_ARRAY_TYPE(RLMEntity6)
