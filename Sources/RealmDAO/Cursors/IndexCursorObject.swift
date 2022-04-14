//
//  IndexCursorObject.swift
//  RealmDAO
//
//  Created by Brian Thomas on 8/20/16.
//

import Foundation
import Realm

/* Not just a cursor - only moves forward. Please use the convenience init. */
public class IndexCursorObject: UniqueObject, UniqueStringKeyed {
    
    public required override init() { }
    public required init(key: String) {
        self.backingKey = key
    }
    
    public convenience init(key: String, start: Int, end: Int = Int.max) {
        self.init(key: key)
        startIndex = start
        currentIndex = start
        endIndex = end
    }
    
    public var uniqueKey: String {
        get { return backingKey }
    }
    
    @objc dynamic var backingKey: String = "DefaultClassName"
    @objc dynamic var startIndex: Int = 0
    @objc dynamic var endIndex: Int = 0
    
    @objc dynamic var currentIndex: Int = 0
    
    public var completed: Bool {
        return currentIndex == endIndex
    }
    
    public var currentToEndGap: Int {
        return endIndex - currentIndex
    }
    
    public var nextIndex: Int {
        return currentIndex + 1
    }
    
    public func bumpIndex() -> Int {
        currentIndex = currentIndex + 1
        return currentIndex
    }
    
    /* Fails if you try to shift the cursor backwards */
    public func setIndex(_ index: Int) -> Bool {
        guard index >= currentIndex else {
            return false
        }
        currentIndex = index
        return true
    }
    
}
