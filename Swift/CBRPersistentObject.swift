//
//  CBRPersistentObject.swift
//  CloudBridge
//
//  Created by Oliver Letterer on 25.06.18.
//

import Foundation

public extension CBRPersistentObject {
    func create(completion: ((Self?, Error?) -> Void)?) {
        cloudBridge!.createPersistentObject(self) { (result, error) in
            guard let result = result as? Self, error == nil else {
                completion?(nil, error)
                return
            }

            completion?(result, nil)
        }
    }

    func reload(completion: ((Self?, Error?) -> Void)?) {
        cloudBridge!.reload(self) { (result, error) in
            guard let result = result as? Self, error == nil else {
                completion?(nil, error)
                return
            }

            completion?(result, nil)
        }
    }

    func save(completion: ((Self?, Error?) -> Void)?) {
        cloudBridge!.save(self) { (result, error) in
            guard let result = result as? Self, error == nil else {
                completion?(nil, error)
                return
            }

            completion?(result, nil)
        }
    }

    func delete(completion: ((Error?) -> Void)?) {
        cloudBridge!.delete(self) { (error) in
            completion?(error)
        }
    }
}

public extension CBRPersistentObject where Self: NSObject {
    func fetchObject<T: CBRPersistentObject>(relationship: String, completion: ((T?, Error?) -> Void)?) {
        assert(!cloudBridgeEntityDescription!.relationshipsByName[relationship]!.toMany)

        fetchObjects(relationship: relationship) { (objects: [T]?, error) in
            completion?(objects?.first, error)
        }
    }

    func fetchObjects<T: CBRPersistentObject>(relationship: String, completion: (([T]?, Error?) -> Void)?) {
        let description = cloudBridgeEntityDescription!.relationshipsByName[relationship]!
        assert(description.inverseRelationship != nil)
        assert(!description.inverseRelationship!.toMany)

        let predicate = NSPredicate(format: "%K == %@", description.inverseRelationship!.name, self)
        cloudBridge!.fetchPersistentObjects(of: NSClassFromString(description.inverseRelationship!.name)!, with: predicate) { (objects, error) in
            guard error == nil, let objects = objects as? [T] else {
                completion?(nil, error)
                return
            }

            completion?(objects, nil)
        }
    }
}

public extension CBRPersistentObject {
    func fetchObjects(predicate: NSPredicate?, completion: (([Self]?, Error?) -> Void)?) {
        cloudBridge!.fetchPersistentObjects(of: Self.self, with: predicate) { (objects, error) in
            guard error == nil, let objects = objects as? [Self] else {
                completion?(nil, error)
                return
            }

            completion?(objects, nil)
        }
    }
}
