# CBRManagedObjectCache

[![CI Status](http://img.shields.io/travis/OliverLetterer/CBRManagedObjectCache.svg?style=flat)](https://travis-ci.org/OliverLetterer/CBRManagedObjectCache)
[![Version](https://img.shields.io/cocoapods/v/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache)
[![License](https://img.shields.io/cocoapods/l/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache)
[![Platform](https://img.shields.io/cocoapods/p/CBRManagedObjectCache.svg?style=flat)](http://cocoadocs.org/docsets/CBRManagedObjectCache)

A lightweight cache for Your `NSManagedObjectContext`.

## Usage

Get the cache for Your `NSManagedObjectContext`:
```
NSManagedObjectContext *context = ...;
CBRManagedObjectCache *cache = context.cdc_cache;
```

`CBRManagedObjectCache` allows You to cache and query managed objects by a single attribute:
```
@interface CBRManagedObjectCache : NSObject
- (id)objectOfType:(NSString *)type withValue:(id)value forAttribute:(NSString *)attribute;
- (NSDictionary *)indexedObjectsOfType:(NSString *)type withValues:(NSSet *)values forAttribute:(NSString *)attribute;
@end

```

## Installation

CBRManagedObjectCache is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "CBRManagedObjectCache"

## Author

Oliver Letterer, oliver.letterer@gmail.com

## License

CBRManagedObjectCache is available under the MIT license. See the LICENSE file for more info.
