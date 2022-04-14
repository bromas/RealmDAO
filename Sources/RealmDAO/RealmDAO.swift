//
//  RealmDAO.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation
import RealmSwift

private var realmGenerator: (() -> Realm)! = .none

private func defaultRealm() -> Realm {
    return realmGenerator()
}

public class RealmDAO<T> where T: UniqueObject {
    
    public static var version: String {
        "v1.0"
    }
    
    public static func configure(_ generator: @escaping () -> Realm) {
        realmGenerator = generator
    }
    
    public func backingRealm() -> Realm {
        return defaultRealm()
    }
    
    public func all() -> [T] {
        return defaultRealm().objects(T.self).map { return $0 }
    }
    
    public func insert(_ object: T) {
        let realm = defaultRealm()
        try! realm.write {
            realm.add(object, update: .all)
        }
    }
    
    public func insert(_ objects: [T]) {
        let realm = defaultRealm()
        try! realm.write {
            realm.add(objects, update: .all)
        }
    }
    
    public func object(_ uuid: NSUUID) -> T? {
        return self.object(uuidString: uuid.uuidString)
    }
    
    public func fetch(_ filter: (T) -> Bool) -> [T] {
        return defaultRealm().objects(T.self).filter { return filter($0) }
    }
    
    public func query(_ predicate: NSPredicate) -> Results<T> {
        return defaultRealm().objects(T.self).filter(predicate)
    }
    
    public func randomItem(_ filter: (T) -> Bool = { item in return true }) -> T? {
        let items = fetch(filter)
        let count = UInt32(items.count)
        
        guard count > 0 else {
            return .none
        }
        
        let selectedIndex = arc4random() % count
        return items[Int(selectedIndex)]
    }
    
    public func deleteAll() {
        let realm = defaultRealm()
        try! realm.write {
            realm.delete(realm.objects(T.self))
        }
    }
    
    fileprivate func object(uuidString: String) -> T? {
        return defaultRealm().object(ofType: T.self, forPrimaryKey: uuidString as AnyObject)
    }
    
}
