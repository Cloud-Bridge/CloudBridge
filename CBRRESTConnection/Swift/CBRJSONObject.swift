//
//  CBRPersistentObject.swift
//  CloudBridge
//
//  Created by Oliver Letterer on 25.06.18.
//

import Foundation

private extension CBRJSONObjectProtocol where Self: CBRJSONObject {
    static func substitute(object: Self, path: String) -> String {
        return path.components(separatedBy: "/").map { (path) -> String in
            guard path.hasPrefix(":") else {
                return path
            }

            let keyPath = path.dropFirst().components(separatedBy: ".").map({
                restConnection!.propertyMapping.persistentObjectProperty(fromCloudKeyPath: $0)
            }).joined(separator: ".")

            let value = object.value(forKeyPath: keyPath)
            return "\(value ?? "")"
            }.joined(separator: "/")
    }
}

public extension CBRJSONObjectProtocol where Self: CBRJSONObject {
    static func fetchObject(from path: String, completion: ((Self?, Error?) -> Void)?) {
        fetchObjects(from: path) { (result, error) in
            guard error == nil, let object = result?.first else {
                completion?(nil, error)
                return
            }

            completion?(object, nil)
        }
    }

    static func fetchObjects(from path: String, completion: (([Self]?, Error?) -> Void)?) {
        restConnection!.fetchCloudObjects(fromPath: path, parameters: nil, withCompletionHandler: { (objects, error) in
            guard error == nil, let objects = objects as? [[String: Any]] else {
                completion?(nil, error)
                return
            }

            let result = objects.map({ (json) in
                return try! Self.init(dictionary: json)
            })

            completion?(result, nil)
        })
    }
}

public extension CBRJSONObjectProtocol where Self: CBRJSONObject {
    func fetchRelation<T>(from path: String, completion: ((T?, Error?) -> Void)?) where T: CBRJSONObject {
        T.fetchObject(from: Self.substitute(object: self, path: path), completion: completion)
    }

    func fetchRelations<T>(from path: String, completion: (([T]?, Error?) -> Void)?) where T: CBRJSONObject {
        T.fetchObjects(from: Self.substitute(object: self, path: path), completion: completion)
    }
}

public extension CBRJSONObjectProtocol where Self: CBRJSONObject {
    func create(to path: String, completion: ((Self?, Error?) -> Void)?) {
        restConnection!.sessionManager.post(Self.substitute(object: self, path: path), parameters: nil, progress: nil, success: { (_, result) in
            try! self.patch(with: result as? [String: Any])
            completion?(self, nil)
        }) { (_, error) in
            completion?(nil, error)
        }
    }

    func reload(from path: String, completion: ((Self?, Error?) -> Void)?) {
        restConnection!.sessionManager.get(Self.substitute(object: self, path: path), parameters: nil, progress: nil, success: { (_, result) in
            try! self.patch(with: result as? [String: Any])
            completion?(self, nil)
        }) { (_, error) in
            completion?(nil, error)
        }
    }

    func save(to path: String, completion: ((Self?, Error?) -> Void)?) {
        restConnection!.sessionManager.put(Self.substitute(object: self, path: path), parameters: nil, success: { (_, result) in
            try! self.patch(with: result as? [String: Any])
            completion?(self, nil)
        }) { (_, error) in
            completion?(nil, error)
        }
    }

    func delete(from path: String, completion: ((Error?) -> Void)?) {
        restConnection!.sessionManager.put(Self.substitute(object: self, path: path), parameters: nil, success: { (_, result) in
            completion?(nil)
        }) { (_, error) in
            completion?(error)
        }
    }
}
