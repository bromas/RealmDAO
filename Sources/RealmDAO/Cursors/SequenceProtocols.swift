//
//  RecordsSegmentSequenceType.swift
//  RealmDAO
//
//  Created by Brian Thomas on 9/17/16.
//

import Foundation


enum SegmentSequenceActionError: Error {
  case alreadyOpen
  case segmentContainsRecordIndex
  case indexOutOfSegmentBounds
  case onlyScanSegmentsForward
}


protocol RecordsSegmentSequenceType {
  var recordSequenceIdentifier: String { get }
  var segmentIndexForScanLine: Int { get }
  var segments: [RecordsSegmentType] { get }
  
  func tryOpen(scanIndex openingIndex: Int) -> RecordsSegmentType?
  func tryClose(scanIndex closingIndex: Int) -> RecordsSegmentType?
}


protocol RecordsSegmentType {
  var uuid: String { get }
  var sequenceIdentifier: String { get }
  
  var startIndex: Int { get }
  var endIndex: Int { get }
  var indexForScanLine: Int { get }
  
  var scanCompletedAt: Date? { get }
  
  func setScanLine(_ index: Int) -> Bool
}
