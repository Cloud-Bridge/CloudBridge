//
//  CBRUnderscoredPropertyMappingTests.m
//  CoreDataCloud
//
//  Created by Oliver Letterer on 09.08.14.
//  Copyright (c) 2014 Oliver Letterer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <CloudBridge/CloudBridge.h>
#import <CBRRESTConnection/CBRUnderscoredPropertyMapping.h>

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
    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"attribute"]).to.equal(@"attribute");
}

- (void)testObjcToJSONAttributeConvertionWithSingleWord
{
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"attribute"]).to.equal(@"attribute");
}

- (void)testJSONToObjcAttributeConvertionWithMultipleWord
{
    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"attribute_value"]).to.equal(@"attributeValue");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleWord
{
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"attributeValue"]).to.equal(@"attribute_value");
}

- (void)testObjcToJSONAttributeConvertionWithMultipleUppercaseWord
{
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"attributeValueURL"]).to.equal(@"attribute_value_url");
}

- (void)testThatAttributeMappingRegistersNamingConventionsWithSingleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"id"]).to.equal(@"identifier");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"identifier"]).to.equal(@"id");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtBeginningWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"id_value"]).to.equal(@"identifierValue");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"identifierValue"]).to.equal(@"id_value");
}

- (void)testThatAttributeMappingRegistersNamingConventionsInTheMiddleWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_id_bar"]).to.equal(@"fooIdentifierBar");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooIdentifierBar"]).to.equal(@"foo_id_bar");
}

- (void)testThatAttributeMappingRegistersNamingConventionsAtTheEndWithMultipleWorks
{
    [self.propertyMapping registerObjcNamingConvention:@"identifier" forJSONNamingConvention:@"id"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_bar_id"]).to.equal(@"fooBarIdentifier");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooBarIdentifier"]).to.equal(@"foo_bar_id");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_url_bar"]).to.equal(@"fooURLBar");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooURLBar"]).to.equal(@"foo_url_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWorks
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_bar_url"]).to.equal(@"fooBarURL");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooBarURL"]).to.equal(@"foo_bar_url");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsInTheMiddleWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_urll_bar"]).to.equal(@"fooUrllBar");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooURLLBar"]).to.equal(@"foo_urll_bar");

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_lurl_bar"]).to.equal(@"fooLurlBar");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooLURLBar"]).to.equal(@"foo_lurl_bar");

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_lurll_bar"]).to.equal(@"fooLurllBar");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooLURLLBar"]).to.equal(@"foo_lurll_bar");
}

- (void)testThatAttributeMappingRegistersCapitalizedNamingConventionsAtTheEndWithMultipleWordsAndDoesntCaptureLongerWords
{
    [self.propertyMapping registerObjcNamingConvention:@"URL" forJSONNamingConvention:@"url"];

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_bar_urll"]).to.equal(@"fooBarUrll");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooBarURLL"]).to.equal(@"foo_bar_urll");

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_bar_lurl"]).to.equal(@"fooBarLurl");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooBarLURL"]).to.equal(@"foo_bar_lurl");

    expect([self.propertyMapping persistentObjectPropertyFromCloudKeyPath:@"foo_bar_lurll"]).to.equal(@"fooBarLurll");
    expect([self.propertyMapping cloudKeyPathFromPersistentObjectProperty:@"fooBarLURLL"]).to.equal(@"foo_bar_lurll");
}


@end
