//
//  RecordsSegmentSequence.swift
//  RealmDAO
//
//  Created by Brian Thomas on 8/31/16.
//

import Foundation


class RecordsSegmentSequence: UniqueObject, UniqueStringKeyed, RecordsSegmentSequenceType {
        
    required override init() { }
    required init(key: String) {
        self.recordSequenceIdentifier = String(key.split(separator: Character("-"))[0])
        self.recordSegmentIdentifier = String(key.split(separator: Character("-"))[1])
    }
    
    var uniqueKey: String {
        get {
            return "\(recordSequenceIdentifier)-\(recordSegmentIdentifier)"
        }
    }
    
    dynamic fileprivate(set) var recordSequenceIdentifier: String = ""
    dynamic fileprivate(set) var recordSegmentIdentifier: String = ""
    dynamic fileprivate(set) var segmentIndexForScanLine: Int = 0
    
    var segments: [RecordsSegmentType] {
        let segmentDAO = RealmDAO<RecordsSegment>()
        return segmentDAO.all()
            .map { (segment) -> RecordsSegmentType in
                return segment as RecordsSegmentType
            }
            .filter { (segment) -> Bool in
                return segment.sequenceIdentifier == recordSequenceIdentifier
            }
            .sorted { (earlier, later) -> Bool in
                return earlier.startIndex < later.startIndex
            }
    }
    
    func tryOpen(scanIndex openingIndex: Int) -> RecordsSegmentType? {
        
        let dao = RealmDAO<RecordsSegment>()
        let allSegments = segments
        
        guard let lastSegment = allSegments.last else {
            let firstSegment = RecordsSegment(identifier: recordSequenceIdentifier, start: 0)
            dao.insert(firstSegment)
            return firstSegment
        }
        
        // eventually return intermediate segments here.
        guard openingIndex > lastSegment.endIndex else {
            for seg in allSegments {
                if openingIndex >= seg.startIndex && openingIndex < seg.endIndex {
                    return seg
                }
            }
            return .none
        }
        
        let nextSegment = RecordsSegment(identifier: recordSequenceIdentifier, start: openingIndex)
        dao.insert(nextSegment)
        return nextSegment
    }
    
    func tryClose(scanIndex closingIndex: Int) -> RecordsSegmentType? {
        let allSegments = segments
        
        guard let _ = allSegments.last else {
            return .none
        }
        
        var resultSegment: RecordsSegmentType? = .none
        allSegments.scan { (currentItem, nextItem) in
            
            if let lastItem = currentItem, nextItem == nil && lastItem.endIndex > closingIndex && lastItem.indexForScanLine <= closingIndex {
                resultSegment = lastItem
            }
            
            if let innerItem = currentItem, let upcomingItem = nextItem, innerItem.endIndex > closingIndex
                && innerItem.indexForScanLine <= closingIndex
                && upcomingItem.startIndex > closingIndex {
                resultSegment = innerItem
            }
            // If let _ = nextItem where currentItem == nil (first segment)
            // Wait and let one of the other 'middle' or 'last' if's catch it
        }
        
        guard let resultUUID = resultSegment?.uuid else {
            return .none
        }
        
        let _ = RealmDAO<RecordsSegment>().update(resultUUID) { segment in
            if segment.close(closingIndex) {
                resultSegment = segment
            }
        }
        
        return resultSegment
    }
    
}



class RecordsSegmentSequenceInWriteBlock: RecordsSegmentSequenceType {
    
    fileprivate var backingSequence: RecordsSegmentSequenceType
    init(sequence: RecordsSegmentSequenceType) {
        backingSequence = sequence
    }
    
    var recordSequenceIdentifier: String {
        return backingSequence.recordSequenceIdentifier
    }
    
    var segmentIndexForScanLine: Int {
        return backingSequence.segmentIndexForScanLine
    }
    
    var segments: [RecordsSegmentType] {
        return backingSequence.segments
    }
    
    // is there a required end?
    func tryOpen(scanIndex openingIndex: Int) -> RecordsSegmentType? {
        let realm = RealmDAO<RecordsSegment>().backingRealm()
        let allSegments = segments
        
        guard let lastSegment = allSegments.last else {
            let firstSegment = RecordsSegment(identifier: recordSequenceIdentifier, start: 0)
            realm.add(firstSegment, update: .all)
            return firstSegment
        }
        
        // eventually return intermediate segments here.
        guard openingIndex > lastSegment.endIndex else {
            for seg in allSegments {
                if openingIndex >= seg.startIndex && openingIndex < seg.endIndex {
                    return seg
                }
            }
            return .none
        }
        
        let nextSegment = RecordsSegment(identifier: recordSequenceIdentifier, start: openingIndex)
        realm.add(nextSegment, update: .all)
        return nextSegment
    }
    
    func tryClose(scanIndex closingIndex: Int) -> RecordsSegmentType? {
        let realm = RealmDAO<RecordsSegment>().backingRealm()
        let allSegments = segments
        
        guard let _ = allSegments.last else {
            return .none
        }
        
        var resultSegment: RecordsSegmentType? = .none
        allSegments.scan { (currentItem, nextItem) in
            
            if let lastItem = currentItem, nextItem == nil && lastItem.endIndex > closingIndex && lastItem.indexForScanLine <= closingIndex {
                resultSegment = lastItem
            }
            
            if let innerItem = currentItem, let upcomingItem = nextItem, innerItem.endIndex > closingIndex
                && innerItem.indexForScanLine <= closingIndex
                && upcomingItem.startIndex > closingIndex {
                resultSegment = innerItem
            }
            // If let _ = nextItem where currentItem == nil (first segment)
            // Wait and let one of the other 'middle' or 'last' if's catch it
        }
        
        guard let result = resultSegment else {
            return .none
        }
        
        guard let segment = realm.object(ofType: RecordsSegment.self, forPrimaryKey: result.uuid as AnyObject) else {
            return .none
        }
        
        if segment.close(closingIndex) {
            return segment
        } else {
            return .none
        }
    }
    
    func scanIndex() -> RecordsSegmentType? {
        return .none
    }
    
}
