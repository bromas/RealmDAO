//
//  DAOEvent.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation

public enum DAOEvent<T> {
    case refresh
    case save([T])
    case delete([T])
}
