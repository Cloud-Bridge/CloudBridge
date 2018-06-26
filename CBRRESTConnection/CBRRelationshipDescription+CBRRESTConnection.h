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

#import <CloudBridge/CBREntityDescription.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBRRelationshipDescription (CBRRESTConnection)

/**
 Set `restKeyPath` of the attribute's `userInfo` dictionary to override the mapping model's propery mapping.
 */
@property (nonatomic, nullable, readonly) NSString *restKeyPath;

/**
 Set `restDisabled` of the attribute's `userInfo` dictionary to `1` to disable this attribute from the propery mapping. Defaults to `NO`.
 */
@property (nonatomic, readonly) BOOL restDisabled;

/**
 Add `restBaseURL` to the relationship's `userInfo` dictionary to enable `-[NSManagedObject fetchObjectsForRelationship:withCompletionHandler:]`.
 */
@property (nonatomic, nullable, readonly) NSString *restBaseURL;

/**
 Add `restIncluded` to the relationship's `userInfo` dictionary to include that relationship when construction a cloud object.
 */
@property (nonatomic, nullable, readonly) NSString *restIncluded;

@end

NS_ASSUME_NONNULL_END
