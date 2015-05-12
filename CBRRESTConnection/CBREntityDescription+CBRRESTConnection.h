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

#import <CloudBridge/CloudBridge.h>



@interface CBREntityDescription (CBRRESTConnection)

/**
 Add `restBaseURL` to the entities `userInfo` dictionary to enable CRUD methods.
 */
@property (nonatomic, readonly) NSString *restBaseURL;

/**
 The key path which is mapped to the unique identifier of the cloud object through the property mapping. Defaults to `identifier`.
 */
@property (nonatomic, readonly) NSString *restIdentifier;

/**
 Add the keyPath `stiKeyPath` to the entities `userInfo` dictionary to enable single table inheritance. Your subclass must specify the matching `stiValue`.
 */
@property (nonatomic, readonly) NSString *stiKeyPath;

/**
 The value that the `stiKeyPath` must match to use this subclass.
 */
@property (nonatomic, readonly) NSString *stiValue;

/**
 Returns an array of possible subentities, valid for single table inheritance.
 */
@property (nonatomic, readonly) NSArray *stiSubentities;

/**
 The value of `restPrefix` will be used to prefix JSON dictionaries with this prefix.
 */
@property (nonatomic, readonly) NSString *restPrefix;

@end
