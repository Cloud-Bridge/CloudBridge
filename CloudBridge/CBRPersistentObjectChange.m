/**
 CloudBridge
 Copyright (c) 2015 Oliver Letterer <oliver.letterer@gmail.com>, Sparrow-Labs

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

#import "CBRPersistentObjectChange.h"

@implementation CBRPersistentObjectChange

- (NSInteger)count
{
    return self.deletions.count + self.insertions.count + self.updates.count;
}

- (instancetype)initWithDeletions:(NSArray<NSNumber *> *)deletions insertions:(NSArray<NSNumber *> *)insertions updates:(NSArray<NSNumber *> *)updates
{
    if (self = [super init]) {
        _deletions = deletions;
        _insertions = insertions;
        _updates = updates;
    }
    return self;
}

- (NSArray<NSIndexPath *> *)deletionsWithSection:(NSInteger)section
{
    NSMutableArray<NSIndexPath *> *result = [NSMutableArray array];

    for (NSNumber *number in self.deletions) {
        [result addObject:[NSIndexPath indexPathForRow:number.integerValue inSection:0]];
    }

    return result;
}

- (NSArray<NSIndexPath *> *)insertionsWithSection:(NSInteger)section
{
    NSMutableArray<NSIndexPath *> *result = [NSMutableArray array];

    for (NSNumber *number in self.insertions) {
        [result addObject:[NSIndexPath indexPathForRow:number.integerValue inSection:0]];
    }

    return result;
}

- (NSArray<NSIndexPath *> *)updatesWithSection:(NSInteger)section
{
    NSMutableArray<NSIndexPath *> *result = [NSMutableArray array];

    for (NSNumber *number in self.updates) {
        [result addObject:[NSIndexPath indexPathForRow:number.integerValue inSection:0]];
    }

    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: {\n  deletions = (%@)\n  insertions = (%@)\n  updates = (%@)\n}", [super description], [self.deletions componentsJoinedByString:@", "], [self.insertions componentsJoinedByString:@", "], [self.updates componentsJoinedByString:@", "]];
}

@end
