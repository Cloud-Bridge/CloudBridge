//
//  CBRUnderscoredPropertyMappingTests.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge.h>
#import <CBRUnderscoredPropertyMapping.h>

#import "CBRTestCase.h"

@interface CBRUnderscoredPropertyMappingTests : CBRTestCase
@property (nonatomic, strong) CBRUnderscoredPropertyMapping *propertyMapping;
@end

@implementation CBRUnderscoredPropertyMappingTests

- (void)setUp
{
    [super setUp];
    self.propertyMapping = [[CBRUnderscoredPropertyMapping alloc] init];
}

- (void)testJSONToObjcAttributeConvertionWithSingleWord
{
    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"attribute"]).to.equal(@"attribute");
}

- (void)testObjcToJSONAttributeConvertionWithSingleWord
{
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"attribute"]).to.equal(@"attribute");
}

- (void)testJSONToObjcAttributeConvertionWithMultipleWord
{
    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"attribute_value"]).to.equal(@"attributeValue");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleWord
{
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"attributeValue"]).to.equal(@"attribute_value");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleUppercaseWord
{
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"attributeValueURL"]).to.equal(@"attribute_value_url");
}

- (void)testThatAttributeMappingRegistersNamingConventionsWithSingleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"id"]).to.equal(@"identifier");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"identifier"]).to.equal(@"id");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtBeginningWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"id_value"]).to.equal(@"identifierValue");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"identifierValue"]).to.equal(@"id_value");
}

- (void)testThatAttributeMappingRegistersNamingConventionsInTheMiddleWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_id_bar"]).to.equal(@"fooIdentifierBar");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooIdentifierBar"]).to.equal(@"foo_id_bar");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtTheEndWithMultipleWorks
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_bar_id"]).to.equal(@"fooBarIdentifier");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooBarIdentifier"]).to.equal(@"foo_bar_id");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_url_bar"]).to.equal(@"fooURLBar");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooURLBar"]).to.equal(@"foo_url_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWorks
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_bar_url"]).to.equal(@"fooBarURL");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooBarURL"]).to.equal(@"foo_bar_url");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_urll_bar"]).to.equal(@"fooUrllBar");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooURLLBar"]).to.equal(@"foo_urll_bar");

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_lurl_bar"]).to.equal(@"fooLurlBar");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooLURLBar"]).to.equal(@"foo_lurl_bar");

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_lurll_bar"]).to.equal(@"fooLurllBar");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooLURLLBar"]).to.equal(@"foo_lurll_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_bar_urll"]).to.equal(@"fooBarUrll");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooBarURLL"]).to.equal(@"foo_bar_urll");

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_bar_lurl"]).to.equal(@"fooBarLurl");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooBarLURL"]).to.equal(@"foo_bar_lurl");

    expect([self.propertyMapping managedObjectPropertyFromCloudKeyPath:@"foo_bar_lurll"]).to.equal(@"fooBarLurll");
    expect([self.propertyMapping cloudKeyPathFromManagedObjectProperty:@"fooBarLURLL"]).to.equal(@"foo_bar_lurll");
}


@end
