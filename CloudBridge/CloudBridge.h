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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import <CloudBridge/CBRJSONObject.h>

#import <CloudBridge/CBRDefines.h>

#import <CloudBridge/CBREntityDescription.h>
#import <CloudBridge/CBRCloudObject.h>
#import <CloudBridge/CBRCloudConnection.h>
#import <CloudBridge/CBRPersistentObject.h>

#import <CloudBridge/CBRCloudBridge.h>
#import <CloudBridge/CBROfflineCapableCloudBridge.h>

#import <CloudBridge/CBRPersistentObjectChange.h>
#import <CloudBridge/CBRPersistentStoreInterface.h>
#import <CloudBridge/CBRDatabaseAdapter.h>
#import <CloudBridge/CBRCloudObjectTransformer.h>
#import <CloudBridge/CBRThreadingEnvironment.h>
#import <CloudBridge/CBRPersistentObjectCache.h>
#import <CloudBridge/CBRSharedDatabaseInterface.h>

#if CBRRealmAvailable
#import <CloudBridge/CBRRealmObject.h>
#import <CloudBridge/CBRRealmInterface.h>
#import <CloudBridge/RLMResults+CloudBridge.h>
#endif

#if CBRCoreDataAvailable
#import <CloudBridge/CBRCoreDataStack.h>
#import <CloudBridge/CBRCoreDataInterface.h>
#endif

#if __has_include(<CloudBridge/CBRRESTConnection.h>)
#import <CloudBridge/CBRRESTConnection.h>
#import <CloudBridge/CBRJSONObject+REST.h>
#endif
