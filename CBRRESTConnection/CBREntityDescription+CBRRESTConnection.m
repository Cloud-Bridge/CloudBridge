/**
 CBRRESTConnection
 Copyright (c) 2014 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "CBREntityDescription+CBRRESTConnection.h"

@implementation CBREntityDescription (CBRRESTConnection)

- (NSString *)restBaseURL
{
    return self.userInfo[@"restBaseURL"];
}

- (NSString *)restIdentifier
{
    if (self.userInfo[@"restIdentifier"]) {
        return self.userInfo[@"restIdentifier"];
    }

    if (self.attributesByName[@"identifier"]) {
        return @"identifier";
    }

    return nil;
}

- (NSString *)stiKeyPath
{
    return self.userInfo[@"stiKeyPath"];
}

- (NSString *)stiValue
{
    return self.userInfo[@"stiValue"];
}

- (NSArray *)stiSubentities
{
    NSMutableArray *subentities = [NSMutableArray array];
    [self _dumpSTISubentitiesInArray:subentities];
    return subentities.copy;
}

- (NSString *)restPrefix
{
    return self.userInfo[@"restPrefix"];
}

- (void)_dumpSTISubentitiesInArray:(NSMutableArray *)subentities
{
    for (CBREntityDescription *entity in self.subentities) {
        if (entity.stiValue) {
            [subentities addObject:entity];
        }

        [entity _dumpSTISubentitiesInArray:subentities];
    }
}

@end
