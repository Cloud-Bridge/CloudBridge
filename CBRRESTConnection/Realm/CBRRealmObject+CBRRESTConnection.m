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

#import "CBRRealmObject+CBRRESTConnection.h"
#import "CBRRESTConnection.h"
#import "CBRRealmInterface.h"



@implementation CBRRealmObject (CBRRESTConnection)

+ (void)fetchObjectFromPath:(NSString *)path withCompletionHandler:(void (^)(id, NSError *))completionHandler
{
    [self fetchObjectsFromPath:path withCompletionHandler:^(NSArray *fetchedObjects, NSError *error) {
        if (completionHandler) {
            completionHandler(fetchedObjects.firstObject, error);
        }
    }];
}

+ (void)fetchObjectsFromPath:(NSString *)path withCompletionHandler:(void (^)(NSArray *, NSError *))completionHandler
{
    NSParameterAssert([[self cloudBridge].cloudConnection isKindOfClass:[CBRRESTConnection class]]);

    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: path };
    [self.cloudBridge fetchPersistentObjectsOfClass:self withPredicate:nil userInfo:userInfo completionHandler:completionHandler];
}

- (void)createToPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: path };
    [self.cloudBridge createPersistentObject:self withUserInfo:userInfo completionHandler:completionHandler];
}

- (void)reloadFromPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: path };
    [self.cloudBridge reloadPersistentObject:self withUserInfo:userInfo completionHandler:completionHandler];
}

- (void)saveToPath:(NSString *)path withCompletionHandler:(void(^)(id managedObject, NSError *error))completionHandler
{
    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: path };
    [self.cloudBridge savePersistentObject:self withUserInfo:userInfo completionHandler:completionHandler];
}

- (void)deleteToPath:(NSString *)path withCompletionHandler:(void(^)(NSError *error))completionHandler
{
    NSDictionary *userInfo = @{ CBRRESTConnectionUserInfoURLOverrideKey: path };
    [self.cloudBridge deletePersistentObject:self withUserInfo:userInfo completionHandler:completionHandler];
}

@end
