//
//  CBRIdentityPropertyMappingTest.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 08.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "CBRTestCase.h"
#import <CBRIdentityPropertyMapping.h>

@interface CBRIdentityPropertyMappingTest : CBRTestCase
@property (nonatomic, strong) CBRIdentityPropertyMapping *propertyMapping;
@end



@implementation CBRIdentityPropertyMappingTest

- (void)setUp
{
    [super setUp];
    
    self.propertyMapping = [[CBRIdentityPropertyMapping alloc] init];
}

- (void)testThatPropertyMappingMapsManagedObjectPropertyToIdentityCloudKeyPath
{
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"someProperty"]).to.equal(@"someProperty");
}

- (void)testThatPropertyMappingMapsManagedObjectPropertyToIdentityCloudKeyPathWithNamingConvention
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"identifier"]).to.equal(@"id");
}

- (void)testThatPropertyMappingMapsComplexManagedObjectPropertyToIdentityCloudKeyPathWithNamingConvention
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"someIdentifier"]).to.equal(@"someId");
}

- (void)testThatPropertyMappingMapsCloudKeyPathToIdentityManagedObjectProperty
{
    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"someProperty"]).to.equal(@"someProperty");
}

- (void)testThatPropertyMappingMapsCloudKeyPathToIdentityManagedObjectPropertyWithNamingConvention
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"id"]).to.equal(@"identifier");
}

- (void)testThatPropertyMappingMapsComplexCloudKeyPathToIdentityManagedObjectPropertyWithNamingConvention
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];
    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"someId"]).to.equal(@"someIdentifier");
}

@end