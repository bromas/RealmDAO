//
//  UniqueObject.swift
//  RealmDAO
//
//  Created by Brian Thomas on 7/4/21.
//

import Foundation
import RealmSwift

public class UniqueObject: Object {
    
    @objc dynamic var uuid: String = UUID().uuidString
    
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var lastUpdatedAt: Date = Date()
    @objc dynamic var deletedAt: Date? = .none
    
    public override static func primaryKey() -> String {
        return "uuid"
    }
    
}

public protocol UniqueIntKeyed {
    init()
    var uniqueKey: Int { get set }
}


