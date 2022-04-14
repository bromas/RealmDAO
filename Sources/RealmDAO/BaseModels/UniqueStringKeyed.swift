//
//  UniqueStringKeyed.swift
//  RealmDAO
//
//  Created by Brian Thomas on 7/4/21.
//

import Foundation

public protocol InitInferable {
    init()
    init(key: String)
}

public protocol UniqueStringKeyReferenceable {
    var uniqueKey: String { get }
}

public protocol UniqueStringKeyed: InitInferable, UniqueStringKeyReferenceable { }

public extension RealmDAO where T: UniqueStringKeyed {
    
    /* Creates or fetches an object with the unique key provided */
    func lazyRecord(_ key: String) -> T {
        let foundItem = backingRealm().objects(T.self).filter { (item) -> Bool in
            return item.uniqueKey == key
        }
        
        var object: T! = .none
        
        if let hadOne = foundItem.first {
            object = hadOne
        } else {
            object = T(key: key)
            object.createdAt = Date()
            object.lastUpdatedAt = Date()
        }
        
        return object
    }
    
    func record(_ key: String) -> T? {
        let foundItem = backingRealm().objects(T.self).filter { (item) -> Bool in
            return item.uniqueKey == key
        }
        
        var object: T? = .none
        
        if let hadOne = foundItem.first {
            object = hadOne
        } else {
            object = .none
        }
        
        return object
    }
}

public extension RealmDAO where T: UniqueStringKeyed {
    
    /* Creates or fetches an object with the unique key provided and allows for editing within the scope of the write closure. Changes to the unique key will be ignored. */
    func update(_ key: String, write: (T) -> ()) -> T {
        let object = lazyRecord(key)

        let realm = backingRealm()
        let _ = try? realm.write {
            write(object)
            object.lastUpdatedAt = Date()
            realm.add(object, update: .all)
        }

        return object
    }
    
}
