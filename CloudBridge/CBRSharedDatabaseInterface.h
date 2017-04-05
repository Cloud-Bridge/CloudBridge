//
//  CBRSharedDatabaseInterface.h
//  Pods
//
//  Created by Oliver Letterer on 05.04.17.
//
//

#import <Foundation/Foundation.h>
#import <CloudBridge/CBRDefines.h>

#if CBRRealmAvailable && CBRCoreDataAvailable

#import <CloudBridge/CBRCoreDataInterface.h>
#import <CloudBridge/CBRRealmInterface.h>



NS_ASSUME_NONNULL_BEGIN

@interface CBRSharedDatabaseInterface : NSObject <CBRPersistentStoreInterface>

@property (nonatomic, readonly) CBRCoreDataInterface *coreDataInterface;
@property (nonatomic, readonly) CBRRealmInterface *realmInterface;

- (instancetype)initWithCoreDataInterface:(CBRCoreDataInterface *)coreDataInterface realmInterface:(CBRRealmInterface *)realmInterface;

@end

NS_ASSUME_NONNULL_END

#endif
