//
//  CBRPersistentObject.swift
//  CloudBridge
//
//  Created by Oliver Letterer on 25.06.18.
//

import Foundation

public extension CBRPersistentObject {
    func fetchObject(from path: String, completion: ((Self?, Error?) -> Void)?) {
        fetchObjects(from: path) { (objects, error) in
            completion?(objects?.first, error)
        }
    }

    func fetchObjects(from path: String, completion: (([Self]?, Error?) -> Void)?) {
        assert(cloudBridge!.isKind(of: CBRRESTConnection.self))

        let userInfo = [ CBRRESTConnectionUserInfoURLOverrideKey: path ]
        cloudBridge!.fetchPersistentObjects(of: Self.self, with: nil, userInfo: userInfo, completionHandler: { (objects, error) in
            guard error == nil, let objects = objects as? [Self] else {
                completion?(nil, error)
                return
            }

            completion?(objects, nil)
        })
    }
}

public extension CBRPersistentObject {
    func create(to path: String, completion: ((Self?, Error?) -> Void)?) {
        let userInfo = [ CBRRESTConnectionUserInfoURLOverrideKey: path ]
        cloudBridge!.createPersistentObject(self, withUserInfo: userInfo) { (object, error) in
            completion?(object as? Self, error)
        }
    }

    func reload(from path: String, completion: ((Self?, Error?) -> Void)?) {
        let userInfo = [ CBRRESTConnectionUserInfoURLOverrideKey: path ]
        cloudBridge!.reload(self, withUserInfo: userInfo) { (object, error) in
            completion?(object as? Self, error)
        }
    }

    func save(to path: String, completion: ((Self?, Error?) -> Void)?) {
        let userInfo = [ CBRRESTConnectionUserInfoURLOverrideKey: path ]
        cloudBridge!.save(self, withUserInfo: userInfo) { (object, error) in
            completion?(object as? Self, error)
        }
    }

    func delete(from path: String, completion: ((Error?) -> Void)?) {
        let userInfo = [ CBRRESTConnectionUserInfoURLOverrideKey: path ]
        cloudBridge!.delete(self, withUserInfo: userInfo, completionHandler: completion)
    }
}
