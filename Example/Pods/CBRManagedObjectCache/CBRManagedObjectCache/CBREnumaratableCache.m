/**
 CBRManagedObjectCache
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

#import "CBREnumaratableCache.h"



@interface CBREnumaratableCache ()
@property (nonatomic, strong) NSMutableSet *enumeratableKeys;
@end



@implementation CBREnumaratableCache

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        _enumeratableKeys = [NSMutableSet set];
    }
    return self;
}

#pragma mark - NSCache

- (void)setObject:(id)obj forKey:(id)key
{
    [super setObject:obj forKey:key];
    [self.enumeratableKeys addObject:key];
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
{
    [super setObject:obj forKey:key cost:g];
    [self.enumeratableKeys addObject:key];
}

- (void)removeObjectForKey:(id)key
{
    [super removeObjectForKey:key];
    [self.enumeratableKeys removeObject:key];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [self.enumeratableKeys countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Private category implementation ()

@end
