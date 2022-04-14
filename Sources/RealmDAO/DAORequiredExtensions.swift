//
//  DAORequiredExtensions.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation
import Combine

extension Array {
    func scan(_ closure: (_ currentItem: Element?, _ nextItem: Element?) -> ()) {
        var element1: Element? = .none
        var element2: Element? = .none
        for item in self {
            if let _ = element1, let secondItem = element2 {
                closure(secondItem, item)
                element1 = secondItem
                element2 = item
                continue
            }
            
            if let onlyElement = element2 {
                closure(onlyElement, item)
                element1 = onlyElement
                element2 = item
                continue
            }
            
            closure(.none, item)
        }
        
        closure(element2, .none)
    }
}

extension Sequence {
  func categorise<U: Hashable>(_ keyFunc: (Iterator.Element) -> U) -> [U: [Iterator.Element]] {
    var dict: [U: [Iterator.Element]] = [:]
    for el in self {
      let key = keyFunc(el)
      if case nil = dict[key]?.append(el) { dict[key] = [el] }
    }
    return dict
  }
}

extension Publisher {
    func eraseToError() -> AnyPublisher<Self.Output, Error> {
        mapError { $0 as Error }.eraseToAnyPublisher()
    }
}
