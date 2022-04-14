//
//  RecordsSegment.swift
//  RealmDAO
//
//  Created by Brian Thomas on 8/31/16.
//

import Foundation
import Realm

/* Not just a cursor - only moves forward. Please use the convenience init. */
class RecordsSegment: UniqueObject, UniqueStringKeyed, RecordsSegmentType {
    
    required override init() { }
    required init(key: String) {
        self.sequenceIdentifier = String(key.split(separator: Character("-"))[0])
        self.segmentIdentifier = String(key.split(separator: Character("-"))[1])
    }
    
    convenience init(identifier: String, start: Int, end: Int = Int.max) {
        self.init(key: identifier)
        startIndex = start
        endIndex = end
    }
    
    var uniqueKey: String {
        get {
            return "\(sequenceIdentifier)-\(segmentIdentifier)"
        }
    }
    
    dynamic fileprivate(set) var sequenceIdentifier: String = ""
    dynamic fileprivate(set) var segmentIdentifier: String = ""
    dynamic fileprivate(set) var startIndex: Int = 0
    dynamic fileprivate(set) var endIndex: Int = Int.max
    dynamic fileprivate(set) var indexForScanLine: Int = -1
    dynamic fileprivate(set) var scanCompletedAt: Date? = .none
    
    var completed: Bool {
        return indexForScanLine == endIndex
    }
    
    func close(_ index: Int) -> Bool {
        guard index > startIndex && index >= indexForScanLine else {
            return false
        }
        endIndex = index
        return true
    }
    
    /* Fails if you try to shift the scan line backwards */
    func setScanLine(_ index: Int) -> Bool {
        guard index <= indexForScanLine else {
            return false
        }
        indexForScanLine = index
        
        if indexForScanLine == endIndex {
            scanCompletedAt = Date()
        }
        
        return true
    }
    
}
